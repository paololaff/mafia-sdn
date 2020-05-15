# Program using MAFIA API as of documentation:
# 
# declare bloomfilter bf<1>[16]
# declare hash_set bf_hash_set (H=3): {metadata.input_port | metadata.switch_id | metadata.output_port } 
#                                      -> {index<4>}
# 
# ( 
#   Match(metadata.is_first_hop == 1) 
#   >> ( Tag(switch.id, ipv4.identification) + Tag(metadata.input_port, ipv4.identification) + Tag(0, tcp.checksum)) 
# )
# +
# ( 
#   
#   BloomFilter(lambda(bf_hash_set):{ bf[index] = 1 }, bf) 
#   >> Tag( bf[] | tcp.checksum, tcp.checksum) 
#   >> BloomFilter(lambda(bf_hash_set):{ bf[index] = 0 }, bf)
# )
# + 
# ( 
#   Match(metadata.is_last_hop == 1)
#   >>
#   (
#    (
#      ( 
#        Tag(switch.id, ipv4.identification) + Tag(metadata.output_port, ipv4.identification) 
#      ) 
#      >> Duplicate("reports")
#    )
#    +
#    ( "reports" >> Collect("endpoint") )
#   )
# )
# 

from mafia_lang.primitives import *

reports = Stream('reports', 1)
bf = BloomFilter('bf', 16, 1)
bf_hash_set = HashFunction( \
                                'bf_hash_set', \
                                'veridp_hash', \
                                3, \
                                [ "standard_metadata.ingress_port", "mafia_metadata.switch_id", "standard_metadata.egress_port"], \
                                [ HashOutputVar('index', 4) ] \
                            )

# The entry switch memorizes in the packet its identifier and the input port the packet was received
entry_ops = Match("is_entry_switch", "metadata.is_first_hop == 1", None) \
            >> ( \
                 Tag("tag_entry_switch", "metadata.switch_id", "ipv4.identification") \
                 + \
                 Tag("tag_entry_port", "metadata.input_port", "ipv4.identification") \
                 + \
                 Tag("reset_checksum", "0", "tcp.checksum") \
               )

# BloomFilter_op('', 'lambda()')
# All switches compute a bloom filter encoding the current packet location and update the path tag
location_bf = BloomFilter_op('location_bf', 'lambda(bf_hash_set): { bf[index] = 1 }', bf) \
              >> Tag("tag_location_bf", "bf[] | tcp.checksum", "tcp.checksum") \
              >> BloomFilter_op("reset_location_bf", "lambda(bf_hash_set): { bf[index] = 0 }", bf)

# The exit switch memorizes in the packet its identifier and the output port where the packet was forwarded.
# Also duplicates the packet and sends reports to the controller.
exit_ops = Match("is_exit_switch", "metadata.is_last_hop == 1", None) \
           >> ( \
                  Tag("tag_exit_switch", "metadata.switch_id", "ipv4.identification") \
                  + \
                  Tag("tag_exit_port", "metadata.output_port", "ipv4.identification") \
              ) \
           >> Duplicate("collect_reports", reports)

send_reports = Stream_op("send_reports", reports) >> Collect("send_reports", ["vlan.vid = 9", "vlan.ether_type = eth.ether_type", "eth.ether_type = 0x8100"])

measurement = (entry_ops + location_bf + (exit_ops + send_reports))
