
from mafia_lang.primitives import *

my_counter = Counter('my_counter', 1024, 32)
my_shift_reg = Counter('my_shift_reg', 1024, 32)

case_1 = Match( "match_ipv4_dst", "ipv4.dst == 10.0.0.1", None)
case_2 = Match( "match_tcp_dst", "tcp.dst == 80", None)
m = case_1 >> case_2

t_counter_gt_9 = Match( "my_counter_gt_9 ", "my_counter > 9", my_counter)
t_counter_lt_99 = Match( "my_counter_lt_99 ", "my_counter < 99", my_counter)
t_complex_expr = Match( "complex_expr ", "ipv4.identification & 1 == 1", my_counter)
# t = (t_counter_gt_9 >> bo) + t_counter_lt_99

add_2 = Counter_op( 'my_counter_add_2', "lambda(): { my_counter = my_counter + 2 }", my_counter )
sub_1 = Counter_op( 'my_counter_sub_1', "lambda(): { my_counter = my_counter - 1 }", my_counter )
shift_r_1 = Counter_op( 'my_shift_reg_r_1', "lambda(): { my_shift_reg = my_shift_reg >> 1 }", my_shift_reg )
shift_l_1 = Counter_op( 'my_shift_reg_l_1', "lambda(): { my_shift_reg = my_shift_reg << 1 }", my_shift_reg )

# ops = (add_2 >> sub_1) >> (shift_r_1 >> shift_l_1)
ops_1 = (add_2 + sub_1)
ops_2 = (shift_r_1 >> shift_l_1)
# ops = ops_1 + ops_2

part_1 = (case_1 >> case_2 >> add_2)
part_2 = (t_counter_gt_9 >> sub_1)
part_3 = (t_counter_lt_99 >> shift_r_1)

measurement = t_complex_expr >> (part_1 + part_2 + part_3)
# measurement = m >> ops_1 >> t >> ops_2
# measurement = (case_1 + case_2) >> (add_2 >> sub_1)
