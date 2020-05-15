#!/bin/bash -x

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ $# -lt 6 ]
then
    echo "Usage: $0 bmv2-path switch-exe cli-exe thrift-port json-file commands-file"
    exit 1
fi

BMV2_PATH=$1
SWITCH_EXE=$2
CLI_EXE=$3
THRIFT_PORT=$4
JSON=$5
COMMANDS=$6

set -m
# This gets root permissions, and gives libtool the opportunity to "warm-up"
sudo $SWITCH_EXE >/dev/null 2>&1
sudo $SWITCH_EXE $JSON \
    -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 \
    --nanolog ipc:///tmp/bm-0-log.ipc \
    --thrift-port $THRIFT_PORT --debugger &
    # --pcap &
sleep 2
$CLI_EXE $JSON $THRIFT_PORT < $COMMANDS
echo "Switch Ready !!!"
fg
exec bash