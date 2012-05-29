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

package Ratings::Random;
use base 'Exporter';
our @EXPORT_OK = qw{ create_matrix };


sub create_matrix($$$$$) {
	my ($number_of_users, $number_of_items, $density, $scale_from, $scale_to) = @_;

	my $verbose = 1;

	my @confidence;
	my @rating;

	print STDERR "Creating ratings and confidence matrix ... " if $verbose;
	# random confidence matrix:
	for (my $i = 0; $i < $number_of_users; $i++) {
		my @tmp;
		for (my $j = 0; $j < $number_of_items; $j++) {
			my $random_number = int(rand 1 / $density) + 1;
			if ($random_number == int (1 / $density) ) {
				$tmp[$j] = 1;
			}
			else {
				$tmp[$j] = 0;
			}
		}
		$confidence[$i] = [ @tmp ];
		#	print "@tmp \n";
	}
	# random ratings matrix:
	for (my $i = 0; $i < $number_of_users; $i++) {
		my @tmp;
		for (my $j = 0; $j < $number_of_items; $j++) {
			if ($confidence[$i][$j] == 1) {
				$tmp[$j] = int(rand ($scale_to - $scale_from + 1)) + $scale_from;
			} else {
				$tmp[$j] = 0;
			}
		}
		$rating[$i] = [ @tmp ];
	#	print "@tmp \n";
	}
	print STDERR "done.\n" if $verbose;

	return (\@rating, \@confidence);
}

1;
