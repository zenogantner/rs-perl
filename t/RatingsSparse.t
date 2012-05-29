use strict;
use warnings;
use encoding 'utf8'; # ä

use Ratings::Sparse;
use CoClustering::Utility; # TODO: get rid of this
use Test::More qw( no_plan);
use Test::Multi;

# a non-sparse 3x3 matrix
my @rating1 = (
	pack($PACK_TEMPLATE, 0, 0) => 1,  pack($PACK_TEMPLATE, 0, 1) => 1,  pack($PACK_TEMPLATE, 0, 2) => 1,
	pack($PACK_TEMPLATE, 1, 0) => 2,  pack($PACK_TEMPLATE, 1, 1) => 2,  pack($PACK_TEMPLATE, 1, 2) => 2,
	pack($PACK_TEMPLATE, 2, 0) => 3,  pack($PACK_TEMPLATE, 2, 1) => 3,  pack($PACK_TEMPLATE, 2, 2) => 3,
);
my %rating1 = @rating1;

# a sparser 3x3 matrix
my %rating2 = (
	pack($PACK_TEMPLATE, 0, 2) => 1,
	pack($PACK_TEMPLATE, 1, 1) => 2,
);


# Test get_rows and get_cols
is_deeply(
	get_rows({ matrix_ref => \%rating1, number_of_rows => 3 }),
	[{pack($PACK_TEMPLATE, 0, 0) => 1,  pack($PACK_TEMPLATE, 0, 1) => 1,  pack($PACK_TEMPLATE, 0, 2) => 1},
	 {pack($PACK_TEMPLATE, 1, 0) => 2,  pack($PACK_TEMPLATE, 1, 1) => 2,  pack($PACK_TEMPLATE, 1, 2) => 2},
	 {pack($PACK_TEMPLATE, 2, 0) => 3,  pack($PACK_TEMPLATE, 2, 1) => 3,  pack($PACK_TEMPLATE, 2, 2) => 3}]
);
is_deeply(
	get_cols({ matrix_ref => \%rating1, number_of_cols => 3 }),
	[{pack($PACK_TEMPLATE, 0, 0) => 1,  pack($PACK_TEMPLATE, 1, 0) => 2,  pack($PACK_TEMPLATE, 2, 0) => 3},
	 {pack($PACK_TEMPLATE, 0, 1) => 1,  pack($PACK_TEMPLATE, 1, 1) => 2,  pack($PACK_TEMPLATE, 2, 1) => 3},
	 {pack($PACK_TEMPLATE, 0, 2) => 1,  pack($PACK_TEMPLATE, 1, 2) => 2,  pack($PACK_TEMPLATE, 2, 2) => 3}]
);
is_deeply(
	get_rows({ matrix_ref => \%rating2, number_of_rows => 3 }),
	[{pack($PACK_TEMPLATE, 0, 2) => 1},
	 {pack($PACK_TEMPLATE, 1, 1) => 2},
	 {}]
);
is_deeply(
	get_cols({ matrix_ref => \%rating2, number_of_cols => 3 }),
	[{},
	 {pack($PACK_TEMPLATE, 1, 1) => 2},
	 {pack($PACK_TEMPLATE, 0, 2) => 1}]
);

# Test compute_row_average and compute_col_average
is_deeply(
	compute_row_averages({
		matrix_ref     => \%rating1,
		rows_ref       => get_rows({ matrix_ref => \%rating1, number_of_rows => 3 }),
		global_average => compute_average(\%rating1),
	}),
	[1, 2, 3]
);
is_deeply(
	compute_col_averages({
		matrix_ref     => \%rating1,
		cols_ref       => get_cols({ matrix_ref => \%rating1, number_of_cols => 3 }),
		global_average => compute_average(\%rating1),
	}),
	[2, 2, 2]
);
is_deeply(
	compute_row_averages({
		matrix_ref     => \%rating2,
		rows_ref       => get_rows({ matrix_ref => \%rating2, number_of_rows => 3 }),
		global_average => compute_average(\%rating2),
	}),
	[1, 2, compute_average(\%rating2)]
);
is_deeply(
	compute_col_averages({
		matrix_ref     => \%rating2,
		cols_ref       => get_cols({ matrix_ref => \%rating2, number_of_cols => 3 }),
		global_average => compute_average(\%rating2),
	}),
	[compute_average(\%rating2), 2, 1]
);

# Test compute_average
is( compute_average(\%rating1), 2);
is( compute_average(\%rating2), 1.5);
	
