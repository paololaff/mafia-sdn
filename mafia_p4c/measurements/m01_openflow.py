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

# All registers must declare a name, the number of instances and the width of each instance.
byte_counter = Counter('byte_counter', 8, 32) # Declares a register named "byte_counter" containing 1024 32-bit counters
packet_counter = Counter('packet_counter', 8, 32)
flow_duration = Counter('flow_duration', 8, 48)
# Timestamps are always 48-bit:
now_ts = Timestamp('now_ts', 8) # Declares a a register named "now_ts" containing 1024 timestamps
start_ts = Timestamp('start_ts', 8) 

# All primitives must provide a unique name as first parameter:
m1 = Match( 'match_ipv4_src', "ipv4.src == 10.0.0.0/24", None) # Match against the source ip address 
m2 = Match( 'match_ipv4_dst', "ipv4.dst == 10.0.0.0/24", None) # Match against the destination ip address 
m3 = Match( 'match_tcp_traffic', "ipv4.protocol == 0x06", None) # Match against tcp packets
t_start_ts_eq_0 = Match( 'start_ts_eq_0', "start_ts == 0", start_ts) # Check if a start timestamp for the flow has been saved, yet. 

# Use two counter primitives to track the flow size (#packets and #bytes):
c_add_size  = Counter_op(    'byte_counter_add_size',   "lambda(): { byte_counter = byte_counter + metadata.packet_length }", byte_counter )
c_add_1     = Counter_op(    'packet_counter_add_1',    "lambda(): { packet_counter = 1 + packet_counter }", packet_counter )
ts_now      = Timestamp_get( 'now_ts',              now_ts )
ts_start    = Timestamp_get( 'start_ts',         start_ts )
# Use a counter to calculate the flow duration:
c_duration  = Counter_op(    'flow_duration_update', "lambda(): { flow_duration = now_ts - start_ts }", flow_duration )

# It's easier to declare all primitive's operation and then compose them together
do_counters = c_add_1 + c_add_size
do_start_ts = t_start_ts_eq_0 >> ts_start
do_duration = ts_now >> c_duration

# The compiler compiles anything named "measurement"
# measurement = (m1 >> m2) >> (do_counters + (do_start_ts + do_duration))
# measurement = m3 >> (do_counters + (do_start_ts + do_duration))
measurement = Match( 'match_tcp', "ipv4.protocol == 0x06", None) >>  (do_counters + (do_start_ts + do_duration))

