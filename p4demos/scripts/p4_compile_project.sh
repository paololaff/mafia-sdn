#!/bin/bash

if [ $# -lt 1 ]
then
    echo "Usage: $0 project_file"
fi

FILE=$1
echo $2
DIRECTORY_FULL=`dirname "$FILE"`
DIRECTORY_NAME="$(basename "$(dirname "$FILE")")"

if [ $DIRECTORY_NAME != "p4src" ] 
then
    # while [ $DIRECTORY_NAME != "p4src" ]
    # do        
        DIRECTORY_PARENT=`dirname "$DIRECTORY_FULL"`
        DIRECTORY_NAME="$(basename "$(dirname "$DIRECTORY_FULL")")"
        P4_MAIN="$(ls $DIRECTORY_PARENT | grep ".p4")"
        FILE=$DIRECTORY_PARENT"/"$P4_MAIN
    # done
fi

FILENAME=`basename "$FILE"`
FILENAME_NO_EXT=$(echo $FILENAME | cut -f 1 -d '.')
DIRECTORY_FULL=`dirname "$FILE"`

P4_INPUT=$DIRECTORY_FULL"/"$FILENAME_NO_EXT".p4"
JSON_OUTPUT=$DIRECTORY_FULL"/"$FILENAME_NO_EXT".json"

echo "P4: Compiling project $P4_INPUT"
~/p4/p4c-bmv2/p4c_bm/__main__.py $P4_INPUT --json $JSON_OUTPUT
