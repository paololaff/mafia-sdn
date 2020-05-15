#!/usr/bin/python
""" Implementation of an SDM demo """

import logging
import subprocess
from ini import IniWrapper
from p4state import *
from p4cli import P4CLI
import mytime as mytime

class P4(object):
    """ P4 Wrapper """
    def __init__(self, install_dir, bmv2_dir, p4c_bm_dir, p4c_bm_script, targets_dir, target_exe, target_cli, loglevel):
        self.install_dir    = install_dir
        self.bmv2_dir       = bmv2_dir
        self.p4c_bm_dir     = p4c_bm_dir
        self.p4c_bm_script  = p4c_bm_script
        self.targets_dir    = targets_dir
        self.target_exe     = target_exe
        self.target_cli     = target_cli
        self.loglevel       = loglevel


class SDMdemo(object):
    """ Implements an SDM demo """
    def __init__(self, p4, code, name, filename, path, thrift_port, description, primitives, timer_ms):
        self.p4          = p4
        self.code        = code
        self.name        = name
        self.filename    = filename
        self.path        = path
        self.thrift_port = thrift_port
        self.description = description
        self.primitives  = primitives.split(',')
        self.timer_ms    = timer_ms
        self.t           = mytime.get_time_milliseconds()
        self.stop        = False

        # logging.basicConfig(level=p4.loglevel, format='%(name)-25s - %(levelname)-8s - %(message)s')
        self.logger      = logging.getLogger(__name__)

        # self.p4_in       = 'demos/' + self.path + '/p4src/' + self.filename + '.p4'
        # self.json_out    = 'demos/' + self.path + '/p4src/' + self.filename + '.json'
        self.p4_in       = self.path + '/' + self.filename + '.p4'
        self.json_out    = self.path + '/' + self.filename + '.json'
        self.cli         = P4CLI(self.p4, p4.target_cli, self.json_out, self.thrift_port)
        self.states      = []
        self.actions     = []
        # self.compile()
        self.load_demo_state()
        # self.load_demo_actions()

    def initialize_p4_state(self, ini, p4state):
        """ Reads the attribute of the P4State object """
        p4state_type     =     ini.get_key_value(p4state, 'type')
        p4state_timer_ms = int(ini.get_key_value(p4state, 'timer_ms'))
        p4state_size_n   = int(ini.get_key_value(p4state, 'size_n'))
        p4state_size_m   = int(ini.get_key_value(p4state, 'size_m'))
        if p4state_type == 'counter'  : return P4Counter (self.p4, self.cli, p4state, p4state_size_n, p4state_size_m, p4state_timer_ms)
        if p4state_type == 'register' : return P4Register(self.p4, self.cli, p4state, p4state_size_n, p4state_size_m, p4state_timer_ms)
        if p4state_type == 'bitmap'   : return P4Bitmap  (self.p4, self.cli, p4state, p4state_size_n, p4state_size_m, p4state_timer_ms)
        if p4state_type == 'sketch'   : return P4Sketch  (self.p4, self.cli, p4state, p4state_size_n, p4state_size_m, p4state_timer_ms)


    def load_demo_state(self):
        """ Loads the p4 switch state associated with the demo  """
        ini = IniWrapper(self.path + '/p4-state.ini')
        state_list = ini.get_section_list()
        for state in state_list:
            self.states.append(self.initialize_p4_state(ini, state))
        # print(self.states)


    # def load_demo_actions(self):
    #     """ Loads the p4 actions associated with the demo  """
    #     ini = IniWrapper(self.path + '/p4-actions.ini')
    #     self.actions = ini.get_section_list()
    #     # print(self.actions)

    def compile(self):
        """ Compiles the p4 demo  """
        # $P4C_BM_SCRIPT p4src/devoflow.p4 --json devoflow.json
        self.logger.info("Compiling SDMdemo %s - %s [%s ---> %s]", self.code, self.name, self.filename + '.p4', self.filename + '.json')

        try:
            output = subprocess.check_output([self.p4.p4c_bm_script, self.p4_in, '--json', self.json_out])
            print output
        except subprocess.CalledProcessError as e:
            print e
            print e.output

    def run(self):
        """ Runs the p4 demo  """
        # self.monitor = P4StateMonitor(self.states)
        while(not self.stop):
            # for state in self.states:
            #     now_ms = mytime.get_time_milliseconds()
            #     if (now_ms - state.time > state.timer_ms):
            #         state.read()
            #         state.time = mytime.get_time_milliseconds()
            # self.logger.info("")
            now_ms = mytime.get_time_milliseconds()
            if (now_ms - self.t > self.timer_ms):
                for state in self.states:
                    state.read()
                self.t = mytime.get_time_milliseconds()
                self.logger.info("")





