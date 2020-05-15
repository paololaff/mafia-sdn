# Program using MAFIA API as of documentation:
# 
# declare counter total<32>[1]
# declare bloomfilter bf<1>[64]
# declare counter volume<32>[1024]
# declare sketch volume_sketch<32>[4][128]
# 
# declare hash_set bf_hash_set (H=3): { ipv4.src, ipv4.dst, ipv4.protocol, tcp.src, tcp.dst } 
#                                      -> {index<6>}
# declare hash_set countmin_hash_set (H=4, countmin_hash): {ipv4.src, ipv4.dst, ipv4.protocol, tcp.src, tcp.dst} 
#                                                          -> {h<2>, index<7>}
# 
# (
#   Counter(lambda(): { total = total + metadata.packet_size }, total) 
#   >> Sketch( lambda(countmin_hash_set)):{ volume_sketch[h][index] + 1 }, n_changes_sketch))
# )
# >> 
# ( 
#   ( 
#     Match( all(bf_hash_set):{ bf[index] } == 1 )
#     >> Counter(lambda(): { volume = volume + metadata.packet_size }, volume) 
#   )
#   +
#   (
#     Match( min(countmin_hash_set):{ volume_sketch[h][index] }/total > 999 )
#     >> BloomFilter( lambda(bf_hash_set):{ bf[index] = 1 }, bf) 
#   )
# )
# 

# Match(metadata.out_port == i) 
# ^\textbf{$\gg$}^ ( Counter(^$\lambda_u$^:{total + metadata.size}, total) 
#      ^\textbf{+}^ Sketch(^$\lambda_u$^:{s + metadata.size}, s) )
# ^\textbf{$\gg$}^ ( ( Match(min(s)/tot > threshold) ^\textbf{$\gg$}^ BloomFilter(^$\lambda_u$^:{1},bf) )
#      ^\textbf{+}^
#      ( Match(sum(bf) == h) ^\textbf{$\gg$}^ Counter(^$\lambda_u$^:{c + metadata.size},c) ) )        

from mafia_lang.primitives import *

total_counter = Counter('total_counter', 1, 32)
hh_counter = Counter('hh_counter', 1024, 32)

bf = BloomFilter("bf", 64, 1)
bf_hash_set = HashFunction( \
                            "bf_hash_set", \
                            "veridp_hash", \
                            3, \
                            [ "ipv4.src", "ipv4.dst", "tcp.src", "tcp.dst", "ipv4.protocol"], \
                            [ HashOutputVar("index", 6) ] \
                          )

volume_sketch = Sketch("volume_sketch", 4, 128, 32)
countmin_hash_set = HashFunction( \
                                    "countmin_hash_set", \
                                    "countmin_hash", \
                                    4, \
                                    [ "ipv4.src", "ipv4.dst", "tcp.src", "tcp.dst", "ipv4.protocol"], \
                                    [ HashOutputVar("h", 2), HashOutputVar("index", 7) ] \
                                )


update_total = Counter_op( 'total_counter_increment', "lambda(): { total_counter = total_counter + metadata.packet_length }", total_counter )
update_sketch = Sketch_op('update_sketch', 'lambda(countmin_hash_set): { volume_sketch[h][index] = volume_sketch[h][index] + metadata.packet_length}', volume_sketch)

threshold_bf = Match("check_threshold", "min(countmin_hash_set):{ volume_sketch[h][index] } / total_counter > 0.5") \
               >> BloomFilter_op('bf', 'lambda(bf_hash_set): { bf[index] = 1 }', bf) 

counter_exact = Match("flow_hh", "all(bf_hash_set):{ bf[index] } == 1") \
                >> Counter_op( 'hh_counter_increment', "lambda(): { hh_counter = hh_counter + metadata.packet_length }", hh_counter )

measurement = update_total >> update_sketch >> (threshold_bf + counter_exact)




