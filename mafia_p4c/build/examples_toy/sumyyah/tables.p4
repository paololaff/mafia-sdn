table t_countmin_hash_update_sketch{
 actions{
     a_countmin_hash_update_sketch;
 }
}
table t_nbytes_increment{
 actions{
     a_nbytes_increment;
 }
}
table t_veridp_hash_flow_hh{
 actions{
     a_veridp_hash_flow_hh;
 }
}

table t_bf{
 actions{
     a_bf;
 }
}
table t_veridp_hash_bf{
 actions{
     a_veridp_hash_bf;
 }
}

table t_update_sketch{
 actions{
     a_update_sketch;
 }
}
table t_flow_hh_read_bf{
 actions{
     a_flow_hh;
 }
}
table t_match_ip_dst{
 reads{
     ipv4.dst: lpm;
 }
 actions{
     a_set_flow_index;_no_op;
 }
}
table t_connections_increment{
 actions{
     a_connections_increment;
 }
}
