#!/bin/bash

if [ $# -lt 5 ]
then
	echo "Usage: $0 cli_path thrift-port json register_name register_index"
	exit -1
fi

CLI=$1
JSON=$2
THRIFT_PORT=$3
P4_REGISTER_NAME=$4
P4_REGISTER_INDEX=$5

echo "register_read $P4_REGISTER_NAME $P4_REGISTER_INDEX" | $CLI $JSON $THRIFT_PORT
