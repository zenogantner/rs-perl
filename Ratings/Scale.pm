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

package Ratings::Scale;

sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
		verbose => 0,
		min     => 1,
		max     => 5,
		binary  => 0,
		# number_of_users
		# number_of_items
		%$arg_ref
	};

	if ($self->{binary}) {
		$self->{min} = 0;
		$self->{max} = 1;
	}

	print STDERR "Creating object of type Ratings::Scale.\n" if $self->{verbose};

	return bless $self, $class;
}


sub min {
	my ($self) = @_;

	return $self->{min};
}


sub max {
	my ($self) = @_;

	return $self->{max};
}


sub binary {
	my ($self) = @_;

	return $self->{binary} ? 1 : 0;
}


sub number_of_users {
	my ($self) = @_;

	return $self->{number_of_users};
}


sub number_of_items {
	my ($self) = @_;

	return $self->{number_of_items};
}

1;
