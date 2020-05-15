#!/bin/bash -x

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ $# < 6 ]
then
    echo "Usage: $0 bmv2-path switch-exe cli-exe thrift-port json commands-file"
fi

BMV2_PATH=$1
SWITCH_EXE=$2
CLI_EXE=$3
THRIFT_PORT=$4
JSON=$5
COMMANDS=$6

sudo $SWITCH_EXE >/dev/null 2>&1
sudo PYTHONPATH=$PYTHONPATH:$BMV2_PATH/mininet/ python scripts/py/topology.py \
    --behavioral-exe $SWITCH_EXE --cli $CLI_EXE --thrift $THRIFT_PORT --json $JSON --commands $COMMANDS
