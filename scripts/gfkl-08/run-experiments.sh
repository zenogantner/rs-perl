#!/bin/bash

BIN_PATH=$HOME/software/zeno/rs-perl
JAR_PATH=$HOME/software/multiway-clustering
DATA=$HOME/data
RESULTS_PATH=./

# general parameters
OPTIONS="--show-progress"

execute_different_experiments() {
	for arg
	do $arg
	done
}

# baseline methods
baseline() {
	for PREDICTOR in average user-average
	do
		METHOD_ARGS="--predictor=$PREDICTOR"
		RESULT_FILE="$RESULTS_PATH/error-$PREDICTOR"
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


# content-based methods
content_based() {
   	PREDICTOR="nb"
    	PREDICTOR_ARGS="--predictor=naive-bayes --sort-attributes"

	RESULT_FILE="$RESULTS_PATH/error-$PREDICTOR"
	rm -f $RESULT_FILE
	
	for ATTRIBUTES in credits actors keywords directors genres
	do
		for DATASET in 1 2 3 4 5
		do
			PREDICTION_FILE="$RESULTS_PATH/u$DATASET.prediction-$PREDICTOR-$ATTRIBUTES"
			ML_ARGS="--training-file=${DATA}/ml/u$DATASET.base --test-file=${DATA}/ml/u$DATASET.test"
			METHOD_ARGS="$PREDICTOR_ARGS --item-attrib-file=${DATA}/ml/movie-$ATTRIBUTES"
			COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS $OPTIONS $METHOD_ARGS --prediction-file=$PREDICTION_FILE"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
	done
}


linear_combination() {	
	for ATTRIBUTES in credits actors keywords directors genres
	do
		for DATASET in 1 2 3 4 5
		do
			RESULT_FILE="$RESULTS_PATH/u$DATASET.lc-$ATTRIBUTES"
			echo rm -f $RESULT_FILE
			rm -f $RESULT_FILE
			COMMAND="$BIN_PATH/blend-and-compare-predictions.pl $HOME/data/ml/u$DATASET.test u$DATASET.prediction-coclustering u$DATASET.prediction-nb-$ATTRIBUTES"
			echo $COMMAND
			echo $RESULT_FILE
			$COMMAND >> $RESULT_FILE
		done
	done
}

coclustering_perl() {
	INIT="static"
	NO_OF_CLUSTERS=3
	MAX_IT=50
	for ML_DATASET in 1 2 3 4 5
	do
	    CLUSTER_FILE="$RESULTS_PATH/cocluster-perl-$MAX_IT-$NO_OF_CLUSTERS-$NO_OF_CLUSTERS-${INIT}-ml-$ML_DATASET"
	    echo rm -f $CLUSTER_FILE
	    rm -f $CLUSTER_FILE
	    DATA_ARGS="--training-file=${DATA}/ml/u$ML_DATASET.base --test-file=${DATA}/ml/u$ML_DATASET.test"
	    METHOD_ARGS="--user-clusters=${NO_OF_CLUSTERS} --item-clusters=${NO_OF_CLUSTERS} --max-iter=${MAX_IT}"
	    COMMAND="$BIN_PATH/coclustering.pl ${DATA_ARGS} $METHOD_ARGS --display-clustering"
	    echo $COMMAND
	    $COMMAND > $CLUSTER_FILE
	    PREDICTION_FILE="$RESULTS_PATH/u$ML_DATASET.prediction-coclustering"
	    COMMAND="$BIN_PATH/evaluate.pl $ML_ARGS --predictor=coclustering --read-cluster-file=$CLUSTER_FILE --prediction-file=$PREDICTION_FILE $DATA_ARGS"
	    echo $COMMAND
	    $COMMAND
	done
}



# coclustering
coclustering_random() {
	MAX_IT=200
        INIT="random"
	RESULT_FILE="$RESULTS_PATH/error-coclustering-no-of-clusters-${MAX_IT}-${INIT}"
	echo rm -f $RESULT_FILE
	rm -f $RESULT_FILE
	echo "Writing evaluation results to $RESULT_FILE ..."
	for ((NO_OF_CLUSTERS=1;NO_OF_CLUSTERS<=30;NO_OF_CLUSTERS+=1))
	do
	    for ML_DATASET in 1 2 3 4 5
	    do
	        for TIMES in 1 2 3 4 5 6 7 8 9 10		    
		    do
			    DATA_ARGS="${DATA}/ml/u$ML_DATASET.base.txt ${DATA}/ml/u$ML_DATASET.test.txt"
			    METHOD_ARGS="${NO_OF_CLUSTERS} ${NO_OF_CLUSTERS} ${MAX_IT}"
			    OPTIONS="no"
			    COMMAND="java -jar $JAR_PATH/coclustering.jar ${DATA_ARGS} $METHOD_ARGS $OPTIONS ${INIT}"
			    echo $COMMAND
			    $COMMAND >> $RESULT_FILE
		    done
        done
	done
}

coclustering_static() {
	MAX_IT=200
	INIT="static"
	RESULT_FILE="$RESULTS_PATH/error-coclustering-no-of-clusters-${MAX_IT}-${INIT}"
	echo rm -f $RESULT_FILE
	rm -f $RESULT_FILE
	echo "Writing evaluation results to $RESULT_FILE ..."
	for ((NO_OF_CLUSTERS=1;NO_OF_CLUSTERS<=30;NO_OF_CLUSTERS+=1))
	do
	        for ML_DATASET in 1 2 3 4 5
		    do
			    DATA_ARGS="${DATA}/ml/u$ML_DATASET.base.txt ${DATA}/ml/u$ML_DATASET.test.txt"
			    METHOD_ARGS="${NO_OF_CLUSTERS} ${NO_OF_CLUSTERS} ${MAX_IT}"
			    OPTIONS="no"
			    COMMAND="java -jar $JAR_PATH/coclustering.jar ${DATA_ARGS} $METHOD_ARGS $OPTIONS ${INIT}"
			    echo $COMMAND
			    $COMMAND >> $RESULT_FILE
		    done
	done
}


coclustering_random_iter() {
        INIT="random"
	NO_OF_CLUSTERS=3
	RESULT_FILE="$RESULTS_PATH/error-coclustering-maxit-${INIT}"
	echo rm -f $RESULT_FILE
	rm -f $RESULT_FILE
	for ((MAX_IT=1;MAX_IT<=200;MAX_IT+=1))
	do
		for ML_DATASET in 1 2 3 4 5
		do
	        	for TIMES in 1 2 3 4 5 6 7 8 9 10		    
		    	do
			    DATA_ARGS="${DATA}/ml/u$ML_DATASET.base.txt ${DATA}/ml/u$ML_DATASET.test.txt"
			    METHOD_ARGS="${NO_OF_CLUSTERS} ${NO_OF_CLUSTERS} ${MAX_IT}"
			    OPTIONS="no"
			    COMMAND="java -jar $JAR_PATH/coclustering.jar ${DATA_ARGS} $METHOD_ARGS $OPTIONS ${INIT}"
			    echo $COMMAND
			    $COMMAND >> $RESULT_FILE
			done
	        done
	done
}



coclustering_static_iter() {
	INIT="static"
	for NO_OF_CLUSTERS in 2 3 4 5 6
	do
		RESULT_FILE="$RESULTS_PATH/error-coclustering-maxit-$NO_OF_CLUSTERS-$NO_OF_CLUSTERS-${INIT}"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for ((MAX_IT=1;MAX_IT<=200;MAX_IT+=1))
		do
			echo "Writing evaluation results to $RESULT_FILE ..."
			    for ML_DATASET in 1 2 3 4 5
			    do
				    DATA_ARGS="${DATA}/ml/u$ML_DATASET.base.txt ${DATA}/ml/u$ML_DATASET.test.txt"
				    METHOD_ARGS="${NO_OF_CLUSTERS} ${NO_OF_CLUSTERS} ${MAX_IT}"
				    OPTIONS="no"
				    COMMAND="java -jar $JAR_PATH/coclustering.jar ${DATA_ARGS} $METHOD_ARGS $OPTIONS ${INIT}"
				    echo $COMMAND
				    $COMMAND >> $RESULT_FILE
			    done
		done
	done
}


coclustering_static_iter_perl() {
	INIT="static"
	for NO_OF_CLUSTERS in 3
	do
		RESULT_FILE="$RESULTS_PATH/error-coclustering-perl-maxit-$NO_OF_CLUSTERS-$NO_OF_CLUSTERS-${INIT}"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
		for ((MAX_IT=1;MAX_IT<=200;MAX_IT+=1))
		do
			echo "Writing evaluation results to $RESULT_FILE ..."
			    for ML_DATASET in 1 2 3 4 5
			    do
				    DATA_ARGS="--training-file=${DATA}/ml/u$ML_DATASET.base --test-file=${DATA}/ml/u$ML_DATASET.test"
				    METHOD_ARGS="--user-clusters=${NO_OF_CLUSTERS} --item-clusters=${NO_OF_CLUSTERS} --max-iter=${MAX_IT}"
				    COMMAND="$BIN_PATH/coclustering.pl ${DATA_ARGS} $METHOD_ARGS --compute-error"
				    echo $COMMAND
				    $COMMAND >> $RESULT_FILE
			    done
		done
	done
}

coclustering_netflix_static() {
	java -Xmx3500m -jar $JAR_PATH/coclustering.jar ~/data/netflix/train-byuser-nd.txt ~/data/netflix/test-byuser-nd.txt 3 3 100 no static >> netflix-static-3-3
}

coclustering_netflix_random() {
	MAX_IT=100
        INIT="random"
	echo "Writing evaluation results to $RESULT_FILE ..."
	for ((NO_OF_CLUSTERS=2;NO_OF_CLUSTERS<=10;NO_OF_CLUSTERS+=1))
	do
		RESULT_FILE="$RESULTS_PATH/netflix-${INIT}-${NO_OF_CLUSTERS}"
		echo rm -f $RESULT_FILE
		rm -f $RESULT_FILE
	        for TIMES in 1 2 3 4 5 
		do
			    DATA_ARGS="${DATA}/netflix/train-byuser-nd.txt ${DATA}/netflix/test-byuser-nd.txt"
			    METHOD_ARGS="${NO_OF_CLUSTERS} ${NO_OF_CLUSTERS} ${MAX_IT}"
			    OPTIONS="no"
			    COMMAND="java -Xmx3500m -jar $JAR_PATH/coclustering.jar ${DATA_ARGS} $METHOD_ARGS $OPTIONS ${INIT}"
			    echo $COMMAND
			    $COMMAND >> $RESULT_FILE
		done
	done
}

execute_different_experiments $@

