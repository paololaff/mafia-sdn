# Program using MAFIA API as of documentation:
# declare counter my_counter<32>[1024]
# Match(ipv4.src == 10.0.0.0/24) >> Counter(lambda(): {my_counter = my_counter + 1}, my_counter)


# Corresponding Python code for the compiler:

from mafia_lang.primitives import *

my_counter = Counter('my_counter', 1024, 32)
m = Match( "match_ipv4_src", "lambda pkt: ipv4.srcAddr == 10.0.0.0/24", None)
c_add_1     = Counter_op(    'counter_add_1', "lambda my_counter = my_counter + 1", my_counter )

measurement = (m >> c_add_1)
