use strict;
use warnings;
use encoding 'utf8'; # ä

use Evaluation::Ranking qw( create_orders_for_user );
use Ratings::Sparse;
use Ratings::Scale;
use Test::More qw( no_plan);
use Test::Multi;

my $verbose = 0;

my %actual_ratings_matrix = (
	pack($PACK_TEMPLATE, 0, 0) => 5,
	pack($PACK_TEMPLATE, 0, 1) => 5,
	pack($PACK_TEMPLATE, 0, 2) => 5,
	pack($PACK_TEMPLATE, 0, 3) => 5,
	pack($PACK_TEMPLATE, 0, 4) => 1,
	pack($PACK_TEMPLATE, 0, 5) => 1,
);

my %predicted_ratings_matrix1 = (
	pack($PACK_TEMPLATE, 0, 0) => 4.6,
	pack($PACK_TEMPLATE, 0, 1) => 4.8,
	pack($PACK_TEMPLATE, 0, 2) => 5,
	pack($PACK_TEMPLATE, 0, 3) => 4.7,
	pack($PACK_TEMPLATE, 0, 4) => 1.1,
	pack($PACK_TEMPLATE, 0, 5) => 1.2,
);

my $expected1_ref = {
	minrank1_ref     => {0 => 1, 1 => 1, 2 => 1, 3 => 1, 4 => 5, 5 => 5},
	maxrank1_ref     => {0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 6, 5 => 6},
	rank2_ref        => {0 => 4, 1 => 2, 2 => 1, 3 => 3, 4 => 6, 5 => 5},
	rated_items_ref  => [2, 1, 3, 0, 5, 4],
	ignore_threshold => 4,
};

my %predicted_ratings_matrix3 = (
	pack($PACK_TEMPLATE, 0, 0) => 1.0,
	pack($PACK_TEMPLATE, 0, 1) => 4.8,
	pack($PACK_TEMPLATE, 0, 2) => 5,
	pack($PACK_TEMPLATE, 0, 3) => 4.7,
	pack($PACK_TEMPLATE, 0, 4) => 1.1,
	pack($PACK_TEMPLATE, 0, 5) => 1.2,
);



sub predict_using_matrix {
	my ($matrix_ref, $user_id, $item_id) = @_;

	return $matrix_ref->{pack($PACK_TEMPLATE, $user_id, $item_id)};
}


my $scale       = Ratings::Scale->new({
	number_of_users => 1,
	number_of_items => 6,
});


my $predict1_ref = sub { return predict_using_matrix(\%predicted_ratings_matrix1, @_); };
my $result_ref = Evaluation::Ranking::create_orders_for_user({
	user_ratings_ref => \%actual_ratings_matrix,
	predict_ref      => $predict1_ref,
	scale            => $scale,
	user_id          => 0,
});
is_deeply($result_ref, $expected1_ref);


my $predict2_ref = sub { return predict_using_matrix(\%predicted_ratings_matrix1, @_); };
my $result2_ref = Evaluation::Ranking::compute_rank_error({
	test_ratings     => Ratings::Sparse->new({
				matrix_ref => \%actual_ratings_matrix,
				scale      => $scale,
			    }),
        predict_ref      => $predict2_ref,
        verbose          => $verbose,
});
is_deeply($result2_ref, {rank_error             => 0, squared_rank_error             => 0,
			 interesting_rank_error => 0, interesting_squared_rank_error => 0,
                         normalized_rank_error  => 0, normalized_squared_rank_error  => 0});


my $predict3_ref = sub { return predict_using_matrix(\%predicted_ratings_matrix3, @_); };
my $result3_ref = Evaluation::Ranking::compute_rank_error({
	test_ratings     => Ratings::Sparse->new({
				matrix_ref => \%actual_ratings_matrix,
				scale      => $scale,
			    }),
        predict_ref      => $predict3_ref,
        verbose          => $verbose,
});
is_deeply($result3_ref, {rank_error             => 3,       squared_rank_error             => 5,
			 interesting_rank_error => 3,       interesting_squared_rank_error => 5,  # TODO: example for that
                         normalized_rank_error  => 3/(5*6), normalized_squared_rank_error  => 1/(6*6)});


