
import asyncio
import random
import packet

from mafia_lang.observer    import Observable, Observer
from mafia_lang.operators   import Operator, Parallel, Sequential
from mafia_lang.primitives  import Match, Timestamp, Counter, count_add
from mafia_lang.util.extensionmethod   import extensionmethod
from mafia_lang.util.lambdacode        import get_short_lambda_source
from mafia_lang.util.util              import indent_str, repr_plus

import ryu.lib as ryu
# from ryu.lib.packet         import packet, ipv4, tcp

import os, sys, inspect
# realpath() will make your script run, even if you symlink it :)
cmd_folder = os.path.realpath(os.path.abspath(os.path.split(inspect.getfile( inspect.currentframe() ))[0]))
if cmd_folder not in sys.path:
    sys.path.insert(0, cmd_folder)

# Use this if you want to include modules from a subfolder
cmd_subfolder = os.path.realpath(os.path.abspath(os.path.join(os.path.split(inspect.getfile( inspect.currentframe() ))[0],"mafia_lang")))
if cmd_subfolder not in sys.path:
    sys.path.insert(0, cmd_subfolder)

class PacketStream(Observable):
    async def run(self):
        while True:
            #await asyncio.sleep(random.random() * 10)

            if random.random() < 0.01:
                self._complete()
                return

            self._next(Packet())


def concrete2pyretic(raw_pkt):
    pkt = packet.get_packet_processor().unpack(raw_pkt['raw'])
    pkt['raw'] = raw_pkt['raw']
    pkt['switch'] = raw_pkt['switch']
    pkt['port'] = raw_pkt['port']

    def convert(h, val):
        if h in ['srcmac', 'dstmac']:
            return MAC(val)
        elif h in ['srcip', 'dstip']:
            return IP(val)
        else:
            return val

    pyretic_packet = packet.Packet(util.frozendict())
    d = {h: convert(h, v) for (h, v) in pkt.items()}
    return pyretic_packet.modifymany(d)


@extensionmethod(ryu.packet.packet.Packet)
def __getattr__(self, k):
    if k in ryu.packet.packet.PKT_CLS_DICT:
        pro = self.get_protocol(ryu.packet.packet.PKT_CLS_DICT[k])
    elif k == 'ip':
        pro = self.get_protocol(ryu.packet.ipv4.ipv4)
    if pro is None:
        raise AttributeError
    return pro

seqn_count = Counter()
ip1 = "10.0.0.1"
ip2 = "10.0.0.2"

s = Match(lambda pkt: pkt.ip.dst == ip1) + Match(lambda pkt: pkt.ip.dst == ip2)

#b = s >> count_add(lambda pkt: pkt.tcp_seqn, seqn_count)
# b = s >> count_add(lambda pkt: pkt.tcp_seqn - seqn_count.value, seqn_count)

p = packet.tcp_packet_gen()
print(p)
print(p.ip.dst)
s._next(p)

# s = Match >> (count_add + (timestamp >> tag))

# c = Collector(URI)

# r = Random(uniform, 0, 1)
# match(lambda pkt: pkt.dstip == ip1) >> random(r) >> match(lambda pkt, meta: meta.r < 0.5) >> collect

# def sampling(r, X):
#     return random(r) >> match(lambda pkt, meta: meta.r < X) >> collect



# def mytuple(pkt):
#     return pkt.ip.src || pkt.ip.dst || pkt.ip.proto || pkt.tcp.sport || pkt.tcp.dport

# def hash(pkt)
#     t = mytuple(pkt)
#     h = []
#     for i in range(4):
#         h.append(t + hash_specific % N)
#     return h


# hfn = partial(hash(mytuple, 4))
# my_countmin_sketch = Sketch(hfn)

# match(lambda pkt: pkt.ip.dst == ip(10.0.0.0/24)) >>

# sketch_add(lambda pkt: (1, 1, 1, 1), my_countmin_sketch)

# a=my_countmin_sketch

# sketch_set(lambda pkt: ((a+1, a|pkt.ip.dst) , 1, 1, 1), my_countmin_sketch)


# bf = BloomFilter(hfn)
# bloom_match(bf) >> tag >> collect

# c = Counter()
# s >> scope(lambda pkt: pkt.ip.dst or pkt.ip.src) { count_add(lambda pkt: pkt.tcp_seqn - seqn_count.value, seqn_count) }


#pkt = {}
#pkt['raw'] = rp.serialize()
#pkt['switch'] = 0
#pkt['port'] = 0
#p = concrete2pyretic(pkt)
#p = packet.Packet()
# p = packet.tcp_packet_gen()
# # print(p)
# print(p.ip.dst)


#iph = p.get_protocols(ipv4.ipv4)[0]
#print(iph.dstip)
#s._next(p)