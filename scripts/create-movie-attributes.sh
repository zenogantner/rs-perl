#!/bin/sh

BIN_PATH=../perl
DATA_PATH=../data
N=$1

# different types of persons
for TYPE in actors actresses directors producers writers
do
	INPUTARGS="--imdb-credit-file=$DATA_PATH/imdb/$TYPE.list --ml-movie-file=$DATA_PATH/ml/u.item"
	OUTPUTARGS="--output-person-file=$DATA_PATH/u.$TYPE-$N --output-movie-file=$DATA_PATH/movie-$TYPE-$N"
	COMMAND="$BIN_PATH/ml-imdb-credits.pl $INPUTARGS $OUTPUTARGS --n=$N"
	echo $COMMAND
	$COMMAND
done

# all actors
INPUTARGS="--ml-movie-file=$DATA_PATH/ml/u.item"
for TYPE in actors actresses
do
	INPUTARGS="$INPUTARGS --imdb-credit-file=$DATA_PATH/imdb/$TYPE.list"
done
OUTPUTARGS="--output-person-file=$DATA_PATH/u.actors-mf-$N --output-movie-file=$DATA_PATH/movie-actors-mf-$N"
COMMAND="$BIN_PATH/ml-imdb-credits.pl $INPUTARGS $OUTPUTARGS --n=$N"
echo $COMMAND
$COMMAND


# complete credits
INPUTARGS="--ml-movie-file=$DATA_PATH/ml/u.item"
for TYPE in actors actresses directors producers writers
do
	INPUTARGS="$INPUTARGS --imdb-credit-file=$DATA_PATH/imdb/$TYPE.list"
done
OUTPUTARGS="--output-person-file=$DATA_PATH/u.credits-$N --output-movie-file=$DATA_PATH/movie-credits-$N"
COMMAND="$BIN_PATH/ml-imdb-credits.pl $INPUTARGS $OUTPUTARGS --n=$N"
echo $COMMAND
$COMMAND

# keywords
INPUTARGS="--imdb-keyword-file=$DATA_PATH/imdb/keywords.list --ml-movie-file=$DATA_PATH/ml/u.item"
OUTPUTARGS="--output-keyword-file=$DATA_PATH/u.keywords-$N --output-movie-file=$DATA_PATH/movie-keywords-$N"
COMMAND="$BIN_PATH/ml-imdb-keywords.pl $INPUTARGS $OUTPUTARGS --n=$N"
echo $COMMAND
$COMMAND
