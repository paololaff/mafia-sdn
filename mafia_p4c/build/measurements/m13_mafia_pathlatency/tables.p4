table t_tag_end_update{
 actions{
     a_tag_end_update;
 }
}

table t_check_is_last_switch{
 reads{
     ipv4.src: exact;ipv4.dst: exact;
 }
 actions{
     a_is_last_switch;
 }
}
table t_generate_segway_report{
 actions{
     a_generate_segway_report;
 }
}
table t_ts_change{
 actions{
     a_ts_change;
 }
}

table t_send_segway_report{
 actions{
     a_header_vlan;
 }
}

