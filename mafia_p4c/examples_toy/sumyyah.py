# Program using MAFIA API as of documentation:

from mafia_lang.primitives import *
#Registers
connections = Counter('connections', 1, 32)
nbytes = Counter('nbytes', 1024, 32)
decrement = Counter ("decrement", 1, 32)
#MinSketch
volume_sketch = Sketch('volume_sketch', 4, 256, 32)
countmin_hash_set = HashFunction( \
                                    'countmin_hash_set', \
                                    'countmin_hash', \
                                    4, \
                                    [ "ipv4.src", "ipv4.dst", "tcp.src", "tcp.dst"], \
                                    [ HashOutputVar('h', 2), HashOutputVar('index', 8) ] \
                                )
#BloomFilter
bf = BloomFilter("bf", 64, 1)
bf_hash_set = HashFunction( \
                            "bf_hash_set", \
                            "veridp_hash", \
                            3, \
                            [ "ipv4.src", "ipv4.dst", "tcp.src", "tcp.dst"], \
                            [ HashOutputVar("index", 6) ] \
                          )


#Actions
update_total = Counter_op( 'nbytes_increment', "lambda(): { nbytes = nbytes + metadata.packet_length }", nbytes )
update_connections = Counter_op( 'connections_increment', "lambda(): { connections=connections+1 }", connections )
update_sketch = Sketch_op('update_sketch', 'lambda(countmin_hash_set): { volume_sketch[h][index] = volume_sketch[h][index] + metadata.packet_length}', volume_sketch)
update_bloom=BloomFilter_op('bf', 'lambda(bf_hash_set): { bf[index] = 1 }', bf) 

#Match conditions
m1 = Match( 'match_ipv4_dst', "ipv4.dst == 10.0.0.0/24", None) 
m2 = Match ('fin_match', "tcp.ctrl & 0x1==1", None) 
m3 = Match("flow_hh", "all(bf_hash_set):{ bf[index] } != 1") 
#update_sketch = Sketch_op('update_sketch', 'lambda(countmin_hash_set): { decrement = volume_sketch[h][index]}', volume_sketch)
decrement_connections =  Counter_op("decrement_connections", "decrement = min(countmin_hash_set):{ volume_sketch[h][index] } ")
measurement = m1 >> (m2) + (update_sketch>>update_total>>m3>>update_connections>>update_bloom)