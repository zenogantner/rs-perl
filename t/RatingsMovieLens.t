use strict;
use warnings;
use encoding 'utf8'; # ä

use Ratings::MovieLens;
use CoClustering::Optimized;
use Test::More qw( no_plan);
#use Test::Multi;
use IO::File;
use POSIX qw(tmpnam);


my %ratings_matrix = (
	pack($PACK_TEMPLATE, 0, 0) => 1,
	pack($PACK_TEMPLATE, 1, 1) => 2,
	pack($PACK_TEMPLATE, 2, 2) => 3,
	pack($PACK_TEMPLATE, 3, 3) => 4,
	pack($PACK_TEMPLATE, 4, 4) => 5,
);
my $ratings = "1\t1\t1\n2\t2\t2\n3\t3\t3\n4\t4\t4\n5\t5\t5\n";
my $ratings_w_timestamps = "1\t1\t1\t12341234\n2\t2\t2\t12341235\n3\t3\t3\t12341236\n4\t4\t4\t12341237\n5\t5\t5\t12341238\n";

my $file1 = write_string_to_tmpfile($ratings);
my $file2 = write_string_to_tmpfile($ratings_w_timestamps);

my $ratings_reader1 = Ratings::MovieLens->new({filename => $file1});
my $ratings_reader2 = Ratings::MovieLens->new({filename => $file2});

my @result_list1 = $ratings_reader1->get_ratings();
my @result_list2 = $ratings_reader2->get_ratings();

is_deeply( [@result_list1], [\%ratings_matrix, 5, 5], 'w/o timestamps');
is_deeply( [@result_list2], [\%ratings_matrix, 5, 5], 'with timestamps');


#foreach my $key (keys %$ratings_ref1) {
#	my ($user, $movie) = unpack($PACK_TEMPLATE, $key);
#	print "r1($user, $movie) = $ratings_ref1->{$key}\n";
#}

sub write_string_to_tmpfile {
	my ($string) = @_;

	my $filename;
	my $fh;
	# try new temporary filenames until we get one that didn't already exist
	do { $filename = tmpnam() }
	    until $fh = IO::File->new($filename, O_RDWR|O_CREAT|O_EXCL);

	# install atexit-style handler so that when we exit or die,
	# we automatically delete this temporary file
	END { unlink($filename) or die "Couldn't unlink $filename : $!" }

	print $fh $string;
	close $fh;

	return $filename;
}
