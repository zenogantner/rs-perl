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

package Predictor::LinearCombination;

sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
		verbose    => 0,
		# predictor1
		# predictor2
		# lambda
		%$arg_ref
	};

	print STDERR "Creating object of type Predictor::LinearCombination.\n" if $self->{verbose};
	my @keys = keys %$self;
	print STDERR "Keys: @keys\n" if $self->{verbose};

	return bless $self, $class;
}


sub predict {
	my ($self, $user_id, $item_id) = @_;

	# this is MovieLens-specific
	my $prediction1 = $self->{predictor1}->predict($user_id, $item_id);
	my $prediction2 = $self->{predictor2}->predict($user_id, $item_id);
	my $result = $prediction1 * $self->{lambda} + $prediction2 * (1 - $self->{lambda});

	return $result;
}


sub description {
	my ($self) = @_;

	return "linear combination of $self->{predictor1}->{description} and $self->{predictor2}->{description}, lambda=$self->{lambda}";
}

1;
