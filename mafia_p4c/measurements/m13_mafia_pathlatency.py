# Program using MAFIA API as of documentation:
# 
# declare timestamp change_ts<48>[1024]
# 
# ( 
#   Counter(lambda(): { packet_counter = packet_counter + 1 }, packet_counter) 
#   +
#   Counter(lambda(): { byte_counter = byte_counter + metadata.packet_size }, byte_counter) 
# )
# + 
# ( 
#   ( Match(start_ts == 0) >> Timestamp(start_ts) )
#   + 
#   ( Timestamp(now_ts) >> Counter(lambda(): { duration_counter = now_ts - start_ts }, duration_counter))
# )

from mafia_lang.primitives import *

ts_change = Timestamp('ts_change', 1024) 
report = Stream('report', 1)

generate_report = Duplicate( "generate_segway_report", report)
# All primitives must provide a unique name as first parameter:
m1 = Match( 'match_segway_update', "ipv4.identification == 999", None) # Match against the source ip address 
m2 = Match("is_last_switch", "metadata.is_last_hop == 1", None)

get_ts_change    = Timestamp_get( 'ts_change',         ts_change )

# The compiler compiles anything named "measurement"
part_1 = (m1 >> m2 >> get_ts_change >> generate_report)
part_2 = Stream_op("report_stream", report) \
         >> Tag("tag_end_update", "ts_change", "tcp.checksum") \
         >> Collect("send_segway_report", ["vlan.vid = 1", "vlan.ether_type = eth.ether_type", "eth.ether_type = 0x8100"])

measurement = (part_1 + part_2)