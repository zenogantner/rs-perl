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

package Predictor::JointWeighting;

sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
		verbose    => 0,
		# predictor1
		# predictor2
		# lambda
		%$arg_ref
	};

	print STDERR "Creating object of type Predictor::JointWeighting.\n" if $self->{verbose};
	my @keys = keys %$self;
	print STDERR "Keys: @keys\n" if $self->{verbose};

	return bless $self, $class;
}


sub predict {
	my ($self, $user_id, $item_id) = @_;

	my $part1_result = $self->{predictor1}->predict($user_id, $item_id);
	my $part2_result = $self->{predictor2}->predict($user_id, $item_id);

	if ($part1_result < 1 || $part2_result < 1) {
		die "Predictor::JointWeighting->predict: Values cannot be < 1: $part1_result, $part2_result; "
                  . "u $user_id, i $item_id\n";
	}
	if ($part1_result > 5 || $part2_result > 5) {
		die "Predictor::JointWeighting->predict: Values cannot be > 5: $part1_result, $part2_result; "
                  . "u $user_id, i $item_id\n";
	}

	$part1_result = $part1_result ** $self->{lambda};
	$part2_result = $part2_result ** (1 - $self->{lambda});

	return $part1_result * $part2_result;
}


sub description {
	my ($self) = @_;

	return "linear combination of $self->{predictor1}->{description} and $self->{predictor2}->{description}, lambda=$self->{lambda}";
}

1;
