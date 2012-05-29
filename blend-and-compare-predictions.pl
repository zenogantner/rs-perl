#!/usr/bin/perl

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
use utf8;
use English qw( -no_match_vars );
use Getopt::Long;
use Carp;
use Regexp::Common qw /number/;

GetOptions(
    'help'     => \(my $help = 0),
    'verbose+' => \(my $verbose = 0),
) or usage(-1);

if ($help) {
    usage(0);
}

my @files = @ARGV;

if (scalar @files != 3) {
    croak 'Please provide two files with predictions to combine, plus the reference file';
}


my %predictions = ();
print STDERR "Reading in predictions ... " if $verbose;
foreach my $file (@files) {
    $predictions{$file} = {};
    
    open my $FILE, '<', $file
        or croak "Can't open '$file' for reading: $ERRNO";

	while (<$FILE>) {
		my $line = $_;
		chomp $line;

		if ($line =~ m/^(\d+)\t(\d+)\t($RE{num}{real})(?:\t(\d+))?$/) { # TODO: nicer regexp
			my $user_id  = $1;
			my $movie_id = $2;
			my $rating   = $3;
			
			if ($file =~ m{u\d\.test$}xms) { # UGLY HACK: adjust for MovieLens files TODO: get rid of that!
			    $user_id--;
			    $movie_id--;
			}
			
			$predictions{$file}->{"$user_id\t$movie_id"} = $rating;
		}
		else {
		    carp "Could not parse line '$line'";
		}
	}
	close $FILE;
}
print STDERR "done\n" if $verbose;

print STDERR "Verifying keys ... " if $verbose; # TODO: maybe there is a CPAN module for that?
my @reference_keys = keys %{$predictions{$files[0]}};
my $number_of_reference_keys = scalar @reference_keys;
foreach my $file (@files) {
    my $number_of_keys = scalar keys %{$predictions{$file}};
    if ($number_of_keys != $number_of_reference_keys ) {
        croak "Number of ratings in '$file' ($number_of_keys) does not match number of ratings in '$files[0]' ($number_of_reference_keys)";
    }
    
    foreach my $key (@reference_keys) {
        if (!exists $predictions{$file}->{$key}) {
            croak "Rating '$key' does not exist in file '$file'";
        }
    }
}
print STDERR "done\n" if $verbose;


my $reference_file = $files[0];

print "# lambda\tMAE\tRMSE\n";



for (my $lambda = 0; $lambda <= 1.01; $lambda += 0.025) {
    print "$lambda\t";
    
    my $absolute_difference_sum = 0;
    my $squared_difference_sum  = 0;

    foreach my $key (@reference_keys) {

        my $combined_rating =  $predictions{$files[1]}->{$key} * $lambda
                             + $predictions{$files[2]}->{$key} * (1 - $lambda);

        my $difference = $predictions{$reference_file}->{$key} - $combined_rating;
        $absolute_difference_sum += abs($difference);
        $squared_difference_sum  += $difference * $difference;
    }

    my $mae  = $absolute_difference_sum / $number_of_reference_keys;
    my $rmse = sqrt($squared_difference_sum / $number_of_reference_keys);

    printf "%.4f\t%.4f\n", $mae, $rmse;
}


sub usage {
    my ($exit_code) = @_;
    
    print << 'END';
Blend two different predictions, and evaluate with different lambda values (MovieLens format).
(c) 2008 Zeno Gantner
        
usage: ./blend-predictions.pl [OPTIONS] file1 file2 ...

  general options:
    --help         display this usage information and exit
    --verbose      increment verbosity level by one
END

    exit $exit_code;
}
