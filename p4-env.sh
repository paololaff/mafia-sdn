THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# ---------------- EDIT THIS ------------------
BMV2_PATH=$THIS_DIR/../behavioral-model
# e.g. BMV2_PATH=$THIS_DIR/../bmv2
P4C_BM_PATH=$THIS_DIR/../p4c-bmv2
# e.g P4C_BM_PATH=$THIS_DIR/../p4c-bm
# ---------------- END ------------------

# Shouldn't require modifications:
P4C_BM=$P4C_BM_PATH/p4c_bm/__main__.py
#CLI_EXE=$BMV2_PATH/tools/runtime_CLI.py
CLI_EXE=$BMV2_PATH/targets/simple_switch/sswitch_CLI
SWITCH_EXE=$BMV2_PATH/targets/simple_switch/simple_switch
DBG_EXE=$BMV2_PATH/tools/p4dbg.py
