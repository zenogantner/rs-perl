# This file is part of the Perl Collaborative Filtering Framework
#
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

package Evaluation;
our @EXPORT = qw( compute_error );

use Carp;
use Term::ProgressBar;

use Ratings::Sparse;

# TODO: think about better name
#       two modules: Evaluation::Error, Evaluation::TopN

sub compute_error {
	my ($arg_ref) = @_;

	my $test_ratings          = $arg_ref->{test_ratings};
	my $predict_ref           = $arg_ref->{predict_ref};
	my $verbose               = exists $arg_ref->{verbose}          ? $arg_ref->{verbose}          : 0;
	my $PREDICTION_FILEHANDLE = $arg_ref->{prediction_filehandle};

	my $scale = $test_ratings->{scale};

	my $number_of_tests = scalar(keys %{$test_ratings->{matrix_ref}});
	if ($number_of_tests == 0) {
		croak 'No tests defined';
	}

	my $exact_error   = 0;
	my $rounded_error = 0;
	my $squared_error   = 0;
	foreach my $key (keys %{$test_ratings->{matrix_ref}}) {         # TODO make proper access method
		# TODO: for Karen-MAE: We need to know the known ratings (and ignore these ...)
		my ($user_id, $item_id) = unpack($PACK_TEMPLATE, $key);
		my $real_rating = $test_ratings->{matrix_ref}->{$key};  # TODO make proper access method
		my $prediction  = &$predict_ref($user_id, $item_id);

        if (defined $PREDICTION_FILEHANDLE) {
		    print $PREDICTION_FILEHANDLE "$user_id\t$item_id\t$prediction\n";
        }

		$exact_error   = $exact_error   + abs($real_rating - $prediction);
		$rounded_error = $rounded_error + abs($real_rating - int($prediction + 0.5));
		$squared_error = $squared_error + ($real_rating - $prediction) * ($real_rating - $prediction);

		if ($prediction < $scale->min) {
			warn "Prediction $prediction is smaller than minimal legal value.\n";
		}
		if ($prediction > $scale->max) {
			warn "Prediction $prediction is smaller than minimal legal value.\n";
		}
	}

	my $mae         = $exact_error   / $number_of_tests;
	my $rounded_mae = $rounded_error / $number_of_tests;
	my $rmse        = sqrt($squared_error / $number_of_tests);

	my $result_ref = {
		mae         => $mae,
		rounded_mae => $rounded_mae,
		rmse        => $rmse,
	};

	return $result_ref;
}


# TODO:
#  implement other types of relevance:
#    - 4-5 => relevant, 1-3 not =>  not relevant (or 3-5, 1-2)
#    - top percentile for each user
sub compute_top_n_error {
	my ($arg_ref) = @_;

	my $top_n         = $arg_ref->{top_n};
	my $test_ratings  = $arg_ref->{test_ratings};
	my $known_ratings = $arg_ref->{known_ratings};
	my $predict_ref   = $arg_ref->{predict_ref};     # reference to the prediction function
	my $show_progress = $arg_ref->{show_progress};
	my $verbose       = $arg_ref->{verbose};

	my $scale           = $known_ratings->{scale};
	my $number_of_users = $scale->number_of_users;
	my $number_of_items = $scale->number_of_items;

	print STDERR "Complete data: $number_of_users users, $number_of_items items\n" if $verbose;

	if (!defined $test_ratings) {
		croak 'test_ratings not defined';
	}

	my $progress;
	if ($show_progress) {
		$progress = Term::ProgressBar->new({
			#name  => 'Powers',
        	        count => $number_of_users,
        	        ETA   => 'linear',
		});
	}

	# get recommended top n
	my @predicted_top_n = ();
	foreach my $user_id (0 .. $number_of_users - 1) {
		my %prediction = ();
		foreach my $item_id (0 .. $number_of_items - 1) {
			if (! $known_ratings->entry_exists($user_id, $item_id)) {
				$prediction{$item_id} = &$predict_ref($user_id, $item_id);
			}
		}
		my @keys = sort {$prediction{$b} <=> $prediction{$a}} keys %prediction;
	        $predicted_top_n[$user_id] = [ @keys[0 .. ($top_n - 1)] ];
		if ($show_progress) {
			$progress->update($user_id);
		}
	}
	# destroy progress bar?

	# get actually relevant items
	my $user_ratings_ref = $test_ratings->get_rows;
	#if (!defined $user_ratings_ref) {
	#	croak 'user_ratings_ref not defined'
	#}
	my @actually_relevant = ();
	foreach my $user_id (0 .. $number_of_users - 1) {
		my %user_ratings;
		if (defined $user_ratings_ref->[$user_id]) {
			%user_ratings = %{$user_ratings_ref->[$user_id]};
		}
		else {
			%user_ratings = ();
		}
		
		#print STDERR "Number of ratings for user $user_id: " . scalar(keys %user_ratings) . "\n" if $verbose;
		my @keys = sort{$user_ratings{$a} <=> $user_ratings{$b}} keys %user_ratings;
		my @relevant_items = ();
		foreach my $key (@keys) {
			my ($row, $item_id) = unpack($PACK_TEMPLATE, $key);
			push @relevant_items, $item_id;
		}
		$actually_relevant[$user_id] = \@relevant_items;
	}

	my $hits         = 0;  my $precision_sum = 0;
	my $selected_sum = 0;  my $recall_sum    = 0;
	my $relevant_sum = 0;  my $f1_sum        = 0;
	my $users_without_rated_items = 0;
	# iterate over all users to find the hits
	EVALUATE_USER: foreach my $user_id (0 .. $number_of_users - 1) {
		my @actual    = @{$actually_relevant[$user_id]};

		# only look at users which have at least one rating in the test set
		if (scalar(@actual) == 0) {
			$users_without_rated_items++;
			next EVALUATE_USER;
		}

		my %actual    = ();
		foreach (@actual) {
			$actual{$_} = 1;
		}
		my @predicted = @{$predicted_top_n[$user_id]};

		# compute per-user statistics
		my $user_hits = 0;
		foreach my $predicted_item_id (@predicted) {
			if (exists $actual{$predicted_item_id}) {
				$user_hits++;
			}
		}
		my $user_relevant_items = scalar(@actual);
		my $user_selected       = scalar(@predicted);

		# add the per-user statistics to the sums
		$selected_sum = $selected_sum + $user_selected;
		$relevant_sum = $relevant_sum + $user_relevant_items;
		$hits         = $hits + $user_hits;
	}

	print "$hits hits, $selected_sum selected items, $relevant_sum relevant items.\n" if $verbose;

	#my $precision = $hits / $selected_sum; # selected_sum may be smaller than top_n
	my $precision = $hits / ($top_n * $number_of_users);
	# actually, this is not really the recall, see Herlocker, Konstan, Terveen, Riedl, section 4.1.2
	my $recall    = $hits / $relevant_sum;
	my $f1;
	if ($precision + $recall != 0) {
		$f1 = (2 * $precision * $recall) / ($precision + $recall);
	}
	else {
		$f1 = 0;
	}

    # TODO: use Statistics::Contingency
	return {
		precision => $precision,
		recall    => $recall,
		f1        => $f1,
	};
}

1;
