# Program using MAFIA API as of documentation:
# 
# declare counter byte_counter<32>[1024]
# declare counter byte_counter<32>[1024]
# declare counter duration_counter<48>[1024]
# declare timestamp now_ts<48>[1024]
# declare timestamp start_ts<48>[1024]
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

# Creates two streams for the duplicated packets for each counter thresholds
samples_bytes_exceeded = Stream('samples_bytes_exceeded', 1)
samples_packets_exceeded = Stream('samples_packets_exceeded', 2)
# Declare two registers named "byte_counter" and "packet_counter" containing 1024 32-bit counters
byte_counter = Counter('byte_counter', 1024, 32)
packet_counter = Counter('packet_counter', 1024, 32)

# Increment the counters:
c_add_size  = Counter_op(    'byte_counter_add_size',   "lambda(): { byte_counter = byte_counter + metadata.packet_length }", byte_counter )
c_add_1     = Counter_op(    'packet_counter_add_1',    "lambda(): { packet_counter = packet_counter + 1 }", packet_counter )
# Check if some thershold has been exceeded:
threshold_bytes = Match("threshold_bytes", "byte_counter > 999", None)
threshold_packets = Match("threshold_packets", "packet_counter > 999", None)

# Compose the counter primitives with the respective threshold checks and creates the duplicated packets
t1 = c_add_size >> threshold_bytes \
                >> Duplicate("duplicate_4_bytes_exceeded", samples_bytes_exceeded)

t2 = c_add_1 >> threshold_packets \
             >> Duplicate("duplicate_4_packets_exceeded", samples_packets_exceeded)

# Compose the duplicated streams the respective tag operation and collection
samples_bytes = Stream_op("samples_bytes_exceeded", samples_bytes_exceeded) \
                >> Tag('tag_byte_counter', 'byte_counter', 'ipv4.identification') \
                >> Collect("sample_bytes", ["vlan.vid = 1", "vlan.ether_type = eth.ether_type", "eth.ether_type = 0x8100"])

samples_packets = Stream_op("samples_packets_exceeded", samples_packets_exceeded) \
                  >> Tag('tag_packet_counter', 'packet_counter', 'ipv4.identification') \
                  >> Collect("samples_packets", ["vlan.vid = 2", "vlan.ether_type = eth.ether_type", "eth.ether_type = 0x8100"])

sample = (samples_bytes + samples_packets)

measurement = (t1 + t2 + sample)