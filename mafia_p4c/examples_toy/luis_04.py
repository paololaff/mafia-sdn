# Program using MAFIA API as of documentation:
# declare counter packet_counter<32>[1024]
# Counter(lambda(): {packet_counter = packet_counter + 1}, packet_counter) >> (Tag(packet_counter, ipv4.identification) + Tag(1, ipv4.tos))

#IMPORTANT NOTICE: In this case the compiler cannot leverage the parallel operator "+" and all actions are executed sequentially

from mafia_lang.primitives import *

packet_counter = Counter('packet_counter', 1024, 32)

c_add_1     = Counter_op(    'packet_counter_add_1',    "lambda packet_counter = packet_counter + 1", packet_counter )
t_tag_number = Tag('tag_number', '1', 'ipv4.tos')
t_tag_counter = Tag('tag_counter', 'packet_counter', 'ipv4.identification')

do_tags = (t_tag_number + t_tag_counter)

measurement = (c_add_1 >> do_tags)
