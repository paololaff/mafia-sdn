#!/usr/bin/python
""" Abstraction of P4 state """

import logging
import mytime as mytime

class P4State(object):
    """ Abstraction of P4 state """
    def __init__(self, p4, name, n, m, timer_ms):
        self.p4 = p4
        self.name = name
        self.n    = n
        self.m    = m
        self.timer_ms = timer_ms
        # self.display = display
        self.values = [0]*(self.n * self.m)
        self.time = mytime.get_time_milliseconds()
        # logging.basicConfig(level=p4.loglevel, format='%(name)-25s - %(levelname)-8s - %(message)s')
        self.logger = logging.getLogger(__name__)

    def read(self):
        """ Reads the P4 state """
        self.logger.error("%s - P4State:read not implemented", self.name)
    def read_index(self, index):
        """ Reads the P4 state at index """
        self.logger.error("%s - P4State:read_index not implemented", self.name)

    def write(self, value):
        """ Writes the P4 state """
        self.logger.error("%s - P4State:write not implemented", self.name)

    def write_index(self, index, value):
        """ Writes the P4 state at index """
        self.logger.error("%s - P4State:write_index not implemented", self.name)

    def display(self, index = None):
        """ Prints the P4 state """
        self.logger.error("%s - P4State:display not implemented", self.name)



class P4Counter(P4State):
    """ Abstraction of a P4 Counter """
    def __init__(self, p4, cli, name, n, m, timer_ms):
        super(P4Counter, self).__init__(p4, name, n, m, timer_ms)
        self.cli = cli

    def read(self):
        """ Reads the P4 Counter """
        self.logger.debug("counter_read %s", self.name)
        for i in range(0, self.n * self.m):
            result = self.cli.counter_read_index(self.name, str(i))
            if result is not None:
                self.values[i] = int(result.strip())
                self.display()
        # result = self.cli.counter_read(self.name)
        # if result is not None:
        #     result = result.split(',')
        #     for i in range(0, len(result)):
        #         self.values[i] = int(result[i].strip())
        # self.logger.info("%s[%s]: %s", self.name, str(index), result)
        # if result is not None: self.logger.info("%s: %s", self.name, result)

    def read_index(self, index):
        """ Reads the P4 Counter at index """
        self.logger.debug("counter_read_index %s %s", self.name, index)
        result = self.cli.execute(self.name, str(index))
        if result is not None:
            self.values[index] = int(result.strip())
            self.display()
        # self.logger.info("%s[%s]: %s", self.name, str(index), result)
        # if result is not None:
        #     self.logger.info("%s[%s]: %s", self.name, str(index), result)

    def display(self, index = None):
        """ Displays the P4 Counter state """
        if index is not None:
            self.logger.info("%20s[%4d] - %s", self.name, index, self.values[index])
        else:
            if self.n == 1:
                self.logger.info("%-24s: [" + ", ".join("%4d" % v for v in self.values) + "]",self.name)
            else:
                self.logger.info("%-24s: ", self.name)
                for row in range(0, self.n):
                    self.logger.info("%-24s[%3d]: [" + ", ".join("%4d" % v for v in self.values[row*self.m:(row*self.m + self.m)]) + "]", " ", row)

    # def write(self, value):
    #     """ Writes the P4 Counter """
    #     print "P4Counter:write not implemented"

    # def write_index(self, index, value):
    #     """ Writes the P4 Counter at index """
    #     print "P4Counter:write_index not implemented"

class P4Register(P4State):
    """ Abstraction of a P4 register """
    def __init__(self, p4, cli, name, n, m, timer_ms):
        super(P4Register, self).__init__(p4, name, n, m, timer_ms)
        self.cli = cli

    def read(self):
        """ Reads the P4 Register """
        self.logger.debug("register_read %s", self.name)
        result = self.cli.register_read(self.name)
        if result is not None:
            result = result.split(',')
            for i in range(0, len(result)):
                self.values[i] = int(result[i].strip())
            self.display()
        # if result is not None: self.logger.info("%s: %s", self.name, result)

    def read_index(self, index):
        """ Reads the P4 state at index """
        self.logger.debug("register_read_index %s %s", self.name, index)
        result = self.cli.register_read_index(self.name, str(index))
        if result is not None:
            self.values[index] = int(result.strip())
            self.display()
        # self.logger.info("%s[%s]: %s", self.name, str(index), result)

    def display(self, index = None):
        """ Displays the P4 Register state """
        if index is not None:
            self.logger.info("%20s[%4d] - %s", self.name, index, self.values[index])
        else:
            if self.n == 1:
                self.logger.info("%-24s: [" + ", ".join("%4d" % v for v in self.values) + " ]",self.name)
            else:
                self.logger.info("%-24s: ", self.name)
                for row in range(0, self.n):
                    self.logger.info("%-23s[%3d]: [" + ", ".join("%4d" % v for v in self.values[row*self.m:(row*self.m + self.m)]) + " ]", " ", row)
        # self.logger.info("")
        
    # def write(self, value):
    #     """ Writes the P4 Register """
    #     if value == 0:
    #         cmd = "register_reset %s" % (self.name)
    #         result = self.cli.execute(cmd)
    #         print("Register reset:")
    #         print(result)
    #     else:
    #         for i in range(0, self.count):
    #             self.write_index(i, value)

    # def write_index(self, index, value):
    #     """ Writes the P4 Register at index """
    #     cmd = "register_write %s %s %s" % (self.name, index, value)
    #     result = self.cli.execute(cmd)
    #     print("%s:" % (cmd))
    #     print(result)

class P4Bitmap(P4State):
    """ Abstraction of a P4 Bitmap """
    def __init__(self, p4, cli, name, n, m, timer_ms):
        super(P4Bitmap, self).__init__(p4, name, n, m, timer_ms)
        self.cli = cli

    def read(self):
        """ Reads the P4 Bitmap """
        self.logger.debug("register_read %s", self.name)
        result = self.cli.register_read(self.name)
        if result is not None:
            result = result.split(',')
            for i in range(0, len(result)):
                self.values[i] = int(result[i].strip())
            self.display()

    def read_index(self, index):
        """ Reads the P4 Bitmap at index """
        self.logger.error("%s - P4Bitmap:read_index not implemented", self.name)

    def display(self, index = None):
        """ Displays the P4 Bitmap state """
        if index is not None:
            self.logger.info("%20s[%4d] - %s", self.name, index, self.values[index])
        else:
            if self.n == 1:
                self.logger.info("%-24s: [" + "".join("%1s" % str(v) for v in self.values) + "]",self.name)
            else:
                self.logger.info("%-24s: ", self.name)
                for row in range(0, self.n):
                    self.logger.info("%-23s[%2d]: [" + "".join("%1s" % (str(v) if v==1 else " ") for v in self.values[row*self.m:(row*self.m + self.m)]) + "]", " ", row)

class P4Sketch(P4State):
    """ Abstraction of a P4 Sketch """
    def __init__(self, p4, cli, name, n, m, timer_ms):
        super(P4Sketch, self).__init__(p4, name, n, m, timer_ms)
        self.cli = cli

    def read(self):
        """ Reads the P4 Sketch """
        self.logger.debug("register_read %s", self.name)
        result = self.cli.register_read(self.name)
        if result is not None:
            result = result.split(',')
            for i in range(0, len(result)):
                self.values[i] = int(result[i].strip())
            self.display()

    def read_index(self, index):
        """ Reads the P4 Sketch at index """
        self.logger.error("%s - P4Sketch:read_index not implemented", self.name)

    def display(self, index = None):
        """ Displays the P4 Sketch state """
        if index is not None:
            self.logger.info("%20s[%4d] - %s", self.name, index, self.values[index])
        else:
            if self.n == 1:
                self.logger.info("%-24s: [" + "".join("%4d" % v for v in self.values) + "]",self.name)
            else:
                self.logger.info("%-24s: ", self.name)
                for row in range(0, self.n):
                    self.logger.info("%-23s[%2d]: [" + "".join(" %4d " % v for v in self.values[row*self.m:(row*self.m + self.m)]) + "]", " ", row)

