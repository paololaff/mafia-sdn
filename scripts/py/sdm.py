#!/usr/bin/python

import os
import sys
import signal
import argparse
import logging
from functools import partial
from ini import IniWrapper
from sdm_demo import P4, SDMdemo

_LOG_LEVEL_STRINGS = ['CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG']

def sigint_handler(signum, frame, demo):
    """ Handler to CTRL+C """
    demo.stop = True
    sys.exit(0)

def _log_level(log_level_string):
    if not log_level_string in _LOG_LEVEL_STRINGS:
        message = 'Invalid log level: {0} (Available: {1})'.format(log_level_string, _LOG_LEVEL_STRINGS)
        raise argparse.ArgumentTypeError(message)

    log_level_int = getattr(logging, log_level_string, logging.INFO)
    # check the logging log_level_choices have not changed from our expected values
    assert isinstance(log_level_int, int)
    return log_level_int

def sdm_demos_lookup(demo, ini):
    """ Finds the selected SDM Demo """
    selected = None
    demos_list = ini.get_section_list()
    if demo not in demos_list:
        for d in demos_list:
            demo_code = ini.get_key_value(d, 'id')
            if demo_code == demo:
                selected = d
    else:
        selected = demo

    return selected

def sdm_demos_available(ini_file):
    """ Returns a string listing available SDM Demos """
    ini = IniWrapper(ini_file)
    demos = ""
    demos_list = ini.get_section_list()
    for demo in demos_list:
        tmp = "%3s - %-32s -----> %s (%s)" % (ini.get_key_value(demo, 'id'), demo, ini.get_key_value(demo, 'description'), ini.get_key_value(demo, 'primitives'))
        demos += tmp + os.linesep
    return demos

def sdm_demos_available_print(ini_file):
    """ Prints available SDM Demos """
    demos = sdm_demos_available(ini_file)
    print('Available SDM Demos:')
    print(demos)

parser = argparse.ArgumentParser(description="SDM primitives with P4")
parser.add_argument('--demo',        '-u', type=str, help='Name or ID of the p4 demo to run',                      required=True)
parser.add_argument('--config',      '-c', type=str, help='path to ini file containing p4 configuration',          required=False, default='p4-env.ini')
parser.add_argument('--thrift',      '-p', type=str, help='Thrift port to connect',                                required=False, default='22222')
parser.add_argument('--timer',       '-m', type=int, help='Demo state print timer, in ms',                         required=False, default=2500)
parser.add_argument('--target',      '-t', type=str, help='Name of the p4 bm target to run')
parser.add_argument('--log',         '-l', type=_log_level, help='Loogging level. {0}'.format(_LOG_LEVEL_STRINGS), required=False, default='INFO', dest='loglevel', nargs='?')
# parser.add_argument('--list_demos',                  help='Prints available SDM demos',                            required=False, action='store_true')

args = parser.parse_args()

# if(args.list_demos):
#     sdm_demos_available_print('demos/sdm_demos.ini')
#     exit(0)

# logging.basicConfig(level=p4.loglevel,
        #                     format='%(name)s: '    
        #                             '%(levelname)s: '
        #                             '%(funcName)s(): '
        #                             '%(lineno)d:\t'
        #                             '%(message)s')

logging.basicConfig(level=args.loglevel, format='%(name)-12s: Line %(lineno)-4d - %(levelname)-8s - %(message)s')
logger = logging.getLogger(__name__)

# handler = logging.FileHandler('demo.log')
# handler.setLevel(args.log_level)
# formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
# handler.setFormatter(formatter)
# logger.addHandler(handler)

p4_install_dir  = None      # P4 Installation directory
bmv2_dir        = None      # Behavioral Model directory
p4c_bm_dir      = None      # P4C Compiler directory
targets_dir     = None      # P4 targets directory
target_default  = None      # Name of the default P4 switch target
target          = None      # Name of the selected P4 switch target
target_exe      = None      # Path to the executable of the selected P4 switch target
target_cli      = None      # Path to the executable of the selected P4 switch target's CLI
p4_demo         = args.demo # Selected demo

# P4 parameter initialization
p4_ini = IniWrapper(args.config)

p4_install_dir  =                  p4_ini.get_key_value('p4', 'install_dir')
bmv2_dir        = p4_install_dir + p4_ini.get_key_value('p4', 'bmv2_path')
p4c_bm_dir      = p4_install_dir + p4_ini.get_key_value('p4', 'p4c_bm_path')
p4c_bm_script   = p4c_bm_dir     + p4_ini.get_key_value('p4', 'p4c_bm_script')
targets_dir     = p4_install_dir + p4_ini.get_key_value('p4', 'targets_path')
default_target  =                  p4_ini.get_key_value('p4', 'default_target')

p4_target_list = p4_ini.get_section_list()
p4_target_list.remove('p4')

target = default_target if (args.target is None) else args.target
if target not in p4_target_list:
    print "Error: Unknown P4 switch target %s" % (target)
    exit(1)

target_exe = targets_dir + p4_ini.get_key_value(target, 'exe')
target_cli = targets_dir + p4_ini.get_key_value(target, 'cli')

logger.debug(" %-15s: %s", "p4_install_dir", p4_install_dir)
logger.debug(" %-15s: %s", "bmv2_dir", bmv2_dir)
logger.debug(" %-15s: %s", "p4c_bm_dir", p4c_bm_dir)
logger.debug(" %-15s: %s", "p4c_bm_script", p4c_bm_script)
logger.debug(" %-15s: %s", "target", target)
logger.debug(" %-15s: %s", "target_exe", target_exe)
logger.debug(" %-15s: %s", "target_cli", target_cli)
logger.debug(" %-15s: %s", "targets_dir", targets_dir)

p4 = P4(p4_install_dir, bmv2_dir, p4c_bm_dir, p4c_bm_script, targets_dir, target_exe, target_cli, args.loglevel)


# SDM Demo initialization
# demo_ini = IniWrapper('demos/sdm_demos.ini')
# demo_name = sdm_demos_lookup(p4_demo, demo_ini)

# if(demo_name is None):
#     logger.critical(" Unknown demo selected: %s ", p4_demo)
#     sdm_demos_available_print('demos/sdm_demos.ini')
#     exit(1)

# demo_id         = demo_ini.get_key_value(demo_name, 'id')
# demo_path       = demo_ini.get_key_value(demo_name, 'path')
# demo_filename   = demo_ini.get_key_value(demo_name, 'filename')
# demo_descr      = demo_ini.get_key_value(demo_name, 'description')
# demo_primitives = demo_ini.get_key_value(demo_name, 'primitives')

demo_path       = args.demo
demo_name       = os.path.basename(args.demo)
demo_filename   = os.path.basename(args.demo)

# logger.debug(" %-15s: %s", "demo_id", demo_id)
logger.debug(" %-15s: %s", "demo_path", demo_path)
logger.debug(" %-15s: %s", "demo_filename", demo_filename)
# logger.debug(" %-15s: %s", "demo_descr", demo_descr)
# logger.debug(" %-15s: %s", "demo_primitives", demo_primitives)

# sdm_demo = SDMdemo(p4, demo_id, demo_name, demo_filename, demo_path, args.thrift , demo_descr, demo_primitives, args.timer)
sdm_demo = SDMdemo(p4, 0, demo_name, demo_filename, demo_path, args.thrift , "", "", args.timer)
signal.signal(signal.SIGINT, partial(sigint_handler, demo=sdm_demo))

sdm_demo.run()











