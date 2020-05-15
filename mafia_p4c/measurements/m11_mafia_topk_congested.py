

# Program using MAFIA API as of documentation:
# 
# declare counter q_len_sum<32>[1024]
# declare sketch total_packets<32>[4][256]
# declare sketch path_q_len<32>[4][256]
# declare hash_set sketch_hash_set (H=4, countmin_hash): {ipv4.src, ipv4.dst, ipv4.protocol, tcp.src, tcp.dst} 
#                                                        -> {h<2>, index<8>}
# 
# ( 
#   Match(metadata.is_first_hop == 1) >> Tag(metadata.queue_length, ipv4.identification) 
# )
# +
# ( 
#   Match(metadata.is_first_hop != 1) 
#   >> Counter( lambda(): { q_len_sum = ipv4.identification + metadata.queue_length }, q_len_sum) 
#   >> Tag(q_len_sum, ipv4.identification)
# )
# + 
# ( 
#   Match(metadata.is_last_hop == 1)
#   >>
#   (
#    Sketch( lambda(sketch_hash_set): { total_packets[h][index] = total_packets[h][index] + 1 }, total_packets)
#    +
#    Sketch( lambda(sketch_hash_set): { path_q_len[h][index] = path_q_len[h][index] + ipv4.identification }, path_q_len)
#   )
# )
# 

from mafia_lang.primitives import *

q_len_sum = Counter('q_len_sum', 1024, 32)
q_len_sketch = Sketch('q_len_sketch', 4, 256, 32)
total_packets = Sketch('total_packets', 4, 256, 32)
sketch_hash_set = HashFunction( \
                                'sketch_hash_set', \
                                'countmin_hash', \
                                4, \
                                [ "ipv4.src", "ipv4.dst", "tcp.src", "tcp.dst", "ipv4.protocol"], \
                                [ HashOutputVar('h', 2), HashOutputVar('index', 8) ] \
                            )

entry_ops = Match("is_entry_switch", "metadata.is_first_hop == 1", None) \
            >> Tag("tag_q_length", "metadata.queue_length", "ipv4.identification")

update_q_lengths = Match("is_not_entry_switch", "metadata.is_first_hop != 1", None) \
                   >> Counter_op( 'update_q_length',   "lambda(): { q_len_sum = ipv4.identification + metadata.queue_length }", q_len_sum ) \
                   >> Tag("update_tag", "q_len_sum", "ipv4.identification")

exit_ops = Match("is_exit_switch", "metadata.is_last_hop == 1", None) \
           >> ( \
                  Sketch_op('q_len_sketch', 'lambda(sketch_hash_set): { q_len_sketch[h][index] = q_len_sketch[h][index] + ipv4.identification}', q_len_sketch) \
                  + \
                  Sketch_op('total_packets_sketch', 'lambda(sketch_hash_set): { total_packets[h][index] = total_packets[h][index] + 1}', total_packets) \
              )

measurement = (entry_ops + update_q_lengths + exit_ops)


