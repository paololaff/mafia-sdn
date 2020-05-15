
# Program using MAFIA API as of documentation:
# 
# 
# ( 
#   Duplicate("postcards") 
# +
# ( "postcards" 
#   >> Tag("metadata.input_port", "eth.src") 
#   >> Tag("metadata.switch_id", "ipv4.identification") 
#   >> Tag("metadata.input_port", "eth.dst") 
#   >> Collect(["vlan.vid = 1", "vlan.ether_type = eth.ether_type", "eth.ether_type = 0x8100"]) 
# )

from mafia_lang.primitives import *

postcard_stream = Stream('postcards', 1)

duplicate_postcards = Duplicate( "duplicate_postcards", postcard_stream)

collect_postcard = Stream_op("postcard_stream", postcard_stream) \
      >> Tag("tag_input_port", "metadata.input_port", "eth.src") \
      >> Tag("tag_switch_id", "metadata.switch_id", "ipv4.identification") \
      >> Tag("tag_output_port", "metadata.output_port", "eth.dst") \
      >> Collect("collect_postcards", ["vlan.vid = 1", "vlan.ether_type = eth.ether_type", "eth.ether_type = 0x8100"])

measurement = (duplicate_postcards + collect_postcard)
