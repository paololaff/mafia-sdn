
table t_collect_reports{
 actions{
     a_collect_reports;
 }
}
table t_veridp_hash_location_bf{
 actions{
     a_veridp_hash_location_bf;
 }
}
table t_tag_entry_port{
 actions{
     a_tag_entry_port;
 }
}
table t_send_reports{
 actions{
     a_header_vlan;
 }
}
table t_location_bf{
 actions{
     a_location_bf;
 }
}
table t_tag_exit_port{
 actions{
     a_tag_exit_port;
 }
}
table t_tag_location_bf{
 actions{
     a_tag_location_bf;
 }
}
table t_reset_checksum{
 actions{
     a_reset_checksum;
 }
}
table t_reset_location_bf{
 actions{
     a_reset_location_bf;
 }
}
table t_tag_exit_switch{
 actions{
     a_tag_exit_switch;
 }
}
table t_check_is_entry_switch{
 reads{
     ipv4.src: exact;ipv4.dst: exact;
 }
 actions{
     a_is_entry_switch;
 }
}
table t_tag_entry_switch{
 actions{
     a_tag_entry_switch;
 }
}

table t_check_is_exit_switch{
 reads{
     ipv4.src: exact;ipv4.dst: exact;
 }
 actions{
     a_is_exit_switch;
 }
}
table t_veridp_hash_reset_location_bf{
 actions{
     a_veridp_hash_reset_location_bf;
 }
}
