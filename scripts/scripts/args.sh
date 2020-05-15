
#!/bin/bash -x

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "$0 - Executes a MAFIA program"
                        echo " "
                        echo "Options:"
                        echo "-h, --help                Show help"
                        echo "-u, --measurement         Specify the measurement to run"
                        echo "-c, --compile             Specify the measurement should be pre-compiled with the MAFIA prototype compiler"
                        echo "-m, --mininet             Executes the measurement in the Mininet emulator"
                        echo "-t, --thrift port         Specify the Thrift port"
                        echo "-d, --debug               Run the P4 switch debugger"
                        exit 0
                        ;;
                -u|--measurement)
                        shift
                        if test $# -gt 0; then
                                export FOLDER=$1
                                export MEASUREMENT=$(basename $1)
                                # Set up demo-specific configuration files
                                export P4_INPUT=$FOLDER$MEASUREMENT".p4"
                                export JSON_OUTPUT=$FOLDER$MEASUREMENT".json"
                                export DEBUG_FILE=$FOLDER"p4dbg-cmd.txt"
                                export COMMANDS=$FOLDER"commands.txt"
                        else
                                echo "Option -u|--measurement requires a value."
                                exit 1
                        fi
                        shift
                        ;;
                -t|--thrift)
                        shift
                        if test $# -gt 0; then
                                export THRIFT_PORT=$1
                        else
                                echo "Option -t|--thrift requires a value."
                                exit 1
                        fi
                        shift
                        ;;
                -c|--compile)
                        export COMPILE_WITH_MAFIA=1
                        # echo "Option -c|--compile is enabled."
                        shift
                        ;;
                -m|--mininet)
                        export MININET=1
                        # echo "Option -m|--mininet is enabled."
                        shift
                        ;;
                -d|--debug)
                        export DEBUG_FLAG=1
                        # echo "Option -d|--debug is enabled."
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done