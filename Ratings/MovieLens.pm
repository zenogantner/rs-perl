use strict;
use warnings;

package Ratings::MovieLens;

use Ratings::Sparse;
use Ratings::Scale;

sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
		verbose  => exists $arg_ref->{verbose}  ? $arg_ref->{verbose}  : 0,
		filename => exists $arg_ref->{filename} ? $arg_ref->{filename} : '-',
		binary   => exists $arg_ref->{binary}   ? $arg_ref->{binary}   : 0,
	};

	return bless $self, $class;
}


sub get_ratings {
	my ($self, $arg_ref) = @_;

	my $number_of_users  = 10_000;
	my $number_of_movies = 10_000;

	my $ratings_limit = 0;
	if (defined $arg_ref) {
		$ratings_limit = exists $arg_ref->{ratings_limit} ? $arg_ref->{ratings_limit} : 0;
	}

	print STDERR "Reading in data ... " if $self->{verbose};
	my $ratings_counter = 0;
	
	open FILE, $self->{filename}
		or die "Could not open '$self->{filename}': $!\n"; 

	my %ratings = ();
	my $user_max_id  = 0;
	my $movie_max_id = 0;

	LINE:
	while (<FILE>) {
		if ($ratings_limit != 0) {
			last LINE if $ratings_counter > $ratings_limit;
		}

		my $line = $_;
		chomp $line;

		if ($line =~ m/^(\d+)\t(\d+)\t([1-5])(?:\t(\d+))?$/) {
			my $user_id  = $1 - 1;	# subtract one because movielens IDs are 1-based
			my $movie_id = $2 - 1;
			my $rating   = $3;

			if (($user_id < $number_of_users) && ($movie_id < $number_of_movies)) {
				$ratings{pack($PACK_TEMPLATE, $user_id, $movie_id)} = $rating;
				$ratings_counter++;
			}

				if ($user_id > $user_max_id) {
					$user_max_id = $user_id;
				}
			#	if ($user_id < $user_min) {
			#		$user_min = $user_id;
			#	}
				if ($movie_id > $movie_max_id) {
					$movie_max_id = $movie_id;
				}
			#	if ($movie_id < $movie_min) {
			#		$movie_min = $movie_id;
			#	}

		}
		else {
			print "Failed to parse line '$line'\n";
		}
	}
	close FILE;
	print STDERR "done.\n" if $self->{verbose};
	print STDERR "Read $ratings_counter ratings.\n" if $self->{verbose};

	my $scale = Ratings::Scale->new({
		number_of_users => $user_max_id + 1,
		number_of_items => $movie_max_id + 1,
		min             => 1,
		max             => 5,
	});

	my $ratings = Ratings::Sparse->new({
		matrix_ref => \%ratings,
		scale      => $scale,
	});
	return $ratings;
}

1;
