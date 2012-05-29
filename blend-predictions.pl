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

my @weights = ();

GetOptions(
    'help'     => \(my $help = 0),
    'verbose+' => \(my $verbose = 0),
    'weight=f' => \@weights,            # remark: notation above does not work for lists!
) or usage(-1);

if ($help) {
    usage(0);
}

my @files = @ARGV;
my $number_of_weights = scalar @weights;
my $number_of_files   = scalar @files;

if ($number_of_files < 2) {
    croak 'Please provide at least two files with predictions to combine';
}

if ($number_of_weights != $number_of_files) {
    croak "Number of weights ($number_of_weights) does not match number of files ($number_of_files)";
}

my %predictions = ();
my %weight      = ();
print STDERR "Reading in predictions ... " if $verbose;
foreach my $file (@files) {
    $weight{$file}      = pop @weights;
    $predictions{$file} = {};

    open my $FILE, '<', $file
        or croak "Can't open '$file' for reading: $ERRNO";

	while (<$FILE>) {
		my $line = $_;
		chomp $line;

		if ($line =~ m/^(\d+)\t(\d+)\t($RE{num}{real}$)(?:\t(\d+))?$/) { # TODO: nicer regexp
			my $user_id  = $1;
			my $movie_id = $2;
			my $rating   = $3;

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
# careful: not everything is checked here!
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


foreach my $key (@reference_keys) {
    my $rating_sum = 0;
    my $weight_sum = 0;
    foreach my $file (@files) {
        $rating_sum += $weight{$file} * $predictions{$file}->{$key};
        $weight_sum += $weight{$file};
    }
    my $combined_rating = $rating_sum / $weight_sum;
    print "$key\t$combined_rating\n";
}

sub usage {
    my ($exit_code) = @_;

    print << 'END';
Blend two different predictions (MovieLens format).
(c) 2008 Zeno Gantner

usage: $PROGRAM_NAME [OPTIONS] file1 file2 ...

  general options:
    --help         display this usage information and exit
    --verbose      increment verbosity level by one
    --weight=L
END

    exit $exit_code;
}
