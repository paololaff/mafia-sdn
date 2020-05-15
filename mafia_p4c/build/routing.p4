
#define N_FLOWS_ENTRIES     1024 // Number of entries for flows (2^10)

action _drop(){
    drop();
}

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.tos;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.src;
        ipv4.dst;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.checksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}

// INGRESS FORWARDING LOGIC (routing table + dmac rewriting) //

action do_route_next_hop(dmac, port) {
    modify_field( fwd_metadata.prev_hop_mac, eth.dst );
    modify_field( fwd_metadata.next_hop_mac, dmac );
    
    modify_field( fwd_metadata.in_port, standard_metadata.ingress_port );
    modify_field( fwd_metadata.out_port, port );
    
    modify_field( standard_metadata.egress_spec, port );

    modify_field( eth.dst, dmac );
    // modify_field(eth.src, fwd_metadata.prev_hop_mac);
    add_to_field( ipv4.ttl, -1 );
}
table table_route_next_hop{
    reads   { ipv4.dst : lpm; }
    actions { do_route_next_hop; _drop; }
    size: N_FLOWS_ENTRIES;
}

// control ingress {
//     apply(table_route_next_hop);
//     apply(table_dst_mac_overwrite);
// }

// EGRESS FORWARDING LOGIC (smac rewriting) //


action do_src_mac_overwrite(smac) {
    // modify_field(eth.src, smac);
    // modify_field(eth.src, fwd_metadata.prev_hop_mac);
}
table table_src_mac_overwrite {
    reads { standard_metadata.egress_port: exact; }
    actions { do_src_mac_overwrite; _drop; }
    // actions { do_src_mac_overwrite; }
    size: 64;
}

// control egress {
//     apply(table_src_mac_overwrite);
// }
