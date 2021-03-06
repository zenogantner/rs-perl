#!/bin/sh

ML_PATH=../data/ml
RESULTS_PATH=../results/coclustering
BIN=../perl
K=$1
L=$2

# takes about 69 minutes (45 x 50 iterations)

PERL5LIB=$PERL5LIB:../perl

MAX_ITER=50

ARG="--verbose --max-iter=$MAX_ITER --display-clustering"

# static case
for DATASET in 1 2 3 4 5
do
	RESULT_FILE="$RESULTS_PATH/static-$K-$L-${MAX_ITER}it-$DATASET"
	TRAIN="--training-file=$ML_PATH/u$DATASET.base"
	COMMAND="$BIN/coclustering.pl $TRAIN --k=$K --l=$L $ARG"
	echo $COMMAND
	echo $RESULT_FILE
	$COMMAND > $RESULT_FILE
done

# random initialization
for DATASET in 1 2 3 4 5
do
	for RANDOM in 1 2 3 4 5 6 7 8
	do
		RESULT_FILE="$RESULTS_PATH/random-$RANDOM-$K-$L-${MAX_ITER}it-$DATASET"
		TRAIN="--training-file=$ML_PATH/u$DATASET.base"
		COMMAND="$BIN/coclustering.pl $TRAIN --k=$K --l=$L $ARG --random"
		echo $COMMAND
		echo $RESULT_FILE
		$COMMAND > $RESULT_FILE
	done
done

