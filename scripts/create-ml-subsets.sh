#!/bin/bash

ML_PATH=../data/ml

ONE_PERCENT=1000

for PERCENT in 10 20 30 40 50 60 70 80 90
do
	DATA_FILE=${ML_PATH}/subsets/u-${PERCENT}-subset
	head -`expr ${PERCENT} \* ${ONE_PERCENT}` ${ML_PATH}/u.data > ${DATA_FILE}

	# clean 80/20 split for 5-fold cross validation
	TEST_SIZE=`expr ${PERCENT} \* ${ONE_PERCENT} / 5`
	echo "$PERCENT %, test size: $TEST_SIZE"
	for i in 1 2 3 4 5
	do
        	head -`expr $i \* ${TEST_SIZE}` ${DATA_FILE} | tail -${TEST_SIZE} > ${DATA_FILE}-$i.test
	  ##      sort -t"        " -k 1,1n -k 2,2n tmp.$$ > ${DATA_FILE}-$i.test
         	head -`expr \( $i - 1 \) \* ${TEST_SIZE}` ${DATA_FILE} >  ${DATA_FILE}-$i.base
	        tail -`expr \( 5 - $i \) \* ${TEST_SIZE}` ${DATA_FILE} >> ${DATA_FILE}-$i.base
	  ##       sort -t"        " -k 1,1n -k 2,2n tmp.$$ > ${DATA_FILE}-$i.base
	done
done

