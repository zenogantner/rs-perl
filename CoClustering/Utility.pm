# variable naming partly according to the paper/technical report by Thomas George and Srujana Merugu

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

package CoClustering::Utility;
use base 'Exporter';
our @EXPORT = qw(
	compute_global_average_complete
	create_clustering create_random_clustering
	array_get_minimum_index array_get_maximum_value
	compute_cluster_averages
);

use Ratings::Sparse;

# returns an array
sub create_clustering {
	my ($arg_ref) = @_;

	my $number_of_objects  = $arg_ref->{number_of_objects};
	my $number_of_clusters = $arg_ref->{number_of_clusters};
	my $random             = exists $arg_ref->{random} ? $arg_ref->{random} : 0;
	
	if ($number_of_objects < $number_of_clusters) {
		die "Number of clusters cannot be greater than number of objects.\n";
	}

	if ($random) {
		return create_random_clustering(@_);
	}
	else {
		my @clustering;  # mapping objects -> clusters

		# established ordered, deterministic cluster assignment:
		for my $i (0 .. ($number_of_objects - 1)) {
			$clustering[$i] = $i % $number_of_clusters;
		}
		return @clustering;
	}
}

# returns an array
sub create_random_clustering {
	my ($arg_ref) = @_;

	my $number_of_objects  = $arg_ref->{number_of_objects};
	my $number_of_clusters = $arg_ref->{number_of_clusters};

	my @clustering;  # mapping objects -> clusters

	# establish random cluster assignment
	for my $i (0 .. ($number_of_objects - 1)) {
		$clustering[$i] = int(rand ($number_of_clusters));
	}

	return @clustering;
}

sub compute_cluster_averages {
	my ($arg_ref) = @_;

	my $known_ratings      = $arg_ref->{known_ratings};
	my $row_clustering_ref = $arg_ref->{row_clustering_ref};
	my $col_clustering_ref = $arg_ref->{col_clustering_ref};
	my $k                  = $arg_ref->{k};
	my $l                  = $arg_ref->{l};

	my $global_average     = $known_ratings->{global_average};
	my $m                  = $known_ratings->{number_of_rows};
	my $n                  = $known_ratings->{number_of_cols};

	# add first, the average arrays are used to store the sums
	my @sum_rc = map { $_ = 0 } (1 .. $k);
	my @sum_cc = map { $_ = 0 } (1 .. $l);
	my @counter_rc = map { $_ = 0 } (1 .. $k);
	my @counter_cc = map { $_ = 0 } (1 .. $l);
	my @sum_coc;
	my @counter_coc;
	for (my $g = 0; $g < $k; $g++) {
		$sum_coc[$g]     = [ map { $_ = 0 } (1 .. $l) ];
		$counter_coc[$g] = [ map { $_ = 0 } (1 .. $l) ];
	}

	foreach my $key (keys %{$known_ratings->{matrix_ref}}) {
		my ($row, $col) = unpack($PACK_TEMPLATE, $key);
		my $rating = $known_ratings->{matrix_ref}->{$key};

		# determine clusters
		my $row_cluster = $row_clustering_ref->[$row];
		my $col_cluster = $col_clustering_ref->[$col];

		# add to sums
		$sum_rc[$row_cluster]                = $sum_rc[$row_cluster] + $rating;
		$sum_cc[$col_cluster]                = $sum_cc[$col_cluster] + $rating;
		$sum_coc[$row_cluster][$col_cluster] = $sum_coc[$row_cluster][$col_cluster] + $rating;

		# iterate counters
		$counter_rc[$row_cluster]++;
		$counter_cc[$col_cluster]++;
		$counter_coc[$row_cluster][$col_cluster]++;
	}

	# compute final averages
	#  for co-clusters
	my @a_coc;
	for (my $g = 0; $g < $k; $g++) {
		for (my $h = 0; $h < $l; $h++) {
			$a_coc[$g][$h] = $counter_coc[$g][$h] != 0
					? $sum_coc[$g][$h] / $counter_coc[$g][$h]
					: $global_average;
		}
	}
	#  for row clusters
	my @a_rc;
	for (my $g = 0; $g < $k; $g++) {
		$a_rc[$g] = $counter_rc[$g] != 0
			   ? $sum_rc[$g] / $counter_rc[$g]
			   : $global_average;
	}
	# column clusters
	my @a_cc;
	for (my $h = 0; $h < $l; $h++) {
		$a_cc[$h] = $counter_cc[$h] != 0
			   ? $sum_cc[$h] / $counter_cc[$h]
			   : $global_average;
	}		

	return (\@a_rc, \@a_cc, \@a_coc)
}

# array must have at least length 1
sub array_get_minimum_index {
	my ($arg_ref) = @_;

	my $default_index = $arg_ref->{default_index};
	my $array_ref     = $arg_ref->{array_ref};

	my $length = scalar @$array_ref;
	my $minimum = $array_ref->[$default_index];
	my $minimum_index = $default_index;
	for (my $i = 0; $i < $length; $i++) {		
		if ($array_ref->[$i] < $minimum) {
			$minimum = $array_ref->[$i];
			$minimum_index = $i;
		}
	}
	return $minimum_index;
}

sub array_get_maximum_value (@) {
	my (@array) = @_;

	my $length = @array;
	my $maximum = $array[0];
	for (my $i = 1; $i < $length; $i++) {		
		if ($array[$i] > $maximum) {
			$maximum = $array[$i];
		}
	}
	return $maximum;
}


1;
