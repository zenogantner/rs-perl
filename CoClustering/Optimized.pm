# Compute co-clusters for a given matrix.
# The naming and use of variables follows the paper/technical report by Thomas George and Srujana Merugu.
# Everywhere the naming differs, there is a notice stating so.
# In the papers, the indices start with 1, in the program they are zero-based.

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

package CoClustering::Optimized;
use base 'Exporter';
our @EXPORT = qw( $PACK_TEMPLATE );
our @EXPORT_OK = qw( compute_exact_error );

use CoClustering::Utility;
use Ratings::Sparse;

sub static_training {
	my ($arg_ref) = @_;

	# "constants"
	my $show_exact_error = 0;
	my $compute_average_twice = 0;

	my $ratings = $arg_ref->{known_ratings};	
	my $verbose        = exists $arg_ref->{verbose}        ? $arg_ref->{verbose}        : 0;
	my $debug          = exists $arg_ref->{debug}          ? $arg_ref->{debug}          : 0;
	my $max_iterations = exists $arg_ref->{max_iterations} ? $arg_ref->{max_iterations} : 1000;
	my $binary_ratings = exists $arg_ref->{binary}         ? $arg_ref->{binary}         : 0;
	my $random         = exists $arg_ref->{random}         ? $arg_ref->{random}         : 0;

	my $m = $ratings->{scale}->number_of_users;
	my $n = $ratings->{scale}->number_of_items;

	# Step 1. Initialize the cluster assignments
	my @user_clustering;
	my $k;
	if (exists $arg_ref->{row_clustering_ref}) {
		@user_clustering = @{$arg_ref->{row_clustering_ref}};
		$k = array_get_maximum_value(@user_clustering) + 1;
	}
	else {
		$k = $arg_ref->{user_clusters};
		@user_clustering = CoClustering::Utility::create_clustering({
			number_of_objects  => $m,
			number_of_clusters => $k,
			random             => $random,
		});
	}
	my @item_clustering;
	my $l;
	if (exists $arg_ref->{col_clustering_ref}) {
		@item_clustering = @{$arg_ref->{col_clustering_ref}};
		$l = array_get_maximum_value(@user_clustering) + 1;
	}
	else {
		$l = $arg_ref->{item_clusters};
		@item_clustering = CoClustering::Utility::create_clustering({
			number_of_objects  => $n,
			number_of_clusters => $l,
			random             => $random,
		});
	}

	my @rating_indices    = keys %{$ratings->{matrix_ref}};
	my $number_of_ratings = @rating_indices;
	if ($number_of_ratings == 0) {
		die "Cannot cluster a matrix without any entries!\n";
	}

	my @rows = @{$ratings->get_rows};
	my @cols = @{$ratings->get_cols};

	# Compute invariant averages
	my $global_average = $ratings->{global_average};
	my @a_r = @{$ratings->compute_row_averages};
	my @a_c = @{$ratings->compute_col_averages};
	# Compute the invariant matrix (called A^{tmp1} in section 4.1 of the technical report)
	# Note that this is, besides the matrix we are co-clustering, the only really invariant matrix
        # in this algorithm.
	my %invariant_matrix = ();
	foreach my $key (@rating_indices) {
		my ($row, $col) = unpack($PACK_TEMPLATE, $key);
	
		$invariant_matrix{$key} = $ratings->{matrix_ref}->{$key} - $a_r[$row] - $a_c[$col];
	}

	my $counter = 0;
	my $modified = 1;
	LOOP:
	while ($counter < $max_iterations && $modified) {

		my $approx_error = 0;
		$modified = 0;

		# Step 2a. Compute averages ...
		my ($a_rc_ref, $a_cc_ref, $a_coc_ref) = compute_cluster_averages({
			known_ratings      => $ratings,
			row_clustering_ref => \@user_clustering,
			col_clustering_ref => \@item_clustering,
			k                  => $k,
			l	           => $l,
		});

		# 2b. Update row cluster assignments
		my @new_user_clustering;
		# Compute invariant matrix
		my %sum = ();
		my %count = ();
		foreach my $rating_index (@rating_indices) {
			my ($row, $col) = unpack($PACK_TEMPLATE, $rating_index);
			my $key = pack($PACK_TEMPLATE, $row, $item_clustering[$col]);
			if (exists $sum{$key}) {
				$sum{$key} = $sum{$key} + $invariant_matrix{$rating_index};
				$count{$key}++;
			}
			else {
				$sum{$key} = $invariant_matrix{$rating_index};
				$count{$key} = 1;
			}
		}
		my %tmp2 = ();
		foreach my $key (keys %sum) {
			my ($i, $h) = unpack($PACK_TEMPLATE, $key);
			$tmp2{$key} = $sum{$key} / $count{$key}	+ $a_cc_ref->[$h];
		}
		# minimize error
		for (my $i = 0; $i < $m; $i++) {
			my @candidate_errors;
			for (my $g = 0; $g < $k; $g++) {
				my $sum = 0;
				foreach my $rating_index (keys %{$rows[$i]}) {
					my ($row, $col) = unpack($PACK_TEMPLATE, $rating_index);
					my $key = pack($PACK_TEMPLATE, $i, $item_clustering[$col]);
					my $local_sum =	$tmp2{$key}
						- $a_coc_ref->[$g][$item_clustering[$col]]
						+ $a_rc_ref->[$g];
					$sum = $sum + $local_sum * $local_sum;
				}
				$candidate_errors[$g] = $sum;
			}

			#print STDERR "Candidate values (rows): @candidate_errors " if $debug > 2;
			my $cluster = array_get_minimum_index({
				default_index => $user_clustering[$i],
				array_ref     => \@candidate_errors,
			});
			#print STDERR "Picked $cluster\n" if $debug > 2;
			if ($cluster != $user_clustering[$i]) {
				$modified++;
			}

			$approx_error = $approx_error + $candidate_errors[$cluster];
			#print STDERR "e + $candidate_errors[$cluster] = $approx_error\n" if $debug > 1;
			$new_user_clustering[$i] = $cluster;
		}
		print STDERR "a: $approx_error, " if $verbose;
		@user_clustering = @new_user_clustering;
		#print STDERR "User clustering in step $counter: @user_clustering\n" if $debug;

		if ($show_exact_error) {
			my $exact_error = compute_exact_error({
				known_ratings        => $ratings,
				row_clustering_ref   => \@user_clustering,
				col_clustering_ref   => \@item_clustering,
				invariant_matrix_ref => \%invariant_matrix,
				row_averages_ref     => \@a_r,
				col_averages_ref     => \@a_c,
				k                    => $k,
				l                    => $l,
			});
			print STDERR "e: $exact_error, " if $verbose;
		}

		

		# 2c. Update column cluster assignments
		($a_rc_ref, $a_cc_ref, $a_coc_ref) = compute_cluster_averages({
			known_ratings      => $ratings,
			row_clustering_ref => \@user_clustering,
			col_clustering_ref => \@item_clustering,
			k                  => $k,
			l	           => $l,
		});

		my @new_item_clustering;
		$approx_error = 0;
		# Compute invariant matrix
		%sum = ();
		%count = ();
		foreach my $rating_index (@rating_indices) {
			my ($row, $col) = unpack($PACK_TEMPLATE, $rating_index);
			my $key = pack($PACK_TEMPLATE, $user_clustering[$row], $col);
			if (exists $sum{$key}) {
				$sum{$key} = $sum{$key} + $invariant_matrix{$rating_index};
				$count{$key}++;
			}
			else {
				$sum{$key} = $invariant_matrix{$rating_index};
				$count{$key} = 1;
			}
		}
		my %tmp3 = ();
		foreach my $key (keys %sum) {
			my ($g, $j) = unpack($PACK_TEMPLATE, $key);
			$tmp3{$key} = $sum{$key} / $count{$key}	+ $a_rc_ref->[$g];
		}
		# minimize error
		for (my $j = 0; $j < $n; $j++) {
			my @candidate_errors;
			for (my $h = 0; $h < $l; $h++) {
				my $sum = 0;
				foreach my $rating_index (keys %{$cols[$j]}) {
					my ($row, $col) = unpack($PACK_TEMPLATE, $rating_index);
					my $key = pack($PACK_TEMPLATE, $user_clustering[$row], $j);
					my $local_sum =	$tmp3{$key}
						- $a_coc_ref->[$user_clustering[$row]][$h]
						+ $a_cc_ref->[$h];
					$sum = $sum + $local_sum * $local_sum;
				}
				$candidate_errors[$h] = $sum;
			}
			#print STDERR "Candidate values (columns): @candidate_errors " if $debug > 2;
			my $cluster = array_get_minimum_index({
				default_index => $item_clustering[$j],
				array_ref     => \@candidate_errors
			});
			#print STDERR "Picked $cluster\n" if $debug > 2;
			if ($cluster != $item_clustering[$j]) {
				$modified++;
			}

			$approx_error = $approx_error + $candidate_errors[$cluster];
			#print STDERR "e + $candidate_errors[$cluster] = $approx_error\n" if $debug > 1;
			$new_item_clustering[$j] = $cluster;
		}
		print STDERR "a: $approx_error " if $verbose;
		@item_clustering = @new_item_clustering;
		#print STDERR "Item clustering in step $counter: @item_clustering\n" if $debug;

		$counter++;

		if ($show_exact_error) {
			my $exact_error = compute_exact_error({
				known_ratings           => $ratings,
				row_clustering_ref      => \@user_clustering,
				col_clustering_ref      => \@item_clustering,
				invariant_matrix_ref    => \%invariant_matrix,
				row_averages_ref        => \@a_r,
				col_averages_ref        => \@a_c,
				k                       => $k,
				l                       => $l,
			});
			print STDERR "e: $exact_error" if $verbose;
		}
	
		print STDERR "\n" if $verbose;
	}
	print STDERR "Clustering finished after $counter iterations.\n" if $verbose;
	if ($modified == 0) {
		print STDERR "Reason: No cluster assignments modified in last iteration.\n" if $verbose;
	}
	elsif ($counter == $max_iterations) {
		print STDERR "Reason: Maximum number of iterations reached.\n" if $verbose;
	}
	else {
		print STDERR "Umknown.\n" if $verbose;
	}

	my ($a_rc_ref, $a_cc_ref, $a_coc_ref) = compute_cluster_averages({
		known_ratings      => $ratings,
		row_clustering_ref => \@user_clustering,
		col_clustering_ref => \@item_clustering,
		k                  => $k,
		l	           => $l,
	});
	my $result_ref = {
		row_clustering_ref      => \@user_clustering,
		col_clustering_ref      => \@item_clustering,
		rowcluster_averages_ref => $a_rc_ref,
		colcluster_averages_ref => $a_cc_ref,
		cocluster_averages_ref  => $a_coc_ref,
		row_averages_ref        => \@a_r,
		col_averages_ref        => \@a_c,
		iterations              => $counter,
	};

	return $result_ref;
}


# Beware, this is rather costly to compute!
sub compute_exact_error {
	my ($arg_ref) = @_;

	my $known_ratings        = $arg_ref->{known_ratings};
	my $row_clustering_ref   = $arg_ref->{row_clustering_ref};
	my $col_clustering_ref   = $arg_ref->{col_clustering_ref};
	my $invariant_matrix_ref = $arg_ref->{invariant_matrix_ref};
	my $a_r_ref              = $arg_ref->{row_averages_ref};
	my $a_c_ref              = $arg_ref->{col_averages_ref};
	my $a_rc_ref;
	my $a_cc_ref;
	my $a_coc_ref;

	if (exists $arg_ref->{rowcluster_averages_ref}) {
		$a_rc_ref  = $arg_ref->{rowcluster_averages_ref};
		$a_cc_ref  = $arg_ref->{colcluster_averages_ref};
		$a_coc_ref = $arg_ref->{cocluster_averages_ref};
	}
	else {
		my $rows_ref       = $known_ratings->get_rows;
		my $cols_ref       = $known_ratings->get_cols;
		my $k              = $arg_ref->{k};
		my $l              = $arg_ref->{l};
		my $global_average = $arg_ref->{global_average};

		($a_rc_ref, $a_cc_ref, $a_coc_ref) = compute_cluster_averages({
			known_ratings      => $known_ratings,
			row_clustering_ref => $row_clustering_ref,
			col_clustering_ref => $col_clustering_ref,
			k                  => $k,
			l	           => $l,
		});

	}

	#my $tmp2_ref = compute_tmp2_ref(...)
	#my $tmp3_ref = compute_tmp3_ref(...)

	my $error = 0;
	foreach my $key (keys %{$known_ratings->{matrix_ref}}) {
		my ($row, $col) = unpack($PACK_TEMPLATE, $key);
		my $g = $row_clustering_ref->[$row];
		my $h = $col_clustering_ref->[$col];

		#print "($row, $col)\n";
		my $local_error = $invariant_matrix_ref->{$key}
				+ $a_rc_ref->[$g]
				+ $a_cc_ref->[$h]
				- $a_coc_ref->[$g][$h];
		#print "$local_error = $invariant_matrix_ref->{$key} + $a_rc_ref->[$g] + $a_cc_ref->[$h] - $a_coc_ref->[$g][$h]\n";

		my $squared_local_error = $local_error * $local_error;
		$error = $error + $squared_local_error;
	}

	return $error;
}

1;
