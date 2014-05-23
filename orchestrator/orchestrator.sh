
#!/bin/sh
# $1 = ALGO directory, relative to base algo dir
# $2 = COMPUTE env directory, relative to base compute envs dir
# $3 = DATA directory, relative to base data dir

# Startup with e.g. orchestrator.sh 01.java/01.mahout/01.example/ 01.linux/01.centos/01.mahout/ 01.MovieTweetings/datasets/snapshots_10K/

BASEDIR=$PWD/..
ALGO_DIR=$BASEDIR/../algorithms
DATA_DIR=$BASEDIR/../datasets
COMPUTING_ENV_DIR=$BASEDIR/../computingenvironments
ORCHESTRATOR_DIR=$BASEDIR/orchestrator

echo reference framework base path: $BASEDIR
echo algorithm base path: $ALGO_DIR
echo dataset path: $DATA_DIR
echo computing environment path: $COMPUTING_ENV_DIR
echo orchestrator path: $ORCHESTRATOR_DIR

## MESSAGE
MESSAGING_DIR=/tmp/messaging
OUTF=$MESSAGING_DIR/cmd_out.msg
BASEMSG_IN=cmd_in.msg
INF=$MESSAGING_DIR/$BASEMSG_IN

## ORCHESTRATOR
SDIR=$ORCHESTRATOR_DIR/resources/

FNAME=$BASEDIR/output_filename.1

echo "cleaning"
rm -f $FNAME
rm -f $INF
rm -f $OUTF
if [ -f .pid ]; then
	kill -9 `cat .pid`
fi
mkdir -p $MESSAGING_DIR

echo "DO: Update git REPOs"
cd $ALGO_DIR
git pull

cd $DATA_DIR
git pull

cd $COMPUTING_ENV_DIR
git pull

# TODO: creating train/test sets

echo "DO: starting machine"
cd $COMPUTING_ENV_DIR/$2
SHARED_ALGO=$ALGO_DIR/$1 SHARED_DATA=$DATA_DIR/$3 SHARED_MSG=$MESSAGING_DIR vagrant up 

echo "STATUS: waiting for machine to be ready"
while [ ! -f $OUTF ] ; 
do
        sleep 2
done
if [ `cat $OUTF` = "READY" ]; then
	echo "INFO: machine started"
else
	echo "WARN: machine failed to start. Process stopped."
	exit
fi
rm -f $OUTF

echo "DO: read input"

echo -e "READ_INPUT\nentities=/mnt/data/entities.dat\nrelations=/mnt/data/relations.dat" > $INF

while [ ! -f $OUTF ] ; 
do
	sleep 2
done
if [ `cat $OUTF` = "OK" ]; then
        echo "INFO: input correctly read"
else
        echo "WARN: some errors while processing input. Process stopped."
        exit
fi
rm -f $OUTF

echo "DO: train"
echo -e "TRAIN" > $INF 

while [ ! -f $OUTF ] ; 
do 
        sleep 2
done
if [ `cat $OUTF` = "OK" ]; then
        echo "INFO: recommender correctly trained"
else
        echo "WARN: some errors while training the recommender. Process stopped."
        exit
fi
rm -f $OUTF

echo "DO: recommend"
echo -e "RECOMMEND\noutput_recommendations.1\n7\n10\n11\n15\n16\n22\n27\n28" > $INF

while [ ! -f $OUTF ] ; 
do 
        sleep 2
done
if [ `cat $OUTF` = "OK" ]; then
        echo "INFO: recommendations correctly generated"
else
        echo "WARN: some errors while generating recommendations. Process stopped."
        exit
fi
rm -f $OUTF

echo "DO: stop"
echo -e "STOP" > $INF

# TODO: test/evaluate the output
sleep 5
kill -9 $pid
rm -f .pid
echo "INFO: finished"
