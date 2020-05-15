import argparse
from scapy.all import *

n = 0

def lambda_hex_dump(x):
    global n
    n += 1
    print ""
    print "Packet #%d" % n
    hexdump(x)
    print ""
    

parser = argparse.ArgumentParser(description='Sniffs a switch interface')
parser.add_argument('--iface', '-i', type=str, help='Switch interface to sniff', required=True)
args = parser.parse_args()

sniff(iface = args.iface, prn = lambda x: lambda_hex_dump(x))
