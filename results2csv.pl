#!/usr/bin/perl

# paired t test

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

use Getopt::Long;
use Regexp::Common qw /number/;

my $verbose          = 0;
my $forgiving        = 0;
my $d                = 6; # output accuracy in digits
my $compute_averages = 0;
my @measures         = ();

GetOptions(
	#'help'             => \$help,
	'verbose'           => \$verbose,
	'forgiving'         => \$forgiving,
	'output-accuracy=i' => \$d,
	'compute-averages'  => \$compute_averages,
	'measure=s'         => \@measures,
);


my @result_files = @ARGV;


foreach my $filename (@result_files) {
	my $line_counter       = 0;
	my %sample_results     = ();
	my %sample_results_sum = ();
	my $method_string;

	open FILE, $filename
		or die "Could not open '$filename': $!\n"; 

	LINE:
	while (<FILE>) {

		next LINE if /^\s*$/;

		my $line = $_;
		chomp $line;

		if ($line =~ m/^'(.+)'(.*);(.+)$/) {
			my $method            = $1;
			my $method_parameters = $2;
			my $key_value_pairs   = $3;

			my $sample_results_ref = extract_values($key_value_pairs); # TODO: this name is very confusing, think about a better one
			foreach my $measure (keys %$sample_results_ref) {
				if (exists $sample_results{$measure}) {
					push @{$sample_results{$measure}}, $sample_results_ref->{$measure};
					$sample_results_sum{$measure} = $sample_results_sum{$measure} + $sample_results_ref->{$measure};
				}
				else {
					$sample_results{$measure}     = [$sample_results_ref->{$measure}];
					$sample_results_sum{$measure} = $sample_results_ref->{$measure};
				}
			}
			$method_string = "$method $method_parameters";
		}
		else {
			print STDERR "Failed to parse line '$line'\n";
			if (!$forgiving) {
				die "Abort. Please fix this.\n";
			}
		}
	}

	# output
	print "$filename, ";
	print "$method_string";
	my @output_measures = ();
	if (scalar(@measures)) {
		# check whether the measures given by the user were indeed in the result files
		foreach my $measure (@measures) {
			if (exists $sample_results{$measure}) {
				push @output_measures, $measure;			
			}
			else {
				print STDERR "Warning: Measure '$measure' was not found in the result file(s).\n";
			}
		}
		@output_measures = sort(@output_measures);
	}
	else {
		@output_measures = sort(keys %sample_results);
	}
	if ($compute_averages) {
		foreach  my $measure (@output_measures) {
			print ",\t$measure, ";
			print ($sample_results_sum{$measure} / @{$sample_results{$measure}});
		}
	}
	else {
		foreach  my $measure (@output_measures) {
			print ",\t$measure, ";
			print join(', ', @{$sample_results{$measure}});
		}
	}
	print "\n";
}


print "\n";

sub extract_values {
	my ($string) = @_;

	my %hash = ();

	while ($string =~ s/(\w*)=($RE{num}{real})//) {
		my $key   = $1;
		my $value = $2;

		$hash{$key} = $value;
	}

	return \%hash;
}


