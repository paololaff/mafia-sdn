table t_countmin_hash_total_packets_sketch{
 actions{
     a_countmin_hash_total_packets_sketch;
 }
}

table t_check_is_exit_switch{
 reads{
     ipv4.dst: exact;ipv4.src: exact;
 }
 actions{
     a_is_exit_switch;
 }
}
table t_total_packets_sketch{
 actions{
     a_total_packets_sketch;
 }
}
table t_check_is_not_entry_switch{
 reads{
     ipv4.dst: exact;ipv4.src: exact;
 }
 actions{
     a_is_not_entry_switch;
 }
}
table t_check_is_entry_switch{
 reads{
     ipv4.dst: exact;ipv4.src: exact;
 }
 actions{
     a_is_entry_switch;
 }
}
table t_q_len_sketch{
 actions{
     a_q_len_sketch;
 }
}
table t_update_tag{
 actions{
     a_update_tag;
 }
}

table t_tag_q_length{
 actions{
     a_tag_q_length;
 }
}

table t_update_q_length{
 actions{
     a_update_q_length;
 }
}
table t_countmin_hash_q_len_sketch{
 actions{
     a_countmin_hash_q_len_sketch;
 }
}
