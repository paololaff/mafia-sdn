#!/usr/bin/python
""" Wrapper of a P4 switch CLI """

import re
import logging
import subprocess

class P4CLI(object):
    """ Abstracts a P4 CLI """
    def __init__(self, p4, path, json, thrift_port):
        self.p4 = p4
        self.path = path
        self.json = json
        self.thrift_port = thrift_port
        # logging.basicConfig(level=p4.loglevel, format='%(name)-25s - %(levelname)-8s - %(message)s')
        self.logger = logging.getLogger(__name__)

    def register_read(self, register):
        """ Executes a CLI command """
        output = ""
        result = None
        # self.logger.debug('CLI executing command: \"cli_read_register.sh %s %s %s %s\"', self.path, self.json, self.thrift_port, register)
        try:
            output = subprocess.check_output(['./scripts/scripts/cli_read_register.sh', self.path, self.json, self.thrift_port, register])
            result = self.parse_cli_output(output, "register_read", register, None)
        except subprocess.CalledProcessError as e:
            result = self.parse_cli_output(e.output, "register_read", register, None)
        return result

    def register_read_index(self, register, index):
        """ Executes a CLI command """
        output = ""
        result = None
        # self.logger.debug('CLI executing command: \"cli_read_register_index.sh %s %s %s %s %s\"', self.path, self.json, self.thrift_port, register, index)
        try:
            output = subprocess.check_output(['./scripts/scripts/cli_read_register_index.sh', self.path, self.json, self.thrift_port, register, index])
            result = self.parse_cli_output(output, "register_read_index", register, index)
        except subprocess.CalledProcessError as e:
            result = self.parse_cli_output(e.output, "register_read_index", register, index)
        return result

    def counter_read(self, counter):
        """ Executes a CLI command """
        output = None
        result = None
        # self.logger.debug('CLI executing command: \"cli_read_counter.sh %s %s %s %s\"', self.path, self.json, self.thrift_port, counter)
        try:
            output = subprocess.check_output(['./scripts/scripts/cli_read_counter.sh', self.path, self.json, self.thrift_port, counter])
            result = self.parse_cli_output(output, "counter_read", counter, None)
        except subprocess.CalledProcessError as e:
            result = self.parse_cli_output(e.output, "counter_read", counter, None)
        return result

    def counter_read_index(self, counter, index):
        """ Executes a CLI command """
        output = ""
        result = None
        # self.logger.debug('CLI executing command: \"cli_read_counter_index.sh %s %s %s %s %s\"', self.path, self.json, self.thrift_port, counter, index)
        try:
            output = subprocess.check_output(['./scripts/scripts/cli_read_counter_index.sh', self.path, self.json, self.thrift_port, counter, index])
            result = self.parse_cli_output(output, "counter_read_index", counter, index)
        except subprocess.CalledProcessError as e:
            result = self.parse_cli_output(e.output, "counter_read_index", counter, index)
        return result

    def parse_cli_output(self, output, operation, name, index):
        """ Parses the output of a CLI command """
        state = None
        regex = None
        error = self.__cli_connection_error(output)
        if(not error):
            if index is not None:
                regex = re.search( r'RuntimeCmd:\s*(' + re.escape(name) + r'\[' + index + r'\])=\s*(\d+)', output, re.M|re.I)
            else:
                regex = re.search( r'RuntimeCmd:\s*(' + re.escape(name) + r')=\s*([\d+,\s]+)', output, re.M|re.I)

            if regex:
                state = regex.group(2)
            else:
                # regex = re.search( r'RuntimeCmd:(\sError:\s|\s)(.*)\((.*)\)\n', output, re.M|re.I)
                regex = re.search( r'RuntimeCmd:(\sError:\s|\s)(.*)\n', output, re.M|re.I)
                if regex:
                    # self.logger.error("CLI Error: %s - %s", regex.group(2), regex.group(3))
                    self.logger.error("CLI Error [%s %s]: %s", operation, name, regex.group(2))
        return state

    def __cli_connection_error(self, output):
        """ Checks for successful connection to the CLI """
        ret = True
        regex = None
        regex = re.search( r'Using Thrift port ' + re.escape(self.thrift_port) + r'\n', output, re.M|re.I)
        if regex:
            regex = re.search( r'Could not connect to thrift client on port ' + self.thrift_port + r'\n', output, re.M|re.I)
            if(regex):
                self.logger.error("CLI Error: %s", regex.group())
            else:
                regex = re.search( r'Obtaining JSON from switch\.\.\.\nDone', output, re.M|re.I)
                if(regex): ret = False
        else:
            regex = re.search( r'No Thrift port specified, using CLI default\n', output, re.M|re.I)
            if regex:
                regex = re.search( r'Could not connect to thrift client on port 9090\n', output, re.M|re.I)
                if(regex):
                    self.logger.error("CLI Error: %s", regex.group())
                else:
                    regex = re.search( r'Obtaining JSON from switch\.\.\.\nDone', output, re.M|re.I)
                    if(regex): ret = False
            else:
                self.logger.error("__cli_connection_error: Unknown Error")
        return ret
