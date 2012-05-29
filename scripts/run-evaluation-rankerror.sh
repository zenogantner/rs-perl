#!/bin/bash

BIN_PATH=../perl
DATA=../data
RESULTS_PATH=../results

ERROR_PREFIX="rank-error"

# general parameters
OPTIONS="--show-progress --${ERROR_PREFIX}"

# coclustering parameters
MAX_ITER=50
K=3
L=3

# parameters for the different content-based methods
ATTRIB_N=2

PERL5LIB=$PERL5LIB:../perl

# TODO: hybrid methods: compute for several lambdas at once ...

execute_different_methods() {
	for arg
	do $arg
	done
}

# baseline methods
# takes about 45" (2 files)
baseline() {
	for PREDICTOR in averages most-popular
	do
		METHOD_ARGS="--predictor=$PREDICTOR"
		RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for ML_DATASET in 1 2 3 4 5
		do
			DATA_ARGS="--training-file=${DATA}/ml/u$ML_DATASET.base --test-file=${DATA}/ml/u$ML_DATASET.test"

			COMMAND="$BIN_PATH/evaluate.pl ${DATA_ARGS} $OPTIONS $METHOD_ARGS"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
	done
}


# coclustering - this part takes about 3'48" (9 files)
coclustering() { 
	PREDICTOR=coclustering
#	for ITER in 0
#	for ITER in 0 ${MAX_ITER}
	for ITER in ${MAX_ITER}
	do
		for RANDOM_INIT in 1 2 3 4 5 6 7 8
		do
			RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-${PREDICTOR}-random-${RANDOM_INIT}-$K-$L-${ITER}"
			rm -f $RESULT_FILE
			for DATASET in 1 2 3 4 5
			do
				CLUSTER="--cluster-file=../results/coclustering/random-${RANDOM_INIT}-$K-$L-${ITER}it-$DATASET"

				ML_ARGS="--training-file=${DATA}/ml/u${DATASET}.base --test-file=${DATA}/ml/u${DATASET}.test"

				COMMAND="${BIN_PATH}/evaluate.pl ${ML_ARGS} ${OPTIONS} --predictor=${PREDICTOR} ${CLUSTER}"
				echo $COMMAND 
				echo $RESULT_FILE
				$COMMAND >> $RESULT_FILE
			done
		done
		# coclustering with static initialization
		RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR-static-$K-$L-${ITER}"
		rm -f $RESULT_FILE
		for DATASET in 1 2 3 4 5
		do
			METHOD_ARGS="--predictor=$PREDICTOR --cluster-file=../results/coclustering/static-$K-$L-${ITER}it-$DATASET"

			ML_ARGS="--training-file=../data/ml/u${DATASET}.base --test-file=../data/ml/u${DATASET}.test"

			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $METHOD_ARGS"
			echo $COMMAND 
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
	done
}


# content-based methods
# 9 files, takes about 22'13" for ATTRIB_N=1
content_based() {
	for PREDICTOR in nb_sort
	do
		if [ $PREDICTOR = "nb" ]
    		    then PREDICTOR_ARGS="--predictor=naive-bayes"
		elif [ $PREDICTOR = "nb_mpr" ]
		    then PREDICTOR_ARGS="--predictor=naive-bayes --most-probable-rating"
		elif [ $PREDICTOR = "nb_sort" ]
		    then PREDICTOR_ARGS="--predictor=naive-bayes --sort-attributes"
		else PREDICTOR_ARGS="--predictor=content-based"
		fi

		for ATTRIBUTES in credits actors-mf keywords directors actors actresses writers producers
		do
			RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR-$ATTRIBUTES-$ATTRIB_N"
			rm -f $RESULT_FILE
			for DATASET in 1 2 3 4 5
			do
				ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
				METHOD_ARGS="$PREDICTOR_ARGS --item-attrib-file=${DATA}/movie-$ATTRIBUTES-$ATTRIB_N"

				COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $METHOD_ARGS"
				echo $COMMAND
				echo $RESULT_FILE
				$COMMAND >> $RESULT_FILE
			done
		done

		ATTRIBUTES=genres
		RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR-$ATTRIBUTES"
		rm -f $RESULT_FILE
		for DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			METHOD_ARGS="$PREDICTOR_ARGS --item-attrib-file=${DATA}/movie-$ATTRIBUTES"

			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $EVALUATION_ARGS $METHOD_ARGS"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
	done
}


# 5 x 9 result files
# takes about 121' for -1
# takes about 84' for -2
joint_weighting() {
	for LAMBDA in 0.7 0.75 0.8 0.85 0.9
	do
		for ATTRIBUTES in keywords directors writers actors actresses actors-mf producers credits
		do
		PREDICTOR="jw-${LAMBDA}"
		PREDICTOR1_ARGS="--predictor=coclustering"
		PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES-$ATTRIB_N"
		PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --joint-weighting=${LAMBDA}"
		RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR-$ATTRIBUTES-$ATTRIB_N-static-coclustering"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			# Take static initialization results, we could use a different one.
			CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"

			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $PREDICTOR_ARGS $CLUSTER"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
		done

		ATTRIBUTES=genres
		# predictor1 already defined
		PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES"
		PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --joint-weighting=${LAMBDA}"
		RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR-$ATTRIBUTES-static-coclustering"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			# Take static initialization results, we could use a different one.
			CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"

			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $PREDICTOR_ARGS $CLUSTER"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done

	done
}


# over all, we have 9 x 5!
# takes about 119' for ATTRIB_N=1
# takes about  79' for ATTRIB_N=2
linear_combination() {
	for LAMBDA in 0.7 0.75 0.8 0.85 0.9
	do
		for ATTRIBUTES in keywords directors writers actors actresses actors-mf producers credits
		do
		PREDICTOR="lc-${LAMBDA}"
		PREDICTOR1_ARGS="--predictor=coclustering"
		PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES-$ATTRIB_N"
		PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --linear-combination=${LAMBDA}"
		RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR-$ATTRIBUTES-$ATTRIB_N-static-coclustering"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			# Take static initialization results, we could use a different one.
			CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"

			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $PREDICTOR_ARGS $CLUSTER"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
		done

		ATTRIBUTES=genres
		# predictor1 already defined
		PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES"
		PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --linear-combination=${LAMBDA}"
		RESULT_FILE="$RESULTS_PATH/${ERROR_PREFIX}-$PREDICTOR-$ATTRIBUTES-static-coclustering"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			# Take static initialization results, we could use a different one.
			CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"

			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $PREDICTOR_ARGS $CLUSTER"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done

	done
}


execute_different_methods $@

