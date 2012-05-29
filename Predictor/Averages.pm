# This predictor can also handle unknown users and items.

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

package Predictor::Averages;

use Carp;

use Ratings::Sparse;
use Ratings::MovieLens;

sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
		verbose => 0,
		type    => 'default',

		%$arg_ref
		# known_ratings | ratings_file
	};

	print STDERR "Creating object of type Predictor::Averages.\n" if $self->{verbose};

    if ($self->{type} eq 'default') {
        $self->{description} = 'average';
    }
    else {
	    $self->{description} = "$self->{type}-average";
    }

	if (exists $self->{ratings_file}) {
		my $ratings_reader = Ratings::MovieLens->new({
			filename => $self->{ratings_file},
			verbose  => $self->{verbose},
		});

		$self->{known_ratings} = $ratings_reader->get_ratings;
	}
	if (! exists $self->{known_ratings}) {
		croak 'No parameter "ratings" or "ratings_file" given';
	}

	$self->{scale} = $self->{known_ratings}->{scale};
	if (exists $self->{scale} && defined $self->{scale}) {
		$self->{number_of_users} = $self->{scale}->number_of_users;
		$self->{number_of_items} = $self->{scale}->number_of_items;
		$self->{scale_min}       = $self->{scale}->min;
		$self->{scale_max}       = $self->{scale}->max;
		$self->{scale_binary}    = $self->{scale}->binary;
	}
	else {
		croak 'No scale object found';
	}

	bless $self, $class;

	$self->compute_averages;

	return $self;
}


sub predict {
	my ($self, $user_id, $item_id) = @_;

	my $number_of_users = $self->{number_of_users};
	my $number_of_items = $self->{number_of_items};

	if ($self->{type} eq 'global') {
		return $self->{global_average};
	}
    elsif ($self->{type} eq 'user') {
        if ($user_id < $number_of_users) {
            return $self->{u_averages_ref}->[$user_id];
        }
        else {
            return $self->{global_average};
        }
    }
    elsif ($self->{type} eq 'item') {
        if ($item_id < $number_of_items) {
            return $self->{i_averages_ref}->[$item_id];
        }
        else {
            return $self->{global_average};
        }
    }
    elsif ($self->{type} eq 'default') {
        if ($user_id < $number_of_users && $item_id < $number_of_items) {
            return ($self->{u_averages_ref}->[$user_id] + $self->{i_averages_ref}->[$item_id]) / 2;
        }
        elsif ($user_id < $number_of_users) {
            return $self->{u_averages_ref}->[$user_id];
        }
        elsif ($item_id < $number_of_items) {
            return $self->{i_averages_ref}->[$item_id];
        }
        else {
            return $self->{global_average};
        }
    }
}

sub compute_averages {
	my ($self) = @_;

	$self->{global_average} = $self->{known_ratings}->{global_average};
	$self->{u_averages_ref} = $self->{known_ratings}->compute_row_averages;
	$self->{i_averages_ref} = $self->{known_ratings}->compute_col_averages;
}

sub user_bias {
	my ($self, $user_id) = @_;

	return $self->{u_averages_ref}->[$user_id] - $self->{global_average};
}

sub global_average {
	my ($self) = @_;

	return $self->{global_average};
}

sub description {
	my ($self) = @_;

	return $self->{description};
}


1;
