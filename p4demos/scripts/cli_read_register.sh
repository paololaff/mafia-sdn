#!/bin/bash

if [ $# -lt 4 ]
then
	echo "Usage: $0 cli_path json thrift-port register_name"
	exit -1
fi

CLI=$1
JSON=$2
THRIFT_PORT=$3
P4_REGISTER_NAME=$4

echo "register_read $P4_REGISTER_NAME" | $CLI $JSON $THRIFT_PORT
