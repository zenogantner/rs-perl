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

package Evaluation::Ranking;
our @EXPORT    = qw( compute_rank_error );
our @EXPORT_OK = qw( create_orders_for_users);  # allow export for testing purposes

use Ratings::Sparse;

sub compute_rank_error {
	my ($arg_ref) = @_;

	my $test_ratings     = $arg_ref->{test_ratings};
	my $predict_ref      = $arg_ref->{predict_ref};
	my $verbose          = exists $arg_ref->{verbose}          ? $arg_ref->{verbose}          : 0;
	#my $show_predictions = exists $arg_ref->{show_predictions} ? $arg_ref->{show_predictions} : 0;

	my $scale           = $test_ratings->{scale};
	my $number_of_users = $scale->number_of_users;
	my $rows_ref        = $test_ratings->get_rows;

	my $number_of_tests = scalar(keys %{$test_ratings->{matrix_ref}});
	if ($number_of_tests == 0) {
		die "Evaluation::Ranking::compute_rank_error: No tests defined. Abort.\n";
	}

	# remark: To iterate over the users is maybe not the fastest approach,
        #         but it is more clear than iterating over all ratings and computing
        #         all rankings on-the-fly ...

	my $rank_error_sum                        = 0;
	my $squared_rank_error_sum                = 0;
	my $rank_error_sum_ign                    = 0;
	my $squared_rank_error_sum_ign            = 0;
	my $normalized_rank_error_sum             = 0;
	my $normalized_squared_rank_error_sum     = 0;
	my $normalized_rank_error_sum_ign         = 0;
	my $normalized_squared_rank_error_sum_ign = 0;
	my $user_counter                          = 0;

	USER:
	foreach my $user_ratings_ref (@$rows_ref) {

		my $number_of_ratings_by_user = scalar(keys %$user_ratings_ref);
		
		next USER if $number_of_ratings_by_user <= 1;

		my $first_key = (keys %$user_ratings_ref)[0];
		my $user_id   = unpack($PACK_TEMPLATE, $first_key);
		print STDERR "$user_id " if $verbose > 1;

		my $result_ref   = create_orders_for_user({
			user_ratings_ref => $user_ratings_ref,
			predict_ref      => $predict_ref,
			scale            => $scale,
			user_id          => $user_id,
		});
		my $minrank1_ref     = $result_ref->{minrank1_ref};
		my $maxrank1_ref     = $result_ref->{maxrank1_ref};
		my $rank2_ref        = $result_ref->{rank2_ref};
		my $rated_items_ref  = $result_ref->{rated_items_ref};
		my $ignore_threshold = $result_ref->{ignore_threshold};

		# assertion
		if (scalar(keys %$minrank1_ref) != scalar(keys %$rank2_ref)
                  ||scalar(keys %$minrank1_ref) != scalar(@$rated_items_ref)) {
			die "O_1, O_2 and rated_items do not have the same size!\n";
		}

		# get rank errors for current user
		my $user_rank_error             = 0;
		my $user_squared_rank_error     = 0;
		my $user_rank_error_ign         = 0;
		my $user_squared_rank_error_ign = 0;
		foreach my $item_id (@$rated_items_ref) {
			my $min_distance = $rank2_ref->{$item_id}    - $minrank1_ref->{$item_id};
                        my $max_distance = $maxrank1_ref->{$item_id} - $rank2_ref->{$item_id};
			if ($min_distance < 0) {
				$user_rank_error         = $user_rank_error         + abs($min_distance);
				$user_squared_rank_error = $user_squared_rank_error + $min_distance * $min_distance;
				if ($verbose > 1) {
					print STDERR "$rank2_ref->{$item_id} instead of ";
					print STDERR "$minrank1_ref->{$item_id}, $maxrank1_ref->{$item_id} ";
					print STDERR "distance: $min_distance\n";
				} # if
			} # if
			if ($max_distance < 0) {
				$user_rank_error         = $user_rank_error         + abs($max_distance);
				$user_squared_rank_error = $user_squared_rank_error + $max_distance * $max_distance;
				if ($verbose > 1) {
					print STDERR "$rank2_ref->{$item_id} instead of ";
					print STDERR "$minrank1_ref->{$item_id}, $maxrank1_ref->{$item_id} ";
					print STDERR "distance: $max_distance\n";
				} # if
			} # if


			# assertion
			if (!defined $ignore_threshold) {
				die "ignore_threshold not defined.\n";
			}
			# (for rank error which ignores bad ratings)
			if (($rank2_ref->{$item_id} <= $ignore_threshold) || ($minrank1_ref->{$item_id} <= $ignore_threshold)) {
				my $min_distance = $rank2_ref->{$item_id}    - $minrank1_ref->{$item_id};
	                        my $max_distance = $maxrank1_ref->{$item_id} - $rank2_ref->{$item_id};
				if ($min_distance < 0) {
					$user_rank_error_ign         = $user_rank_error_ign         + abs($min_distance);
					$user_squared_rank_error_ign = $user_squared_rank_error_ign + $min_distance * $min_distance;
				} # if
					if ($max_distance < 0) {
					$user_rank_error_ign         = $user_rank_error_ign         + abs($max_distance);
					$user_squared_rank_error_ign = $user_squared_rank_error_ign + $max_distance * $max_distance;
				} # if
			}
			else {
				print STDERR "... ignored because of threshold $ignore_threshold\n" if $verbose > 1;
			}
			
		} # foreach

		my $denominator                    = ($number_of_ratings_by_user - 1) * $number_of_ratings_by_user;
		my $user_normalized_rank_error     = $user_rank_error     / $denominator;
		my $user_normalized_rank_error_ign = $user_rank_error_ign / $denominator;

		$denominator                               = $denominator * $number_of_ratings_by_user;
		my $user_normalized_squared_rank_error     = $user_squared_rank_error / $denominator;
		my $user_normalized_squared_rank_error_ign = $user_squared_rank_error / $denominator;

		$rank_error_sum                    = $rank_error_sum                    + $user_rank_error;
		$squared_rank_error_sum            = $squared_rank_error_sum            + $user_squared_rank_error;

		$rank_error_sum_ign                = $rank_error_sum_ign                + $user_rank_error_ign;
		$squared_rank_error_sum_ign        = $squared_rank_error_sum_ign        + $user_squared_rank_error_ign;

		$normalized_rank_error_sum         = $normalized_rank_error_sum         + $user_normalized_rank_error;
		$normalized_squared_rank_error_sum = $normalized_squared_rank_error_sum + $user_normalized_squared_rank_error;

		$normalized_rank_error_sum_ign
                 = $normalized_rank_error_sum_ign         + $user_normalized_rank_error_ign;
		$normalized_squared_rank_error_sum_ign
                 = $normalized_squared_rank_error_sum_ign + $user_normalized_squared_rank_error_ign;

		
		$user_counter++;

	} # foreach USER

	return {
		re    => $rank_error_sum,
		sre   => $squared_rank_error_sum,
		ire   => $rank_error_sum_ign,
		isre  => $squared_rank_error_sum_ign,
		nre   => $normalized_rank_error_sum         / $user_counter,
		nsre  => $normalized_squared_rank_error_sum / $user_counter,
		nire  => $normalized_rank_error_sum_ign          / $user_counter,
		nisre => $normalized_squared_rank_error_sum_ign  / $user_counter,
	};
}

sub create_orders_for_user {
		my ($argref) = @_;

		my $user_ratings_ref = $argref->{user_ratings_ref};
		my $predict_ref      = $argref->{predict_ref};
		my $scale            = $argref->{scale};
		my $user_id          = $argref->{user_id};

		# create equivalence classes from test ratings
		#   and find out which items have to be predicted and ranked by the recommender
		my %rating_items      = ();
		my @items_to_be_rated = ();
		foreach my $possible_rating ($scale->min .. $scale->max) { # this only works for integer ratings
			$rating_items{$possible_rating} = [];		
		}
		foreach my $key (keys %$user_ratings_ref) {
			my ($user_id_from_key, $item_id) = unpack($PACK_TEMPLATE, $key);
			if ($user_id != $user_id_from_key) {
				die "Evaluation::Ranking::create_orders_for_user: different users $user_id and $user_id_from_key.\n";
			}
			my $rating = $user_ratings_ref->{$key};

			push @{$rating_items{$rating}}, $item_id;
			push @items_to_be_rated, $item_id;
		} # foreach

		# create order O_1 over equivalence classes,
		my %minrank1 = ();
		my %maxrank1 = ();
		my $number_of_better_items = 0;
		for (my $possible_rating = $scale->max; $possible_rating >= $scale->min; $possible_rating--) {
			# -- this only works for integer ratings --
			my $number_of_items_with_rating    = scalar(@{$rating_items{$possible_rating}});
			my $number_of_same_or_better_items = $number_of_better_items + $number_of_items_with_rating;
			foreach my $item_id (@{$rating_items{$possible_rating}}) {
				$minrank1{$item_id} = $number_of_better_items + 1;
				$maxrank1{$item_id} = $number_of_same_or_better_items;
#				print STDERR "$item_id min, max: $minrank1{$item_id}, $maxrank1{$item_id}\n";
			}
			$number_of_better_items = $number_of_same_or_better_items;
		}

		# This is MovieLens-specific; extend scale so that there is a list of ratings that can be considered as bad ...
		my $ignore_threshold = scalar(@items_to_be_rated) - scalar(@{$rating_items{1}}) - scalar(@{$rating_items{2}});
		# here, ratings of 1 and 2 stars are BAD

		# predict ratings for all necessary items
		my %predicted_rating = ();
		foreach my $item_id (@items_to_be_rated) {
			$predicted_rating{$item_id} = &$predict_ref($user_id, $item_id);
		} # foreach

		my @rated_items = sort { $predicted_rating{$b} <=> $predicted_rating{$a} } @items_to_be_rated;

		# create order O_2 over all necessary items
		my %rank2 = ();
		for (my $i = 0; $i < scalar(@rated_items); $i++) {
			$rank2{$rated_items[$i]} = $i + 1;
		} # for

		my $result_ref = {
			minrank1_ref     => \%minrank1,
			maxrank1_ref     => \%maxrank1,
			rank2_ref        => \%rank2,
			rated_items_ref  => \@rated_items,
			ignore_threshold => $ignore_threshold,
		};

		return $result_ref;
}


1;
