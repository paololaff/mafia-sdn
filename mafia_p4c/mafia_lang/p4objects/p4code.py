

p4ctrl = """control %s{
%s
}"""

p4ctrl_in = """control %s{
if(valid(ipv4)){
 apply(table_route_next_hop);
%s
}
}"""
# apply(table_src_mac_overwrite); 

p4ctrl_out = """control %s{
 if(valid(ipv4)){
    %s
 }
}"""

p4ctrl_cond = """if(%s){
%s
}"""

p4table = """table %s{
%s
}"""

p4table_reads = """reads{
    %s
}"""

p4table_actions = """actions{
    %s
}"""

p4table_apply = "apply(%s)"

# p4table_block = """{
#     %s
# }"""

p4table_block = """{\n%s\n}"""

p4table_hit = """hit{
%s
}"""

p4table_miss = """miss{
%s
}"""

p4action = """action %s(%s){
%s
}"""

p4action_call = "%s(%s);"


p4action_modify_field          = "modify_field( %s, %s );"
p4action_add                   = "add( %s, %s, %s );"
p4action_add_to_field          = "add_to_field( %s, %s );"
p4action_subtract              = "subtract( %s, %s, %s );"
p4action_subtract_from_field   = "subtract_from_field( %s, %s );"
p4action_shift_left            = "shift_left( %s, %s, %s );"
p4action_shift_right           = "shift_right( %s, %s, %s );"
p4action_bit_or                = "bit_or( %s, %s, %s );"
p4action_bit_and               = "bit_and( %s, %s, %s );"
p4action_register_read         = "register_read( %s, %s, %s );"
p4action_register_write        = "register_write( %s, %s, %s );"
p4action_hash                  = "modify_field_with_hash_based_offset( %s, %s, %s, %s);"
p4action_duplicate             = "clone_ingress_pkt_to_egress( %s, %s );"
# p4action_collect               = "clone_ingress_pkt_to_egress( %s, %s );"

p4header = "header_type %s {\n%s\n}"
p4headerfields = "fields{\n%s\n}"

p4register = "register %s {\n%s\n}"
p4register_count = "instance_count: %s;"
p4register_width = "width: %s;"

p4field_list = "field_list %s {\n%s;\n}"
p4hash = "field_list_calculation %s {\n%s\n}"
p4hash_input = "input{ %s; }"
p4hash_output = "output_width: %s;"
p4hash_algorithm = "algorithm: %s;"

