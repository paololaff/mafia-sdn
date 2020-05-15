

if [ $DEMO = "1.1" ]
then
	NAME="1.1 - OpenFlow [Statistics]"
	FOLDER=$THIS_DIR/demos/1-openflow/1.1-statistics
	P4_INPUT=$FOLDER/p4src/of.p4
	JSON_OUTPUT=$FOLDER/p4src/of.json
	DEBUG_FILE=$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "1.2" ]
then
	NAME="1.2 - OpenFlow [Flow Start/End Notification]"
	FOLDER=$THIS_DIR/demos/1-openflow/1.2-flow_start_end
	P4_INPUT=$FOLDER/p4src/of.p4
	JSON_OUTPUT=$FOLDER/p4src/of.json
	DEBUG_FILE=$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "2.1" ]
then
	NAME="2.1 - DevoFlow [Thresholds]"
	FOLDER=$THIS_DIR/demos/2-devoflow/2.1-thresholds
	P4_INPUT=$FOLDER/p4src/devoflow.p4
	JSON_OUTPUT=$FOLDER/p4src/devoflow.json
	DEBUG_FILE=$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "2.2" ]
then
	NAME="2.2 - DevoFlow [Count-Min Sketch]"
	FOLDER=$THIS_DIR/demos/2-devoflow/2.2-count_min_sketch
	P4_INPUT=$FOLDER/p4src/devoflow.p4
	JSON_OUTPUT=$FOLDER/p4src/devoflow.json
	DEBUG_FILE=$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "3.1" ]
then
	NAME="3.1 - FleXam [Stochastic Sampling]"
	FOLDER=$THIS_DIR/demos/3-flexam/3.1-sample_stochastic
	P4_INPUT=$FOLDER/p4src/flexam.p4
	JSON_OUTPUT=$FOLDER/p4src/flexam.json
	DEBUG_FILE=$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "3.2" ]
then
	NAME="3.2 - FleXam [Stochastic Sampling with TCAM]"
	FOLDER=$THIS_DIR/demos/3-flexam/3.2-sample_stochastic_tcam
	P4_INPUT=$FOLDER/p4src/flexam.p4
	JSON_OUTPUT=$FOLDER/p4src/flexam.json
	DEBUG_FILE=$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "3.3" ]
then
	NAME="3.3 - FleXam [Deterministic Sampling]"
	FOLDER=$THIS_DIR/demos/3-flexam/3.3-sample_deterministic
	P4_INPUT=$FOLDER/p4src/flexam.p4
	JSON_OUTPUT=$FOLDER/p4src/flexam.json
elif [ $DEMO = "4.1" ]
then
	NAME="4.1 - OpenSketch PCSA [PCSA Cardinality Sketch]"
	FOLDER=$THIS_DIR/demos/4-opensketch/4.1-pcsa
	P4_INPUT=$FOLDER/p4src/opensketch-pcsa.p4
	JSON_OUTPUT=$FOLDER/p4src/opensketch-pcsa.json
elif [ $DEMO = "4.2" ]
then
	NAME="4.1 - OpenSketch SSD [SuperSpreader Detection with CountMin Sketch + Bitmap]"
	FOLDER=$THIS_DIR/demos/4-opensketch/4.2-superspreader
	P4_INPUT=$FOLDER/p4src/opensketch-ssd.p4
	JSON_OUTPUT=$FOLDER/p4src/opensketch-ssd.json
elif [ $DEMO = "5.1" ]
then
	NAME="5.1 - SCREAM HyperLogLog [HLL Cardinality Sketch]"
	FOLDER=$THIS_DIR/demos/5-scream/5.1-hyperloglog
	P4_INPUT=$FOLDER/p4src/scream-hll.p4
	JSON_OUTPUT=$FOLDER/p4src/scream-hll.json
elif [ $DEMO = "6" ]
then
	NAME="6 - NetSight"
	FOLDER=$THIS_DIR/demos/6-netsight
	P4_INPUT=$FOLDER/p4src/netsight.p4
	JSON_OUTPUT=$FOLDER/p4src/netsight.json
	DEBUG_FILE="--debug_file "$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "7" ]
then
	NAME="7 - VeriDP"
	FOLDER=$THIS_DIR/demos/7-veridp
	P4_INPUT=$FOLDER/p4src/veridp.p4
	JSON_OUTPUT=$FOLDER/p4src/veridp.json
	DEBUG_FILE="--debug_file "$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "8.1" ]
then
	NAME="8.1 - UnivMon CountSketch"
	FOLDER=$THIS_DIR/demos/8-univmon/8.1-count_sketch
	P4_INPUT=$FOLDER/p4src/univmon.p4
	JSON_OUTPUT=$FOLDER/p4src/univmon.json
	DEBUG_FILE="--debug_file "$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "0.1" ]
then
	NAME="0.1 - MAFIA HH"
	FOLDER=$THIS_DIR/demos/0-mafia/0.1-heavy_hitters
	P4_INPUT=$FOLDER/p4src/mafia-hh.p4
	JSON_OUTPUT=$FOLDER/p4src/mafia-hh.json
	DEBUG_FILE="--debug_file "$FOLDER/p4dbg-cmd.txt
elif [ $DEMO = "0.6" ]
then
	NAME="0.6 - MAFIA TM"
	FOLDER=$THIS_DIR/demos/0-mafia/0.6-tm
	P4_INPUT=$FOLDER/p4src/mafia-tm.p4
	JSON_OUTPUT=$FOLDER/p4src/mafia-tm.json
	DEBUG_FILE=$FOLDER/p4dbg-cmd.txt
else
	echo "Error: Unknown demo identifier $DEMO"
	py/sdm.py --list_demos -d 0
	exit
fi

COMMANDS=$FOLDER/commands.txt