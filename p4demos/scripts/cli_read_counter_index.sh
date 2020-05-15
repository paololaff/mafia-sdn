#!/bin/bash

if [ $# -lt 5 ]
then
	echo "Usage: $0 cli_path thrift-port json counter_name counter_index"
	exit -1
fi

CLI=$1
JSON=$2
THRIFT_PORT=$3
P4_COUNTER_NAME=$4
P4_COUNTER_INDEX=$5

echo "counter_read $P4_COUNTER_NAME $P4_COUNTER_INDEX" | $CLI $JSON $THRIFT_PORT
