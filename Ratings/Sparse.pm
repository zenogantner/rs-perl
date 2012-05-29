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

# NOTE: Although it is not enforced, this ratings representation should only be used in a read-only manner!

package Ratings::Sparse;
use base 'Exporter';
our @EXPORT = qw(
	$PACK_TEMPLATE
);
#	get_rows get_cols
#	compute_average
#	compute_row_averages compute_col_averages


our $PACK_TEMPLATE = 'JJ';

sub new {
	my ($class, $arg_ref) = @_;

	my $self = {
		verbose      => 0,
		scale_binary => 0,
		%$arg_ref,
		# matrix_ref
		# number_of_rows + number_of_cols | scale
	};

	if (!exists $self->{matrix_ref}) {
		die "matrix_ref not defined!\n";
	}
	if (exists $self->{scale}) {
		$self->{number_of_rows} = $self->{scale}->number_of_users;
		$self->{number_of_cols} = $self->{scale}->number_of_items;
		$self->{scale_min}      = $self->{scale}->min;
		$self->{scale_max}      = $self->{scale}->max;
		$self->{scale_binary}   = $self->{scale}->binary;		
	}

	if ($self->{scale_binary}) {
		my $number_of_entries = scalar(keys %{$self->{matrix_ref}});
		my $number_of_cells   = $self->{number_of_rows} * $self->{number_of_cols};

		$self->{global_average} = $number_of_entries / $number_of_cells;
	}
	else {
		$self->{global_average} = compute_average($self->{matrix_ref});
	}

	return bless $self, $class;
}


sub get_rows {
	my ($self) = @_;

	if (exists $self->{rows_ref}) {
		return $self->{rows_ref};
	}

	my $matrix_ref     = $self->{matrix_ref};
	my $number_of_rows = $self->{number_of_rows};

	my @rows = map { $_ = {} } (1 .. $number_of_rows);      # m elements which are references to an empty hash
	foreach my $matrix_index (keys %$matrix_ref) {
		my ($row, $col) = unpack($PACK_TEMPLATE, $matrix_index);
		my $row_ref = $rows[$row];
		$row_ref->{$matrix_index} = $matrix_ref->{$matrix_index}; # insert into hash for row $row
	}

	$self->{rows_ref} = \@rows;
	return \@rows;
}


sub get_cols {
	my ($self) = @_;

	# this only works if there weren't any modifications ...
	if (exists $self->{cols_ref}) {
		return $self->{cols_ref};
	}

	my $matrix_ref     = $self->{matrix_ref};
	my $number_of_cols = $self->{number_of_cols};

	my @cols = map { $_ = {} } (1 .. $number_of_cols);      # n elements which are references to an empty hash
	foreach my $matrix_index (keys %$matrix_ref) {
		my ($row, $col) = unpack($PACK_TEMPLATE, $matrix_index);
		my $col_ref = $cols[$col];
		$col_ref->{$matrix_index} = $matrix_ref->{$matrix_index}; # insert into hash for column $col
	}

	$self->{cols_ref} = \@cols;
	return \@cols;
}


# class method
sub compute_average {
	my ($matrix_ref, $default_average) = @_;

	my $number_of_entries = keys %$matrix_ref;
	if ($number_of_entries == 0) {
		if (defined $default_average) {
			return $default_average;
		}
		else {
			die "Ratings::Sparse->compute_average: No ratings provided, and no default average defined!\n";
		}
	}

	my $sum = 0;
	foreach my $index (keys %$matrix_ref) {
		$sum = $sum + $matrix_ref->{$index};
	}
	return $sum / $number_of_entries;
}


sub compute_row_averages {
	my ($self) = @_;

	my $rows_ref       = $self->get_rows;
	my $number_of_rows = $self->{number_of_rows};
	my $number_of_cols = $self->{number_of_cols};

	my @a_r;
	if ($self->{scale_binary}) {
		foreach my $row_id (0 .. $number_of_rows - 1) {
			my $number_of_entries_in_row = scalar(keys %{$rows_ref->[$row_id]});
			$a_r[$row_id] = $number_of_entries_in_row / $number_of_cols;
		}
	}
	else {
		my $global_average = $self->{global_average};
		for (my $i = 0; $i < $number_of_rows; $i++) {
			$a_r[$i] = compute_average($rows_ref->[$i], $global_average);
		}
	}

	return \@a_r;
}


sub compute_col_averages {
	my ($self) = @_;

	my $cols_ref       = $self->get_cols;
	my $number_of_rows = $self->{number_of_rows};
	my $number_of_cols = $self->{number_of_cols};

	my @a_c;
	if ($self->{scale_binary}) {
		foreach my $col_id (0 .. $number_of_cols - 1) {
			my $number_of_entries_in_col = scalar(keys %{$cols_ref->[$col_id]});
			$a_c[$col_id] = $number_of_entries_in_col / $number_of_rows;
		}
	}
	else {
		my $global_average = $self->{global_average};
		for (my $j = 0; $j < $number_of_cols; $j++) {
			$a_c[$j] = compute_average($cols_ref->[$j], $global_average);
		}
	}

	return \@a_c;
}


sub entry_exists {
	my ($self, $row_id, $col_id) = @_;

	my $key = pack($PACK_TEMPLATE, $row_id, $col_id);

	return exists $self->{matrix_ref}->{$key};
}

1;
