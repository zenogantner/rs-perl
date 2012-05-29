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

use English qw( -no_match_vars );
use Getopt::Long;

use Ratings::MovieLens;
use Ratings::Sparse;
use Predictor::ContentBased;
use CoClustering::Utility;
use Evaluation;

my $verbose            = 0;
my $movielens_file       = '';
my $movie_attribute_file = '';
my $user_keyword_file    = 'user-keywords';

GetOptions(
	'verbose'              => \$verbose,
	'movielens-file=s'     => \$movielens_file,
	'movie-keyword-file=s' => \$movie_keyword_file,
	'user-keyword-file=s'  => \$user_keyword_file,
);

if ($movielens_file eq '' || $movie_keyword_file eq '') {
	print STDERR "Please provide filenames...\n";
	exit -1;
}

print STDERR "Initializing predictor ... " if $verbose;
my $predictor = Predictor::ContentBased->new({
	ratings_file       => $movielens_file,
	movie_keyword_file => $movie_keyword_file,
	verbose            => $verbose,
});
print STDERR "done.\n" if $verbose;

print STDERR "Saving model ... " if $verbose;
$predictor->save_model($user_keyword_file);
print STDERR "done.\n" if $verbose;

