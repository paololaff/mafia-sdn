#!/usr/bin/python

# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from mininet.net import Mininet
from mininet.topo import Topo
from mininet.log import setLogLevel
from mininet.cli import CLI
from mininet.link import Intf

from p4_mininet import P4Switch, P4Host

import argparse
from time import sleep
import os
import subprocess

_THIS_DIR = os.path.dirname(os.path.realpath(__file__))
_THRIFT_BASE_PORT = 22222

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--json', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--cli', help='Path to BM CLI',
                    type=str, action="store", required=True)
parser.add_argument('--thrift', help='Thrift port',
                    type=int, action="store", required=True)
parser.add_argument('--commands', help='Path to commands.txt file',
                    type=str, action="store", required=True)

args = parser.parse_args()

class MyTopo(Topo):
    def __init__(self, sw_path, json_path, nb_hosts, nb_switches, links, thrift_port, **opts):
        # Initialize topology and default options
        Topo.__init__(self, **opts)

        for i in xrange(nb_switches):
           self.addSwitch('s%d' % (i + 1),
                            sw_path = sw_path,
                            # mac="AA:00:00:00:00:0%d" % (i+1),
                            # ifs = "-i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8",
                            # ifs = "-i 0@veth" + str(10*i + 0) + " -i 1@veth" + str(10*i + 2) + " -i 2@veth" + str(10*i + 4) + " -i 3@veth" + str(10*i + 6) + " -i 4@veth" + str(10*i + 8) + "",
                            # ifs = "-i " + (10*i + 0) + "@veth" + (10*i + 0) + \
                            #       " -i " + (10*i + 1) + "@veth" + (10*i + 2) + \
                            #       " -i " + (10*i + 2) + "@veth" + (10*i + 4) + \
                            #       " -i " + (10*i + 3) + "@veth" + (10*i + 6) + \
                            #       " -i " + (10*i + 4) + "@veth" + (10*i + 8) + "",
                            json_path = json_path,
                            thrift_port = thrift_port + i,
                            pcap_dump = True,
                            enable_debugger = True,
                            device_id = i)

        for h in xrange(nb_hosts):
            self.addHost('h%d' % (h + 1), ip="10.0.0.%d" % (h + 1),
                    mac="00:00:00:00:00:0%d" % (h+1))

        for a, b in links:
            self.addLink(a, b)

def read_topo():
    nb_hosts = 0
    nb_switches = 0
    links = []
    with open("scripts/py/topology.txt", "r") as f:
        line = f.readline()[:-1]
        w, nb_switches = line.split()
        assert(w == "switches")
        line = f.readline()[:-1]
        w, nb_hosts = line.split()
        assert(w == "hosts")
        for line in f:
            if not f: break
            a, b = line.split()
            links.append( (a, b) )
    return int(nb_hosts), int(nb_switches), links


def main():
    nb_hosts, nb_switches, links = read_topo()

    topo = MyTopo(args.behavioral_exe,
                  args.json,
                  nb_hosts, nb_switches, links, args.thrift)

    net = Mininet(topo = topo,
                  host = P4Host,
                  switch = P4Switch,
                  controller = None )
    
    # cpu_intf = Intf("cpu-veth-1", net.get('s1'), 4)
    
    net.start()

    for n in xrange(nb_hosts):
        h = net.get('h%d' % (n + 1))
        for off in ["rx", "tx", "sg"]:
            cmd = "/sbin/ethtool --offload eth0 %s off" % off
            print cmd
            h.cmd(cmd)
        print "disable ipv6"
        h.cmd("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
        h.cmd("sysctl -w net.ipv6.conf.default.disable_ipv6=1")
        h.cmd("sysctl -w net.ipv6.conf.lo.disable_ipv6=1")

        print "Setting ARP table for host h"+str(n+1)
        for m in xrange(nb_hosts):
            if(m != n):
                print "h"+str(m+1)
                print "     00:00:00:00:00:0"+str(m + 1)
                print "     10.0.0."+str(m + 1)
                h.setARP("10.0.0."+str(m + 1), "00:00:00:00:00:0"+str(m + 1))

        # h.cmd("sysctl -w net.ipv4.tcp_congestion_control=reno")
        # h.cmd("iptables -I OUTPUT -p icmp --icmp-type destination-unreachable -j DROP")

    sleep(5)

    for i in xrange(nb_switches):
        #cmd = [args.cli, "--json", args.json,
               #"--thrift-port", str(_THRIFT_BASE_PORT + i)]
        cmd = [args.cli, args.json, str(args.thrift + i)]
        with open(args.commands, "r") as f:
            print " ".join(cmd)
            try:
                output = subprocess.check_output(cmd, stdin = f)
                print output
            except subprocess.CalledProcessError as e:
                print e
                print e.output

    sleep(1)

    print "Ready !"

    CLI( net )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    main()
