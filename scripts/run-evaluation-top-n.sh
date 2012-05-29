#!/bin/bash

# TODO: rewrite in Perl
# TODO: graphical version with different progress bars ...
# TODO: think about smarter handling of different methods

BIN_PATH=../perl
DATA=../data
RESULTS_PATH=../results

# coclustering parameters
MAX_ITER=50
K=3
L=3

#if [$1 = '']; then
#	echo Call ${0} TOP_N ATTRIB_N
#	exit 1
#fi
#if [$2 = '']; then
#	echo Call ${0} TOP_N ATTRIB_N
#	exit 1
#fi
TOP_N=10
EVALUATION_ARGS="--top-n=${TOP_N}"
OPTIONS="--show-progress"

ATTRIB_N=1

PERL5LIB=$PERL5LIB:../perl


execute_different_methods() {
	for arg
	do $arg
	done
}

#execute_different_methods $@
#exit 0

# baseline methods - takes about 3'30'' (2 files)
baseline() {
	for PREDICTOR in averages most-popular
	do
		METHOD_ARGS="--predictor=$PREDICTOR"
		RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for ML_DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$ML_DATASET.base --test-file=${DATA}/ml/u$ML_DATASET.test"

			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $EVALUATION_ARGS $METHOD_ARGS"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
	done
}


# coclustering - this part takes about 19' (9 files)
coclustering() { 
	PREDICTOR=coclustering
	for RANDOM_INIT in 1 2 3 4 5 6 7 8
	do
		RESULT_FILE="$RESULTS_PATH/top-$TOP_N-${PREDICTOR}-random-${RANDOM_INIT}-$K-$L-${MAX_ITER}"
		rm -f $RESULT_FILE
		for DATASET in 1 2 3 4 5
		do
			CLUSTER="--cluster-file=../results/coclustering/random-${RANDOM_INIT}-$K-$L-${MAX_ITER}it-$DATASET"
			ML_ARGS="--training-file=${DATA}/ml/u${DATASET}.base --test-file=${DATA}/ml/u${DATASET}.test"

			COMMAND="${BIN_PATH}/evaluate.pl ${ML_ARGS} ${OPTIONS} ${EVALUATION_ARGS} --predictor=${PREDICTOR} ${CLUSTER}"
			echo $COMMAND 
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
	done
	# coclustering with static initialization
	RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR-static-$K-$L-${MAX_ITER}"
	rm -f $RESULT_FILE
	for DATASET in 1 2 3 4 5
	do
		METHOD_ARGS="--predictor=$PREDICTOR --cluster-file=../results/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"
		ML_ARGS="--training-file=${DATA}/ml/u${DATASET}.base --test-file=${DATA}/ml/u${DATASET}.test"

		COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $EVALUATION_ARGS $METHOD_ARGS"
		echo $COMMAND 
		echo $RESULT_FILE
		$COMMAND >> $RESULT_FILE
	done
}


# TODO: split up
# content-based methods
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

		ATTRIBUTES=genres
		RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR-$ATTRIBUTES"
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

 		for ATTRIBUTES in actors actresses writers producers
# 		for ATTRIBUTES in credits actors-mf keywords directors actors actresses writers producers
		do
			RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR-$ATTRIBUTES-$ATTRIB_N"
			rm -f $RESULT_FILE
			for DATASET in 1 2 3 4 5
			do
				ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
				OPTIONS="--show-progress"
				METHOD_ARGS="$PREDICTOR_ARGS --item-attrib-file=${DATA}/movie-$ATTRIBUTES-$ATTRIB_N"

				COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $EVALUATION_ARGS $METHOD_ARGS"
				echo $COMMAND
				echo $RESULT_FILE
				$COMMAND >> $RESULT_FILE
			done
		done

	done
}


# 
# takes about 360 minutes for 9x5=45 files
joint_weighting() {
	for ATTRIBUTES in credits actors-mf keywords directors actors actresses writers producers
	do
		PREDICTOR1_ARGS="--predictor=coclustering"
		PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES-$ATTRIB_N"
		FILE_TEMPLATE="$RESULTS_PATH/top-$TOP_N-jw-LAMBDA-$ATTRIBUTES-$ATTRIB_N-static-coclustering"
		PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --joint-weighting=0.5 --several-lambdas=$FILE_TEMPLATE"

		# delete old result files:
		for LAMBDA in 0.7 0.75 0.8 0.85 0.9
		do
			PREDICTOR="jw-${LAMBDA}"
			RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR-$ATTRIBUTES-$ATTRIB_N-static-coclustering"
			echo rm -f $RESULT_FILE
			rm -f $RESULT_FILE
		done

		for DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			# Take static initialization results, we could use a different one.
			CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"
			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS ${EVALUATION_ARGS} $PREDICTOR_ARGS $CLUSTER"
			echo $COMMAND
			echo $FILE_TEMPLATE
			$COMMAND
		done
	done

	ATTRIBUTES=genres
	# predictor1 already defined
	PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES"
	PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --joint-weighting=0.5 --several-lambdas=$FILE_TEMPLATE"

	# delete old result files:
	for LAMBDA in 0.7 0.75 0.8 0.85 0.9
	do
		PREDICTOR="jw-${LAMBDA}"
		RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR-$ATTRIBUTES-static-coclustering"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
	done

	for DATASET in 1 2 3 4 5
	do
		ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
		# Take static initialization results, we could use a different one.
		CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"

		COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS ${EVALUATION_ARGS} $PREDICTOR_ARGS $CLUSTER"
		echo $COMMAND
		echo $FILE_TEMPLATE
		$COMMAND
	done

}

linear_combination() {
	for ATTRIBUTES in keywords directors
	#for ATTRIBUTES in credits actors-mf keywords directors actors actresses writers producers
	do
		PREDICTOR1_ARGS="--predictor=coclustering"
		PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES-$ATTRIB_N"
		FILE_TEMPLATE="$RESULTS_PATH/top-$TOP_N-lc-LAMBDA-$ATTRIBUTES-$ATTRIB_N-static-coclustering"
		PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --linear-combination=0.5 --several-lambdas=$FILE_TEMPLATE"

		# delete old result files:
		for LAMBDA in 0.7 0.75 0.8 0.85 0.9
		do
			PREDICTOR="lc-${LAMBDA}"
			RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR-$ATTRIBUTES-$ATTRIB_N-static-coclustering"
			echo rm -f $RESULT_FILE
			rm -f $RESULT_FILE
		done

		for DATASET in 1 2 3 4 5
		do
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			# Take static initialization results, we could use a different one.
			CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"
			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS ${EVALUATION_ARGS} $PREDICTOR_ARGS $CLUSTER"
			echo $COMMAND
			echo $FILE_TEMPLATE
			$COMMAND
		done
	done

	ATTRIBUTES=genres
	# predictor1 already defined
	PREDICTOR2_ARGS="--predictor=naive-bayes --sort-attributes --item-attrib-file=${DATA}/movie-$ATTRIBUTES"
	PREDICTOR_ARGS="${PREDICTOR1_ARGS} ${PREDICTOR2_ARGS} --linear-combination=0.5 --several-lambdas=$FILE_TEMPLATE"

	# delete old result files:
	for LAMBDA in 0.7 0.75 0.8 0.85 0.9
	do
		PREDICTOR="lc-${LAMBDA}"
		RESULT_FILE="$RESULTS_PATH/top-$TOP_N-$PREDICTOR-$ATTRIBUTES-static-coclustering"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
	done

	for DATASET in 1 2 3 4 5
	do
		ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
		# Take static initialization results, we could use a different one.
		CLUSTER=" --cluster-file=${RESULTS_PATH}/coclustering/static-$K-$L-${MAX_ITER}it-$DATASET"

		COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS ${EVALUATION_ARGS} $PREDICTOR_ARGS $CLUSTER"
		echo $COMMAND
		echo $FILE_TEMPLATE
		$COMMAND
	done

}


execute_different_methods $@

