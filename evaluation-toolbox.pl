#!/usr/bin/perl

# This file is part of the Perl Collaborative Filtering Framework

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

# paired t test

use strict;
use warnings;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
use English qw( -no_match_vars );
use Carp;

use Getopt::Long;
use Regexp::Common qw /number/;

my $help              = 0;
my $verbose           = 0;
my $forgiving         = 0;
my $confidence        = 95;
my $d                 = 6; # output accuracy in digits
my $greater_better    = 0;
my $graphviz_measure  = '';
my $list_best_measure = '';
my $list_averages_for_measure = '';

my $graphviz_aspect_ratio = sqrt(2);

GetOptions(
    'help'                        => \$help,
    'verbose+'                    => \$verbose,
    'forgiving'                   => \$forgiving,
    'output-accuracy=i'           => \$d,
    'greater-better'              => \$greater_better,  # TODO: should also change output order
    'graphviz-measure=s'          => \$graphviz_measure,
    'list-best-for-measure=s'     => \$list_best_measure,
    'list-averages-for-measure=s' => \$list_averages_for_measure,
) or usage(-1);

my @result_files = @ARGV;

if ($help) {
    usage(0);
}

if (scalar @result_files == 0) {
    usage(-1);
}

## TODO: make CPAN module for the t test
## TODO: use CPAN module Statistics::Distributions
my %student = (
    # one-sided    75%       80%     85%     90%     95%     97.5%     99%     99.5%     99.75%     99.9%     99.95%
    # two-sided    50%       60%     70%     60%     90%     95%     98%     99%     99.5%     99.8%     99.9%
    1     => [ qw{1.000     1.376     1.963     3.078     6.314     12.71     31.82     63.66     127.3     318.3     636.6} ],
    2     => [ qw{0.816     1.061     1.386     1.886     2.920     4.303     6.965     9.925     14.09     22.33     31.60} ],
    3     => [ qw{0.765     0.978     1.250     1.638     2.353     3.182     4.541     5.841     7.453     10.21     12.92} ],
    4     => [ qw{0.741     0.941     1.190     1.533     2.132     2.776     3.747     4.604     5.598     7.173     8.610} ],
    5     => [ qw{0.727     0.920     1.156     1.476     2.015     2.571     3.365     4.032     4.773     5.893     6.869} ],
    6     => [ qw{0.718     0.906     1.134     1.440     1.943     2.447     3.143     3.707     4.317     5.208     5.959} ],
    7     => [ qw{0.711     0.896     1.119     1.415     1.895     2.365     2.998     3.499     4.029     4.785     5.408} ],
    8     => [ qw{0.706     0.889     1.108     1.397     1.860     2.306     2.896     3.355     3.833     4.501     5.041} ],
    9     => [ qw{0.703     0.883     1.100     1.383     1.833     2.262     2.821     3.250     3.690     4.297     4.781} ],
    10    => [ qw{0.700     0.879     1.093     1.372     1.812     2.228     2.764     3.169     3.581     4.144     4.587} ],
    11    => [ qw{0.697     0.876     1.088     1.363     1.796     2.201     2.718     3.106     3.497     4.025     4.437} ],
    12    => [ qw{0.695     0.873     1.083     1.356     1.782     2.179     2.681     3.055     3.428     3.930     4.318} ],
    13    => [ qw{0.694     0.870     1.079     1.350     1.771     2.160     2.650     3.012     3.372     3.852     4.221} ],
    14    => [ qw{0.692     0.868     1.076     1.345     1.761     2.145     2.624     2.977     3.326     3.787     4.140} ],
    15    => [ qw{0.691     0.866     1.074     1.341     1.753     2.131     2.602     2.947     3.286     3.733     4.073} ],
    16    => [ qw{0.690     0.865     1.071     1.337     1.746     2.120     2.583     2.921     3.252     3.686     4.015} ],
    17    => [ qw{0.689     0.863     1.069     1.333     1.740     2.110     2.567     2.898     3.222     3.646     3.965} ],
    18    => [ qw{0.688     0.862     1.067     1.330     1.734     2.101     2.552     2.878     3.197     3.610     3.922} ],
    19    => [ qw{0.688     0.861     1.066     1.328     1.729     2.093     2.539     2.861     3.174     3.579     3.883} ],
    20    => [ qw{0.687     0.860     1.064     1.325     1.725     2.086     2.528     2.845     3.153     3.552     3.850} ],
    21    => [ qw{0.686     0.859     1.063     1.323     1.721     2.080     2.518     2.831     3.135     3.527     3.819} ],
    22    => [ qw{0.686     0.858     1.061     1.321     1.717     2.074     2.508     2.819     3.119     3.505     3.792} ],
    23    => [ qw{0.685     0.858     1.060     1.319     1.714     2.069     2.500     2.807     3.104     3.485     3.767} ],
    24    => [ qw{0.685     0.857     1.059     1.318     1.711     2.064     2.492     2.797     3.091     3.467     3.745} ],
    25    => [ qw{0.684     0.856     1.058     1.316     1.708     2.060     2.485     2.787     3.078     3.450     3.725} ],
    26    => [ qw{0.684     0.856     1.058     1.315     1.706     2.056     2.479     2.779     3.067     3.435     3.707} ],
    27    => [ qw{0.684     0.855     1.057     1.314     1.703     2.052     2.473     2.771     3.057     3.421     3.690} ],
    28    => [ qw{0.683     0.855     1.056     1.313     1.701     2.048     2.467     2.763     3.047     3.408     3.674} ],
    29    => [ qw{0.683     0.854     1.055     1.311     1.699     2.045     2.462     2.756     3.038     3.396     3.659} ],
    30    => [ qw{0.683     0.854     1.055     1.310     1.697     2.042     2.457     2.750     3.030     3.385     3.646} ],
    40    => [ qw{0.681     0.851     1.050     1.303     1.684     2.021     2.423     2.704     2.971     3.307     3.551} ],
    50    => [ qw{0.679     0.849     1.047     1.299     1.676     2.009     2.403     2.678     2.937     3.261     3.496} ],
    60    => [ qw{0.679     0.848     1.045     1.296     1.671     2.000     2.390     2.660     2.915     3.232     3.460} ],
    80    => [ qw{0.678     0.846     1.043     1.292     1.664     1.990     2.374     2.639     2.887     3.195     3.416} ],
    100   => [ qw{0.677     0.845     1.042     1.290     1.660     1.984     2.364     2.626     2.871     3.174     3.390} ],
    120   => [ qw{0.677     0.845     1.041     1.289     1.658     1.980     2.358     2.617     2.860     3.160     3.373} ],
    infty => [ qw{0.674     0.842     1.036     1.282     1.645     1.960     2.326     2.576     2.807     3.090     3.291} ],
);

my %one_sided_index = (
    75 => 0, 80 => 1, 85 => 2, 90 => 3, 95 => 4, 97.5 => 5,    99 => 6, 99.5 => 7, 99.75 => 8, 99.9 => 9, 99.95 => 10
);
my %two_sided_index = (
    50 => 0, 60 => 1, 70 => 2, 60 => 3, 90 => 4, 95 =>5,    98 => 6, 99 => 7,   99.5 => 8,  99.8 => 9, 99.9 => 10
);


my %sample_results    = ();
my %method_parameters = ();

foreach my $filename (@result_files) {

    my $line_counter           = 0;
    $sample_results{$filename} = [];
    
    open FILE, $filename
        or die "Could not open '$filename': $ERRNO\n";

    LINE: while (<FILE>) {
        next LINE if /^\s*$/;

        my $line = $_;
        chomp $line;

        if ($line =~ m/^'(.+)'(.*);(.+)$/) {
            my $method            = $1;
            my $method_parameters = $2;
            my $key_value_pairs   = $3;

            $sample_results{$filename}->[$line_counter] = extract_values($key_value_pairs);
            $method_parameters{$filename} = extract_values($method_parameters);

            $line_counter++;
        }
        else {
            print STDERR "Failed to parse line '$line' of file '$filename'.\n";
            if (!$forgiving) {
                die "Abort. Please fix this.\n";
            }
        }
    }
    close FILE;
}


my @samples = keys %sample_results;

my %means = ();


foreach my $i (0 .. scalar(@samples) - 1) {
    my $sample      = $samples[$i];
    my @sample      = @{$sample_results{$sample}};

    $means{$sample} = {};

    print STDERR "$sample: " if $verbose;
    foreach my $measure (keys %{$sample_results{$sample}->[0]}) {
        print STDERR "\tmeasure '$measure': " if $verbose;

        my @x = ();
        for my $n (0 .. scalar(@sample) - 1) {
            push @x, $sample[$n]->{$measure};
        }

        my $result_ref = compute_statistics(\@x);

        print STDERR "mean=$result_ref->{mean}" if $verbose;
        print STDERR ", sd=$result_ref->{sd}, variance $result_ref->{variance}" if $verbose;

        $means{$sample}->{$measure} = $result_ref->{mean};
    }
    print STDERR "\n" if $verbose;

}


print STDERR "\n" if $verbose;

my %greater = ();
my %less    = ();
foreach my $measure (keys %{$sample_results{$samples[0]}->[0]}) {
    $greater{$measure} = [];
    $less{$measure}    = [];
    foreach my $i (0 .. scalar(@samples) - 1) {
        $greater{$measure}->[$i] = [];
        $less{$measure}->[$i]    = [];
    }
}

foreach my $i (0 .. scalar(@samples) - 2) {
    my $sample1 = $samples[$i];
    my @sample1 = @{$sample_results{$sample1}};
    
    foreach my $j ($i + 1 .. scalar(@samples) - 1) {
        my $sample2 = $samples[$j];
        my @sample2 = @{$sample_results{$sample2}};

        print STDERR "$sample1 vs. $sample2...\n" if $verbose;
        foreach my $measure (keys %{$sample_results{$sample1}->[0]}) {
            print STDERR "measure: $measure\n" if $verbose;
            
            my @x = ();
            my @y = ();
            for my $n (0 .. scalar(@sample1) - 1) {
                push @x, $sample1[$n]->{$measure};
                push @y, $sample2[$n]->{$measure};
            }

            my $result_ref = stat_test({
                x_ref      => \@x,
                y_ref      => \@y,
                confidence => $confidence,
            });

            print STDERR "\tUsing a confidence level of ${confidence}%, " if $verbose;
            if ($result_ref->{x_significant}) {
                print STDERR "x is significantly greater than y.\n" if $verbose;
                push @{$greater{$measure}->[$i]}, $j;
                push @{$less{$measure}->[$j]}, $i;
            }
            elsif ($result_ref->{y_significant}) {
                print STDERR "y is significantly greater than x.\n" if $verbose;
                push @{$greater{$measure}->[$j]}, $i;
                push @{$less{$measure}->[$i]}, $j;
            }
            else {
                print STDERR "none of the two samples is significantly different from the other.\n" if $verbose;
            }
            if ($verbose > 1) {
                printf STDERR "\tt=%.${d}f, ny=%.${d}f.\n", $result_ref->{t}, $result_ref->{ny};
                printf STDERR "\tvariance=%.${d}f, sd=%.${d}f\n", $result_ref->{variance}, $result_ref->{sd};
                printf STDERR "\ts_delta=%.${d}f\n", $result_ref->{s_delta};
            }
            printf STDERR "\tmean difference=%.${d}f\n", $result_ref->{mean_difference} if $verbose;
            printf STDERR "\tconfidence interval: %.${d}f, %.${d}f\n", $result_ref->{from}, $result_ref->{to} if $verbose;
        }
        print STDERR "\n" if $verbose;
    }

    print STDERR "\n" if $verbose;
}

if ($list_best_measure) {
    my $neg_cmp_ref = $greater_better ? \%less    : \%greater;
    my $pos_cmp_ref = $greater_better ? \%greater : \%less;
    output_top_methods(\@samples, $neg_cmp_ref, $pos_cmp_ref, $list_best_measure);
    exit 0;
}

if ($list_averages_for_measure) {
    my $neg_cmp_ref = $greater_better ? \%less    : \%greater;
    my $pos_cmp_ref = $greater_better ? \%greater : \%less;
    output_averages(\@samples, $neg_cmp_ref, $pos_cmp_ref, $list_averages_for_measure);
    exit 0;
}

my $cmp_ref = $greater_better ? \%greater : \%less;
if ($graphviz_measure) {
    output_as_dotfile(\@samples, $cmp_ref, $graphviz_measure);
} else {
    # TODO: sort by number of dominated strategies?
    my $cmp_char = $greater_better ? '>' : '<';
    print "Summary:\n";
    foreach my $measure (keys %{$sample_results{$samples[0]}->[0]}) {
        print "$measure\n";
        foreach my $i (0 .. scalar(@samples) - 1) {
            if (scalar(@{$cmp_ref->{$measure}->[$i]}) > 0) {
                print "$samples[$i] $cmp_char\n";
                foreach my $j (@{$cmp_ref->{$measure}->[$i]}) {
                    print "\t$samples[$j]\n";
                }
            }
        }
    }
}

sub extract_values {
    my ($string) = @_;

    my %hash = ();

    while ($string =~ s/(\w*)=($RE{num}{real})//) {
        my $key   = $1;
        my $value = $2;

        $hash{$key} = $value;
    }

    return \%hash;
}

sub compute_statistics {
    my ($sample_ref) = @_;

    my %result = ();

    # mean
    my $sum = 0;
    for my $value (@$sample_ref) {
        if (defined $value) {
            $sum = $sum + $value;
        }
        else {
            die 'Encountered undefined value in array @$sample_ref.' . "\n";
        }
    }
    $result{mean} = $sum / scalar(@$sample_ref);

    # variance and standard deviation
    $sum = 0;
    for my $value (@$sample_ref) {
        if ($verbose > 2) {
            print $value;
            print ' - ';
            print $result{mean};
            print ' = ';
            print ($value - $result{mean});
            print ' ... ^2 --> ';
            print (($value - $result{mean}) ** 2);
            print "\n";
        }
        $sum = $sum + ($value - $result{mean}) ** 2;
    }
    if ($verbose > 1) {
        print "quadratic sum: $sum\n";
    }
    my $k = scalar(@$sample_ref);
    $result{variance} = $sum / $k;
    $result{s_delta}  = sqrt ($sum / ($k * ($k - 1)));
    $result{sd}       = sqrt($result{variance});
    
    return \%result;
}

sub stat_test {
    my ($arg_ref) = @_;

    my $x_ref = ($arg_ref->{x_ref});
    my $y_ref = ($arg_ref->{y_ref});

    my $k = scalar(@$x_ref);

    # compute difference between the two methods
    my @differences = ();
    foreach my $i (0 .. $k - 1) {
        if (defined $x_ref->[$i] && defined $y_ref->[$i]) {
            $differences[$i] = $x_ref->[$i] - $y_ref->[$i];
        }
        else {
            warn "x or y value for index $i is not defined.\n";
            die "Abort.\n" if !$forgiving;
        }
    }

    my $statistics_ref = compute_statistics(\@differences);
    my $mean_difference    = $statistics_ref->{mean};
    my $variance           = $statistics_ref->{variance};
    my $standard_deviation = $statistics_ref->{sd};
    my $s_delta            = $statistics_ref->{s_delta};

    my $t;
    if ($s_delta == 0) {
        $t = 10000;
    }
    else {
        $t = $mean_difference / $s_delta;  # see Mitchell, equation 5.18
    }

    my $index = $two_sided_index{$arg_ref->{confidence}};
    my $ny    = $student{$k - 1}->[$index];

    my %result = ();

    $result{variance} = $variance;
    $result{sd}       = $standard_deviation;
    $result{s_delta}  = $s_delta;
    $result{from}     = $mean_difference - ($ny * $s_delta);
    $result{to}       = $mean_difference + ($ny * $s_delta);
    $result{mean_difference}    = $mean_difference;
    $result{t}                  = $t;
    $result{ny}                 = $ny;
    $result{x_significant}      = ($t       > $ny);
    $result{y_significant}      = (- 1 * $t > $ny);
    $result{degrees_of_freedom} = $k - 1;

    return \%result;
}

sub name_filter {
    my ($string) = @_;

    # remove beginning
    $string =~ s/^\.\.\/results\/error-//;
    $string =~ s/^\.\.\/results\/rank-error-//;
    # remove end
    $string =~ s/-static-coclustering$//;

    # '-' => '_'
    $string =~ s/-/_/g;

    if ($graphviz_measure) {
        # '.' => '_'
        $string =~ s/\./_/g;
    }

    # 'nb_sort' => ''
    $string =~ s/_?nb_sort_?//g;

    return $string;
}

sub output_as_dotfile {
    my ($samples_ref, $cmp_ref, $measure) = @_;

    print "digraph $measure {\n";
    print "    ratio=$graphviz_aspect_ratio;\n";
    foreach my $i (0 .. scalar(@$samples_ref) - 1) {
        my $node = name_filter($samples_ref->[$i]);
        print "    $node;\n";
        if (scalar(@{$cmp_ref->{$measure}->[$i]}) > 0) {
            foreach my $j (@{$cmp_ref->{$measure}->[$i]}) {
                my $target_node = name_filter($samples_ref->[$j]);
                print "    $node -> $target_node;\n";
            }
        }
        print "\n";
    }
    print "}\n";
}

sub output_top_methods {
    my ($samples_ref, $neg_cmp_ref, $pos_cmp_ref, $measure) = @_;

    my %best_methods = ();
    foreach my $i (0 .. scalar(@$samples_ref) - 1) {
        my $filename = $samples_ref->[$i];
        if (scalar(@{$neg_cmp_ref->{$measure}->[$i]}) == 0) {
            my $number_of_dominated_methods = scalar(@{$pos_cmp_ref->{$measure}->[$i]});
            $best_methods{$filename} = $number_of_dominated_methods;
        }
    }
    my @best_keys = sort { $best_methods{$b} <=> $best_methods{$a} } keys %best_methods;
    print "Best methods\n";
    foreach my $filename (@best_keys) {
            my $mean   = $means{$filename}->{$measure};
            my $method = name_filter($filename);
            print "  $method: $best_methods{$filename} $mean\n";
    }
    print "\n";
}

sub output_averages {
    my ($samples_ref, $neg_cmp_ref, $pos_cmp_ref, $measure) = @_;

    my @best_filenames = sort { $means{$a}->{$measure} <=> $means{$b}->{$measure} } @$samples_ref;

    print "Averages for measure $measure\n";
    foreach my $filename (@best_filenames) {
            my $mean   = $means{$filename}->{$measure};
            # TODO: show several attributes of the method
            my $method = name_filter($filename);
            print "  $method: $mean\n";
    }
    print "\n";
}

sub usage {
    my ($exit_code) = @_;
    
    print << 'END';
    usage: ./$PROGRAM_NAME [OPTIONS] logfile1 ... logfileN

    --help                              display this usage information
    --verbose                           increment verbosity level by one
    --forgiving                         do not stop when encountering errors
    --output-accuracy=DIGITS            set output accuracy to DIGITS
    --greater-better                    greater values are better values (default: smaller is better)
    --graphviz-measure=MEASURE          create a GraphViz .dot file visualizing significant domination wrt. to MEASURE
    --list-best-for-measure=MEASURE     list all methods that are not dominated by another method wrt. to MEASURE
    --list-averages-for-measure=MEASURE simply compute average MEASURE for every method
END
    
    exit $exit_code;
}
