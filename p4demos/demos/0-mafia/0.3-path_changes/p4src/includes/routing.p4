
#define N_FLOWS_ENTRIES     1024 // Number of entries for flows (2^10)

action do_route_next_hop(nhop_ipv4, port) {
    modify_field( fwd_metadata.nhop_ipv4, nhop_ipv4 );
    modify_field( standard_metadata.egress_spec, port );
    add_to_field( ipv4.ttl, -1 );
}
table table_route_next_hop{
    reads   { ipv4.dstAddr : lpm; }
    actions { do_route_next_hop; _drop; }
    size: N_FLOWS_ENTRIES;
}



action do_dst_mac_overwrite(dmac) {
    modify_field( ethernet.dstAddr, dmac );
}
table table_dst_mac_overwrite {
    reads { fwd_metadata.nhop_ipv4 : exact; }
    actions { do_dst_mac_overwrite; _drop; }
    size: 64;
}



action do_src_mac_overwrite(smac) {
    modify_field(ethernet.srcAddr, smac);
}
table table_src_mac_overwrite {
    reads { standard_metadata.egress_port: exact; }
    actions { do_src_mac_overwrite; _drop; }
    size: 64;
}