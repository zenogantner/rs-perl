#!/usr/bin/perl

# Copyright (C) 2006, 2007, 2008 Zeno Gantner
#
# This software is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use utf8;
use English qw( -no_match_vars );
use Getopt::Long;
use Carp;

# TODO:
#   result output should be 1-based (like the input!!!)
#   more general usage
#   use this program to generate results, but not to interpret them
#   rename it
#   usage information
#   generate R output (maybe in another program)
#   call java classes ;-)

use Ratings::Convert;
use Ratings::Karen;
use Ratings::MovieLens;
use Ratings::Sparse;
use Ratings::Scale;

use Evaluation;
use Evaluation::Ranking;

use Predictor::Averages;
use Predictor::CoClustering;
use Predictor::JointWeighting;
use Predictor::LinearCombination;
use Predictor::MostPopular;
use Predictor::NaiveBayes;


# program variables
my $help                 = 0;
my $verbose              = 0;
#my $debug = 0;
my $training_file        = '';
my $test_file            = '';
my $matrix_file_mode     = 0;   # matrix mode for training, test and attribute files
my @predictor_types      = ();
my $evaluate_all         = 0;

my $read_cluster_file    = '';  # parameter for coclustering
my $fix_results          = 1;   # parameter for coclustering
my $item_attribute_file  = '';  # parameter for naive-bayes
my $most_probable_rating = 0;   # parameter for naive-bayes
my $sort_attributes      = 0;   # parameter for naive-bayes
my $lambda               = 0;   # parameter for joint weighting or linear combination
my $linear_combination   = 0;   # parameter to choose linear combination instead of joint weighting
my $several_lambdas      = '';   # special parameter to try several different lambda values at once
                                 # TODO: this could be integrated in a much nicer way
                                 # ... parameter contains the logfile name template

my $rank_error           = 0;
my $top_n                = 0; # TODO: distinguish between micro- and macro-averaging

my $show_progress        = 0;
my $prediction_file      = '';

GetOptions(
    'help'                 => \$help,
    'verbose+'             => \$verbose,
    #'debug+'               => \$debug,
    'training-file=s'      => \$training_file,
    'test-file=s'          => \$test_file,
    'matrix-file-mode'     => \$matrix_file_mode,
    'predictor=s'          => \@predictor_types,  # several are needed for our ensembles
    'top-n=i'              => \$top_n,
    'rank-error'           => \$rank_error,
    'read-cluster-file=s'  => \$read_cluster_file,
    'fix-results!'         => \$fix_results,
    'item-attrib-file=s'   => \$item_attribute_file,
    'most-probable-rating' => \$most_probable_rating,
    'sort-attributes'      => \$sort_attributes,
    'joint-weighting=f'    => \$lambda,
    'several-lambdas=s'    => \$several_lambdas,
    'linear-combination=f' => sub {
                                my $option_name;
                                ($option_name, $lambda) = @_;
                                $linear_combination = 1;
                              },
    'show-progress'        => \$show_progress,
    'prediction-file=s'    => \$prediction_file,
    'evaluate-all'         => \$evaluate_all,
) or usage(-1);

if ($help) {
    usage(0);
}

if ($training_file eq '' || $test_file eq '') {
    print STDERR "Please provide values for the parameters --training-file and --test-file.\n\n";
    usage(-1);
}
if (scalar(@predictor_types) == 0) {
    print STDERR "Please provide a value for the parameter --predictor.\n";
    print STDERR "Possible values for --predictor: ";
    print STDERR "average, user-average, item-average, global-average, coclustering, most-popular, naive-bayes\n\n";
    # TODO: automatize
    usage(-1);
}
my %predictor_type = ();
foreach (@predictor_types) {
    $predictor_type{$_} = 1;
}
if (exists $predictor_type{'naive-bayes'} && $item_attribute_file eq '' ) {
    print STDERR "Please provide --item-attrib-file=...\n\n";
    usage(-1);
}
if (exists $predictor_type{'coclustering'} && $read_cluster_file eq '') {
    print STDERR "Please provide a cluster file for the coclustering predictor: --cluster-file=...\n\n";
    usage(-1);
}
# TODO: check for more parameters that make no sense

my $training_data_reader;
my $test_data_reader;
if ($matrix_file_mode) {
    $training_data_reader = Ratings::Karen->new({
        filename => $training_file,
        verbose  => $verbose,
    });
    $test_data_reader = Ratings::Karen->new({
        filename => $test_file,
        verbose  => $verbose,
    });
}
else {
    $training_data_reader = Ratings::MovieLens->new({
        filename => $training_file,
        verbose  => $verbose,
    });
    $test_data_reader = Ratings::MovieLens->new({
        filename => $test_file,
        verbose  => $verbose,
    });
}
my $known_ratings = $training_data_reader->get_ratings();
my $test_ratings  = $test_data_reader->get_ratings();

# TODO: replace by factory method or something similar ...
print STDERR "Initializing predictor ... " if $verbose;
my @predictors = ();
foreach my $predictor_type (@predictor_types) {
    my $predictor;
    if ($predictor_type eq 'coclustering') {
        $predictor = Predictor::CoClustering->new({
            cluster_file  => $read_cluster_file,
            known_ratings => $known_ratings,
            fix_results   => $fix_results,
            verbose       => $verbose,
        });
    }
    elsif ($predictor_type eq 'most-popular') {
        $predictor = Predictor::MostPopular->new({
            known_ratings => $known_ratings,
            verbose       => $verbose,
        });
    }
    elsif ($predictor_type eq 'average') {
        $predictor = Predictor::Averages->new({
            known_ratings      => $known_ratings,
            verbose            => $verbose,
        });
    }
    elsif ($predictor_type eq 'user-average') {
        $predictor = Predictor::Averages->new({
            known_ratings      => $known_ratings,
            type               => 'user',
            verbose            => $verbose,
        });
    }
    elsif ($predictor_type eq 'item-average') {
        $predictor = Predictor::Averages->new({
            known_ratings      => $known_ratings,
            type               => 'item',
            verbose            => $verbose,
        });
    }
    elsif ($predictor_type eq 'global-average') {
        $predictor = Predictor::Averages->new({
            known_ratings      => $known_ratings,
            type               => 'global',
            verbose            => $verbose,
        });
    }
    elsif ($predictor_type eq 'naive-bayes') {
        my $number_of_items = $known_ratings->{scale}->number_of_items;
        if (!$matrix_file_mode) {
            # TODO: this is movielens-specific
            $number_of_items = 1682;  # this is a hack, but otherwise, we'd lose attribute information
        }
        $predictor = Predictor::NaiveBayes->new({
            known_ratings             => $known_ratings,
            number_of_items           => $number_of_items,
            item_attribute_file       => $item_attribute_file,
            pick_most_probable_rating => $most_probable_rating,
            sort_attributes           => $sort_attributes,
            show_progress             => $show_progress,
            verbose                   => $verbose,
        });
    }
    else {
        print STDERR "Possible values for --predictor: ";
        print STDERR "average, user-average, item-average, global-average, coclustering, most-popular, naive-bayes\n";
        # TODO: create this line automatically
        exit -1;
    }
    push @predictors, $predictor;
}
if ($several_lambdas) {
    $lambda = 1;
}
if ($lambda > 0) {
    if (scalar(@predictors) == 2) {
        if ($linear_combination) {
            my $composed_predictor = Predictor::LinearCombination->new({
                predictor1  => $predictors[0],
                predictor2  => $predictors[1],
                lambda      => $lambda,
                verbose     => $verbose,
            });
            push @predictors, $composed_predictor;
        }
        else {
            my $composed_predictor = Predictor::JointWeighting->new({
                predictor1  => $predictors[0],
                predictor2  => $predictors[1],
                lambda      => $lambda,
                verbose     => $verbose,
            });
            push @predictors, $composed_predictor;
        }
    }
    else {
        print STDERR "Please provide exactly two predictor types using --predictor=... twice if you want to use joint weighting.\n";
        exit -1;
    }
}
print STDERR "done.\n" if $verbose;

if (!$evaluate_all) {
    @predictors = (pop @predictors);
}

if ($several_lambdas) {
    run_eval_for_several_lambdas();
}


foreach my $predictor (@predictors) {
    my $description = $predictor->description;
    print "'$description' ";
    if ($top_n) {
        my $result_ref = Evaluation::compute_top_n_error({
            top_n         => $top_n,
            test_ratings  => $test_ratings,
            known_ratings => $known_ratings,
            predict_ref   => sub { return $predictor->predict(@_) },
            show_progress => $show_progress,
            verbose       => $verbose,
        });
        printf "n=$top_n; precision=%.4f, recall=%.4f, f1=%.4f\n",
            $result_ref->{precision}, $result_ref->{recall}, $result_ref->{f1};
    }
    elsif ($rank_error) {
        my $error_ref = Evaluation::Ranking::compute_rank_error({
            test_ratings     => $test_ratings,
            predict_ref      => sub { return $predictor->predict(@_) },
            verbose          => $verbose,
        });

        my $re    = $error_ref->{re};
        my $sre   = $error_ref->{sre};
        my $ire   = $error_ref->{ire};
        my $isre  = $error_ref->{isre};
        my $nre   = $error_ref->{nre};
        my $nsre  = $error_ref->{nsre};
        my $nire  = $error_ref->{nire};
        my $nisre = $error_ref->{nisre};

        printf "; RE=$re, SRE=$sre, NRE=%.4f, NSRE=%.4f, ",     $nre, $nsre;
        printf "IRE=$ire, ISRE=$isre, NIRE=%.4f, NISRE=%.4f\n", $nire, $nisre;
    }
    else {
        my $PREDICTION_FILEHANDLE = undef;
        # TODO: make a command line switch for precision, too

        if ($prediction_file) {
            open $PREDICTION_FILEHANDLE, '>', $prediction_file
                or croak "Can't open '$prediction_file' for writing: $ERRNO";
        }

        my $error_ref = Evaluation::compute_error({
            test_ratings          => $test_ratings,
            predict_ref           => sub { return $predictor->predict(@_) },
            prediction_filehandle => $PREDICTION_FILEHANDLE,
            show_progress         => $show_progress,
            verbose               => $verbose,
        });
        if (defined $PREDICTION_FILEHANDLE) {
            close $PREDICTION_FILEHANDLE;
        }

        printf "; MAE=%.4f, rMAE=%.4f, RMSE=%.4f\n",
            $error_ref->{mae},
            $error_ref->{rounded_mae},
            $error_ref->{rmse};
    }
}

# TODO: re-integrate into main procedure ??
# TODO: move to its own script
sub run_eval_for_several_lambdas {

    my @lambdas = qw(0.7 0.75 0.8 0.85 0.9);

    my $predictor = pop @predictors;
    foreach my $l (@lambdas) {
        my $result_file = $several_lambdas;
        $result_file =~ s/LAMBDA/$l/;
        $predictor->{lambda} = $l;

        open my $RESULT_FILE, '>>', $result_file
            or croak "Can't open '$result_file' for appending: $ERRNO";
        # TODO: clean file handling

        my $description = $predictor->description;
        print $RESULT_FILE "'$description' ";
        if ($top_n) {
            my $result_ref = Evaluation::compute_top_n_error({
                top_n         => $top_n,
                test_ratings  => $test_ratings,
                known_ratings => $known_ratings,
                predict_ref   => sub { return $predictor->predict(@_) },
                show_progress => $show_progress,
                verbose       => $verbose,
            });
            printf $RESULT_FILE "n=$top_n; precision=%.4f, recall=%.4f, f1=%.4f\n",
                $result_ref->{precision}, $result_ref->{recall}, $result_ref->{f1};
        }
        elsif ($rank_error) {
            my $error_ref = Evaluation::Ranking::compute_rank_error({
                test_ratings     => $test_ratings,
                predict_ref      => sub { return $predictor->predict(@_) },
                verbose          => $verbose,
            });

            my $re    = $error_ref->{re};
            my $sre   = $error_ref->{sre};
            my $ire   = $error_ref->{ire};
            my $isre  = $error_ref->{isre};
            my $nre   = $error_ref->{nre};
            my $nsre  = $error_ref->{nsre};
            my $nire  = $error_ref->{nire};
            my $nisre = $error_ref->{nisre};

            printf $RESULT_FILE "; RE=$re, SRE=$sre, NRE=%.4f, NSRE=%.4f, ",     $nre, $nsre;
            printf $RESULT_FILE "IRE=$ire, ISRE=$isre, NIRE=%.4f, NISRE=%.4f\n", $nire, $nisre;
        }
        else {
            # TODO: make a command line switch for precision, too
            my $error_ref = Evaluation::compute_error({
                test_ratings     => $test_ratings,
                predict_ref      => sub { return $predictor->predict(@_) },
                prediction_filehandle => undef,  # TODO
                show_progress    => $show_progress,
                verbose          => $verbose,
            });

            printf $RESULT_FILE "; MAE=%.4f, MAEr=%.4f, RMSE=%.4f\n",
                $error_ref->{mae},
                $error_ref->{rounded_mae},
                $error_ref->{rmse};
        }
        close $RESULT_FILE;
    }
}

sub usage {
    my ($exit_code) = @_;

    print << 'END';
Evaluate different predictors using the MovieLens data.
(c) 2007, 2008 Zeno Gantner
        
usage: $PROGRAM_NAME [OPTIONS]

  general options:
    --help                     display this usage information and exit
    --verbose                  increment verbosity level by one
    --training-file=FILE       read training data from FILE
    --test-file=FILE           read test data from FILE
    --matrix-file-mode         data is in matrix files, not in MovieLens format
    --predictor=PRED           evaluate predictor PRED (possible values:
                               'average', 'user-average', 'item-average',
                               'global-average', 'coclustering', 'most-popular',
                               'naive-bayes'
    --top-n=N                  compute precision and recall for the top-N items
                               of each user
    --rank-error               compute rank errors
    --show-progress            print information about the progress to STDERR
    --prediction-file=FILE     write predictions to FILE
    --evaluate-all             evaluate all given predictors at once

  coclustering options:
    --read-cluster-file=FILE   read clustering from FILE
    --no-fix-results           don't fix results < 1 or > 5
    
  naive bayes options:
    --item-attrib-file=FILE    read item attributes from FILE
    --most-probable-rating     pick most probable rating (instead of using sum
                               all ratings weighted by probability)
    --sort-attributes          sort attributes when eliminating features for
                               numerical stability (this is a hack)

  ensemble options
    --joint-weighting=L        combine two predictors using the weighted
                               geometric mean with weights L and 1-L
    --linear-combination=L     combine two predictors using a linear combination
                               with weights L and 1-L
    --several-lambdas="L1 L2"  evaluate for several weight parameters
END

    exit $exit_code;
}
