#!/usr/bin/python
""" Module for INI file management """

import configparser
import tempfile

# def load_ini_file(file_name):
#     """Reads an ini file and returns a configparser object"""
#     tmp = open(file_name)
#     tmpcontent = tmp.read().decode("utf-8-sig").encode("utf-8")
#     tmp.close()
#     fp = tempfile.TemporaryFile()
#     fp.write(tmpcontent)
#     fp.seek(0)
#     ini = configparser.ConfigParser()
#     ini.readfp(fp)
#     fp.close()
#     return ini

class IniWrapper(object):
    """Wrapper to configparser"""

    def __init__(self, filename):
        self.filename = filename
        self.fp = None
        # self.tmp = None
        # self.tmpcontent = None
        self.ini = configparser.ConfigParser()
        self.load_file()

    def __del__(self):
        self.fp.close()

    def load_file(self):
        """Loads the ini file content for the configparser"""
        tmp = open(self.filename)
        tmpcontent = tmp.read().decode("utf-8-sig").encode("utf-8")
        tmp.close()
        # self.tmp = open(self.filename)
        # self.tmpcontent = self.tmp.read().decode("utf-8-sig").encode("utf-8")
        # self.tmp.close()
        self.fp = tempfile.TemporaryFile()
        self.fp.write(tmpcontent)
        self.fp.seek(0)
        self.ini.readfp(self.fp)

    def get_section_list(self):
        """Get the list of sections defined in the ini file"""
        return self.ini.sections()

    def get_key_value(self, section, key):
        """Get the list of sections defined in the ini file"""
        return self.ini[section][key].strip()

