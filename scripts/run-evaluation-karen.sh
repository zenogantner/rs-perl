#!/bin/sh

BIN_PATH=../perl
DATA_PATH=../data/karen
RESULTS_PATH=../results

TOP_N=$1
EVALUATION_ARGS="--top-n=$TOP_N"

PERL5LIB=$PERL5LIB:../perl

# baseline methods
for PREDICTOR in averages most-popular
do
	METHOD_ARGS="--predictor=$PREDICTOR --matrix-file-mode"
	RESULT_FILE="$RESULTS_PATH/karen-top-$TOP_N-$PREDICTOR"
	echo rm -f $RESULT_FILE
	rm -f $RESULT_FILE
	for DATASET in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10"
	do
		DATA_ARGS="--training-file=$DATA_PATH/$DATASET/trainMatrix.data --test-file=$DATA_PATH/$DATASET/testMatrix.data"
		OPTIONS="--show-progress --matrix-file-mode"

		COMMAND="$BIN_PATH/evaluate.pl $DATA_ARGS $OPTIONS $EVALUATION_ARGS $METHOD_ARGS"
		echo $COMMAND
		$COMMAND >> $RESULT_FILE
	done
done


# coclustering
PREDICTOR=coclustering
for RANDOM_SEED in 1 2 3 4 5 6 7 8
do
	RESULT_FILE="$RESULTS_PATH/karen-top-$TOP_N-$PREDICTOR-50-$RANDOM_SEED"
	echo rm -f $RESULT_FILE
	rm -f $RESULT_FILE
	for DATASET in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10"
	do
		METHOD_ARGS="--predictor=$PREDICTOR --cluster-file=../results/ml-karen-$DATASET-50-$RANDOM_SEED.cluster"

		DATA_ARGS="--training-file=$DATA_PATH/$DATASET/trainMatrix.data --test-file=$DATA_PATH/$DATASET/testMatrix.data"
		OPTIONS="--show-progress --matrix-file-mode"

		COMMAND="$BIN_PATH/evaluate.pl $DATA_ARGS $OPTIONS $EVALUATION_ARGS $METHOD_ARGS"
		echo $COMMAND 
		#$COMMAND >> $RESULT_FILE
	done
done


# content-based methods
for PREDICTOR in nb nb_mpr #cbf
do
	if [ $PREDICTOR = "nb" ]
    	    then PREDICTOR_ARGS="--predictor=naive-bayes"
	elif [ $PREDICTOR = "nb_mpr" ]
	    then PREDICTOR_ARGS="--predictor=naive-bayes --most-probable-rating"
	else PREDICTOR_ARGS="--predictor=content-based"
	fi

	RESULT_FILE="$RESULTS_PATH/karen-top-$TOP_N-$PREDICTOR"
	rm -f $RESULT_FILE
	for DATASET in "01" "02" "03" "04" "05" "06" "07" "08" "09" "10"
	do
		DATA_ARGS="--training-file=$DATA_PATH/$DATASET/trainMatrix.data --test-file=$DATA_PATH/$DATASET/testMatrix.data"
		OPTIONS="--show-progress --matrix-file-mode"
		METHOD_ARGS="$PREDICTOR_ARGS --item-attrib-file=$DATA_PATH/$DATASET/AIMatrix.data"
			COMMAND="$BIN_PATH/evaluate.pl $DATA_ARGS $OPTIONS $EVALUATION_ARGS $METHOD_ARGS"
		echo $COMMAND
		#$COMMAND >> $RESULT_FILE
	done
done


