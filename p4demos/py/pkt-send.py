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

from scapy.all import Ether, IP, sendp, get_if_hwaddr, get_if_list, TCP, Raw
import sys
import argparse
import random, string, time

def randomword(max_length):
    length = random.randint(1, max_length)
    return ''.join(random.choice(string.lowercase) for i in range(length))

def read_topo():
    nb_hosts = 0
    nb_switches = 0
    links = []
    with open("py/topology.txt", "r") as f:
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

def send_random_traffic(dst, n, connections, port, random_port):
    dst_mac = None
    dst_ip = None
    src_mac = [get_if_hwaddr(i) for i in get_if_list() if i == 'eth0']
    if len(src_mac) < 1:
        print ("No interface for output")
        sys.exit(1)
    src_mac = src_mac[0]
    src_ip = None
    if src_mac =="00:00:00:00:00:01":
        src_ip = "10.0.0.1"
    elif src_mac =="00:00:00:00:00:02":
        src_ip = "10.0.0.2"
    elif src_mac =="00:00:00:00:00:03":
        src_ip = "10.0.0.3"
    else:
        print ("Invalid source host")
        sys.exit(1)

    if dst == 'h1':
        dst_mac = "00:00:00:00:00:01"
        dst_ip = "10.0.0.1"
    elif dst == 'h2':
        dst_mac = "00:00:00:00:00:02"
        dst_ip = "10.0.0.2"
    elif dst == 'h3':
        dst_mac = "00:00:00:00:00:03"
        dst_ip = "10.0.0.3"
    else:
        print ("Invalid host to send to")
        sys.exit(1)

    total_pkts = 0

    for c in range(0, connections):
        if(random_port):
            dst_port = random.sample(xrange(80, 65535), 1)
        src_port = random.sample(xrange(80, 65535), 1)
        print "Connection %d: sending %s packets to %s throguh port %s" % (c, n, dst, port)
        for i in range(n):
            data = randomword(100)
            #p = Ether(dst=dst_mac,src=src_mac)/IP(dst=dst_ip,src=src_ip)
            if i == 1:
                # print "Sending SYN"
                #p = p/TCP(dport=port,flags="S")
                a = Ether(dst=dst_mac,src=src_mac)/IP(dst=dst_ip,src=src_ip)/TCP(sport=src_port,dport=dst_port,flags="S")
                sendp(a, iface = "eth0", verbose=False)
                print a.show()
            else:
                #p = p/TCP(dport=port)/Raw(load=data)
                b = Ether(dst=dst_mac,src=src_mac)/IP(dst=dst_ip,src=src_ip)/TCP(sport=src_port,dport=dst_port,flags=0)/Raw(load=data)
                sendp(b, iface = "eth0", verbose=False)
            total_pkts += 1
            # time.sleep(1)
        # print "Sending FIN"
        p = Ether(dst=dst_mac,src=src_mac)/IP(dst=dst_ip,src=src_ip)/TCP(sport=src_port,dport=dst_port,flags="F")
        print p.show()
        sendp(p, iface = "eth0", verbose=False)
        total_pkts += 1
        time.sleep(1)
    print "Sent %s packets in total" % total_pkts

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Packet generator')
    parser.add_argument('--dst',          '-d', type=str, help='Mininet host destination',           required=True)
    parser.add_argument('--n_packets',     '-n', type=int, help='Number of packets to send',          required=False, default=100)
    parser.add_argument('--n_connections', '-c', type=int, help='Number of packets to send',          required=False, default=1)
    parser.add_argument('--port',          '-p', type=int, help='TCP port to use',                    required=False, default=80)
    parser.add_argument('--random_pkts',                   help='Whether to send a random num of pkts', action='store_true')
    # parser.add_argument('--random_dest',                   help='Whether to use random destinations', action='store_true')
    parser.add_argument('--random_port',                   help='Whether to use random ports',        action='store_true')
    args = parser.parse_args()

    n = args.n_packets
    if(args.random_pkts):
        n = random.sample(xrange(50, 1000), 1)

    send_random_traffic(args.dst, n, args.n_connections, args.port, args.random_port)
