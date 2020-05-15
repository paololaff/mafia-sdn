table t_packet_counter_add_1{
 actions{
     a_packet_counter_add_1;
 }
}
table t_byte_counter_add_size{
 actions{
     a_byte_counter_add_size;
 }
}
table t_duplicate_4_packets_exceeded{
 actions{
     a_duplicate_4_packets_exceeded;
 }
}
table t_duplicate_4_bytes_exceeded{
 actions{
     a_duplicate_4_bytes_exceeded;
 }
}

table t_condition_packet_counter_gt_999{
 actions{
     a_condition_packet_counter_gt_999;
 }
}
table t_condition_byte_counter_gt_999{
 actions{
     a_condition_byte_counter_gt_999;
 }
}



table t_tag_packet_counter{
 actions{
     a_tag_packet_counter;
 }
}
table t_tag_byte_counter{
 actions{
     a_tag_byte_counter;
 }
}
table t_samples_packets{
 actions{
     a_header_vlan;
 }
}
table t_sample_bytes{
 actions{
     a_header_vlan;
 }
}
