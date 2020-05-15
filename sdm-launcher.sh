#!/bin/bash -x

MININET=0
DEBUG_FLAG=0
THRIFT_PORT=9999

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SCRIPT_DIR=$THIS_DIR/scripts/scripts
PY_DIR=$THIS_DIR/scripts/py

source $SCRIPT_DIR/args.sh # Argument handler
source $THIS_DIR/p4-env.sh # P4 installation config

if [[ ! -v MEASUREMENT ]]
then 
	echo "Please specify a measurement to run"
	echo "Help: $0 -h|--help"
	exit
fi

if [[ -v COMPILE_WITH_MAFIA ]]
then 
	echo "Compiling measurement $MEASUREMENT with the MAFIA prototype compiler"
	cd ./mafia_p4c && python3 mafia-p4c.py --measurement $MEASUREMENT >/dev/null && cd -
fi

if [ ! -e $P4_INPUT -o ! -e $COMMANDS ] # -o ! -e $DEBUG_FILE
then
	echo "Error: Invalid measurement $MEASUREMENT"
	exit
fi

$P4C_BM $P4_INPUT --json $JSON_OUTPUT 	# Compile the measurement with the default p4 compiler

if [ ! -e $JSON_OUTPUT ]
then
	echo "Error: .json output file for $MEASUREMENT not found. Check for compilation errors"
	exit
fi

ARGS="$BMV2_PATH $SWITCH_EXE $CLI_EXE $THRIFT_PORT $JSON_OUTPUT $COMMANDS"

sudo ./cleanup >/dev/null 2>&1
sleep 1
sudo ./$SCRIPT_DIR/setup_veth.sh >/dev/null 2>&1
sleep 1

if [ $MININET -eq 0 ]; then EMULATOR="$SCRIPT_DIR/run_switch.sh"; else EMULATOR="$SCRIPT_DIR/run_mininet.sh"; fi

CMD_TITLE="source $SCRIPT_DIR/terminal-title.sh; set-title"
CMD_ENV="sudo $EMULATOR $ARGS"
CMD_CTRL="sudo $PY_DIR/sdm.py --demo $FOLDER --thrift $THRIFT_PORT"
CMD_DBG="sudo $DBG_EXE --thrift-port $THRIFT_PORT --debug-file $DEBUG_FILE"

# Launch the terminals
# gnome-terminal --geometry=100x640+0+0       --working-directory=${THIS_DIR}  -e "${CMD_ENV}" 	  --title="Doesnt work"
# gnome-terminal --geometry=120x1080+900+0    --working-directory=${THIS_DIR}  -e "${CMD_CTRL}" 	  --title="Doesnt work"
gnome-terminal --geometry=75x640+0+0       --working-directory=${THIS_DIR}  -e "bash -c \"$CMD_TITLE simple_switch; ${CMD_ENV}; exec bash\"" 	  --title="Doesnt work"
gnome-terminal --geometry=150x1080+850+0    --working-directory=${THIS_DIR}  -e "bash -c \"$CMD_TITLE $DEMO; ${CMD_CTRL}; exec bash\"" 	  --title="Doesnt work"

sleep 2
if [ $DEBUG_FLAG -eq 1 ]
then
	gnome-terminal --geometry=80x1080+450+0    --working-directory=${THIS_DIR}  -e "bash -c \"${CMD_DBG}; exec bash\"" --title="p4dbg"
fi

