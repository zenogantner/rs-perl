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

package Predictor::Util;
use base qw( Exporter );
our @EXPORT = qw( get_top_n );

# a module for different practical functions ...

sub get_top_n {
        my ($probability_ref, $n) = @_;

        my @avg_keys  = sort{$probability_ref->{$b} <=> $probability_ref->{$a}} keys %$probability_ref;

        my @top_n_keys = ();
        KEY:
        for (my $i = 0; $i < $n; $i++) {
                my $key = $avg_keys[$i];
                if (defined $key) {
                        push @top_n_keys, $key;
                }
                else  {
                        last KEY;
                }
        }

        return \@top_n_keys;
}

1;

