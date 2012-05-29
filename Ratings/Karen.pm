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

# Module for reading binary matrices used by Karen Tso.

package Ratings::Karen;
use Ratings::Sparse;
use Ratings::Scale;

sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
		verbose  => exists $arg_ref->{verbose}  ? $arg_ref->{verbose}  : 0,
		filename => exists $arg_ref->{filename} ? $arg_ref->{filename} : '-',
	};

	return bless $self, $class;
}


sub get_ratings {
	my ($self, $arg_ref) = @_;

	my %ratings = ();
	my $user_id = 0;
	my $item_id;

	print STDERR "Reading in data ... " if $self->{verbose};
	open FILE, $self->{filename}
		or die "Could not open '$self->{filename}': $!\n"; 
	LINE: while (<FILE>) {
		my $line = $_;
		chomp $line;

		my @user_ratings = split /\s/, $line;
		$item_id = 0;
		foreach my $rating (@user_ratings) {
			if ($rating eq '1.0') {
				$ratings{pack($PACK_TEMPLATE, $user_id, $item_id)} = $rating;
			}
			$item_id++;
		}
		$user_id++;
	}
	close FILE;
	print STDERR "done.\n" if $self->{verbose};

	my $number_of_ratings = scalar(keys %ratings);
	print STDERR "Read $number_of_ratings ratings.\n" if $self->{verbose};

	my $scale = Ratings::Scale->new({
		number_of_users => $user_id,
		number_of_items => $item_id,
		binary          => 1,
	});

	my $ratings = Ratings::Sparse->new({
		matrix_ref => \%ratings,
		scale      => $scale,
	});
	return $ratings;
}


1;
