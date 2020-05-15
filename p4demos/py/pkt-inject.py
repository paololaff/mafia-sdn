#!/usr/bin/python

from scapy.all import Ether, IP, sendp, get_if_hwaddr, get_if_list, TCP, Raw
import sys
import argparse
import random, string, time, socket

def random_payload(max_length):
    length = random.randint(1, max_length)
    return ''.join(random.choice(string.lowercase) for i in range(length))

def random_mac():
    return "%02x:%02x:%02x:%02x:%02x:%02x" % (
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255)
        )

def random_ip():
    return ".".join(str(random.randint(0, 255)) for _ in range(4))

def emulate_connections(iface, src_mac, dst_mac, src_ip, dst_ip, src_port, dst_port, n_packets, connections, payload, delay_ms):

    socket_fd = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(0x03))
    socket_fd.bind((iface, 0))
    ips_2_macs = dict()

    for c in range(0, connections):
        c_src_ip = random_ip() if src_ip == "0.0.0.0" else src_ip
        c_dst_ip = random_ip() if dst_ip == "0.0.0.0" else dst_ip
        # c_src_mac = random_mac() if src_mac == "00:00:00:00:00:00" else src_mac
        # c_dst_mac = random_mac() if dst_mac == "00:00:00:00:00:00" else src_mac
        if src_mac == "00:00:00:00:00:00":
            if ips_2_macs.has_key(c_src_ip):
                c_src_mac = ips_2_macs[c_src_ip]
            else:
                c_src_mac = random_mac()
                ips_2_macs[c_src_ip] = c_src_mac
        else:
            c_src_mac = src_mac
        if dst_mac == "00:00:00:00:00:00":
            if ips_2_macs.has_key(c_dst_ip):
                c_dst_mac = ips_2_macs[c_dst_ip]
            else:
                c_dst_mac = random_mac()
                ips_2_macs[c_dst_ip] = c_dst_mac
        else:
            c_dst_mac = dst_mac

        c_src_port = random.sample(xrange(1025, 65535), 1)[0] if src_port == 0 else src_port
        c_dst_port = random.sample(xrange(1025, 65535), 1)[0] if dst_port == 0 else dst_port

        n = n_packets if n_packets > 0 else random.sample(xrange(50, 1000), 1)[0]

        print "Connection %d (iface: %s) [%s/%s/%d] -----> [%s/%s/%d]: %d packets" % (c+1, iface, c_src_mac, c_src_ip, c_src_port, c_dst_mac, c_dst_ip, c_dst_port, n)
        inject_packets(socket_fd, c_src_mac, c_dst_mac, c_src_ip, c_dst_ip, c_src_port, c_dst_port, n, payload)
        time.sleep(delay_ms / 1000.0)

def inject_packets(socket_fd, src_mac, dst_mac, src_ip, dst_ip, src_port, dst_port, n, payload):

    total_pkts = 0

    syn_pkt  = Ether(dst=dst_mac,src=src_mac)/IP(dst=dst_ip,src=src_ip)/TCP(sport=src_port,dport=dst_port,flags="S")
    data_pkt = Ether(dst=dst_mac,src=src_mac)/IP(dst=dst_ip,src=src_ip)/TCP(sport=src_port,dport=dst_port,flags=0)
    fin_pkt  = Ether(dst=dst_mac,src=src_mac)/IP(dst=dst_ip,src=src_ip)/TCP(sport=src_port,dport=dst_port,flags="F")

    for i in range(n):
        pkt =  data_pkt/Raw(load=random_payload(payload)) if (payload > 0) else data_pkt
        if i == 0   and n > 1: pkt = syn_pkt
        if i == n-1 and n > 1: pkt = fin_pkt
        socket_fd.send(str(pkt))
        total_pkts += 1
    print "Sent %s packets in total" % (total_pkts)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Packet generator')
    parser.add_argument('--iface',         '-i', type=str, help='Interface through which send packets',  required=True)
    parser.add_argument('--src_mac',             type=str, help='Source MAC address',                    required=False, default='00:00:00:00:00:00')
    parser.add_argument('--dst_mac',             type=str, help='Destination MAC address',               required=False, default='00:00:00:00:00:00')
    parser.add_argument('--src_ip',              type=str, help='Source IP address',                     required=False, default='0.0.0.0')
    parser.add_argument('--dst_ip',              type=str, help='Destination IP address',                required=False, default='0.0.0.0')
    parser.add_argument('--src_port',            type=int, help='Source TCP port',                       required=False, default=0)
    parser.add_argument('--dst_port',            type=int, help='Destination TCP port',                  required=False, default=0)
    parser.add_argument('--payload',             type=int, help='Maximum size of each packet payload',   required=False, default=0)
    parser.add_argument('--n_packets',     '-n', type=int, help='Number of packets to send',             required=False, default=1)
    parser.add_argument('--connections',   '-c', type=int, help='Number of packets to send',             required=False, default=1)
    parser.add_argument('--delay_ms',      '-d', type=int, help='Delay between connections',             required=False, default=500)
    # parser.add_argument('--random_pkts',                   help='Whether to send a random num of pkts',  action='store_true')

    args = parser.parse_args()

    # n = args.n_packets
    # if(args.random_pkts):
    #     n = random.sample(xrange(50, 1000), 1)[0]
    #     print("Random # packets: %d", n)

    emulate_connections(args.iface, args.src_mac, args.dst_mac, args.src_ip, args.dst_ip, args.src_port, args.dst_port, args.n_packets, args.connections, args.payload, args.delay_ms)
