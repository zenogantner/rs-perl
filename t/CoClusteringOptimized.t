use strict;
use warnings;
use encoding 'utf8'; # ä

use CoClustering::Optimized qw( $PACK_TEMPLATE compute_exact_error);
use Test::More qw( no_plan);
use Test::Multi;

#use File::Slurp;

# a non-sparse 3x3 matrix
my %ratings1 = (
	pack($PACK_TEMPLATE, 0, 0) => 1,  pack($PACK_TEMPLATE, 0, 1) => 1,  pack($PACK_TEMPLATE, 0, 2) => 1,
	pack($PACK_TEMPLATE, 1, 0) => 2,  pack($PACK_TEMPLATE, 1, 1) => 2,  pack($PACK_TEMPLATE, 1, 2) => 2,
	pack($PACK_TEMPLATE, 2, 0) => 3,  pack($PACK_TEMPLATE, 2, 1) => 3,  pack($PACK_TEMPLATE, 2, 2) => 3,
);

my %inv1 = (
	pack($PACK_TEMPLATE, 0, 0) => 1 - 1 - 2,  pack($PACK_TEMPLATE, 0, 1) => 1 - 1 - 2,  pack($PACK_TEMPLATE, 0, 2) => 1 - 1 - 2,
	pack($PACK_TEMPLATE, 1, 0) => 2 - 2 - 2,  pack($PACK_TEMPLATE, 1, 1) => 2 - 2 - 2,  pack($PACK_TEMPLATE, 1, 2) => 2 - 2 - 2,
	pack($PACK_TEMPLATE, 2, 0) => 3 - 3 - 2,  pack($PACK_TEMPLATE, 2, 1) => 3 - 3 - 2,  pack($PACK_TEMPLATE, 2, 2) => 3 - 3 - 2,
);

# a sparse matrix

#my @global_average_test = (
#	\%ratings1 => 2,
#);

my @exact_error_test = (
	{
		matrix_ref           => \%ratings1,
		row_clustering_ref   => [ 0, 1, 2],
		col_clustering_ref   => [ 0, 1, 2],
		invariant_matrix_ref => \%inv1,
		row_averages_ref     => [ 1, 2, 3],
		col_averages_ref     => [ 2, 2, 2],
		rowcluster_averages_ref => [ 1, 2, 3],
		colcluster_averages_ref => [ 2, 2, 2],
		cocluster_averages_ref  => [ [ 1, 1, 1],
					     [ 2, 2, 2],
					     [ 3, 3, 3] ]
	} => 0
);

#my $global_average_ref = sub {
#	my ($ratings_ref) = @_; 
#	global_average(
#		CoClustering::OptimizedWithoutInvariants->new(ratings_ref => $ratings_ref)
#	);
#};

test_one_arg(\@exact_error_test, \&compute_exact_error, 'compute_exact_error');

# Test the remove_parantheses method
#test_four_arg(\@parantheses_test, \&remove_parantheses, 'remove_parantheses');


