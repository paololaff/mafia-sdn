
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/veridp-bf.p4"

#define TABLE_INDEX_WIDTH   10 
#define N_FLOWS_ENTRIES     1024 // Number of entries for flows (2^10)
#define VERIDP_VLAN_ID 0xFF
#define VERIDP_REPORT_SESSION_ID 999

metadata my_fwd_metadata_t      fwd_metadata;
metadata intrinsic_metadata_t   intrinsic_metadata;

action _drop() { drop(); }
action _no_op(){ no_op(); }


action set_nhop(nhop_ipv4, port) {
    modify_field( fwd_metadata.nhop_ipv4, nhop_ipv4 );
    modify_field( standard_metadata.egress_spec, port );
    add_to_field( ipv4.ttl, -1 );
}
table ipv4_lpm {
    reads   { ipv4.dstAddr : lpm; }
    actions { set_nhop; _drop; }
    size: N_FLOWS_ENTRIES;
}

action set_dmac(dmac) {
    modify_field( ethernet.dstAddr, dmac );
}
table forward {
    reads { fwd_metadata.nhop_ipv4 : exact; }
    actions { set_dmac; _drop; }
    size: 512;
}

action do_veridp_load_switch_id(switch_id){
    modify_field( veridp_metadata.switch_id, switch_id  ); // Save this switch's id
    modify_field( veridp_metadata.marker, ipv4.tos);
}
table table_veridp_load_switch_id{
    actions { do_veridp_load_switch_id; _no_op; }
    size: 1;
}

action do_veridp_in_out_port(input_port){
    modify_field( veridp_metadata.input_port,  input_port );                     // Save the packet input port
    modify_field( veridp_metadata.output_port, standard_metadata.egress_spec );  // Save the packet output port
}
table table_veridp_in_out_port{
    reads{
        veridp_metadata.switch_id:  exact;
        ethernet.srcAddr:  exact;
    }
    actions{
        do_veridp_in_out_port;
        _no_op;
    }
    size: 128;
}

action do_veridp_sample_interval(entry_index){
    modify_field( veridp_metadata.entry_index, entry_index );
    
    // Calculate how much time has passed since last verification for this flow
    modify_field (       veridp_metadata.ts,       intrinsic_metadata.ingress_global_timestamp);
    register_read(       veridp_metadata.ts_last,  veridp_sample_timestamps, veridp_metadata.entry_index);
    subtract_from_field( veridp_metadata.ts,       veridp_metadata.ts_last);    
}
table table_veridp_sample_interval{
    reads { 
        ipv4.srcAddr: exact; 
        ipv4.dstAddr: exact; 
    }
    actions{ do_veridp_sample_interval; _no_op; }
    size: 128;
}

action do_veridp_select(){
    // Update the last time a packet was selected
    register_write( veridp_sample_timestamps, veridp_metadata.entry_index, intrinsic_metadata.ingress_global_timestamp);
    
    add_header( veridp_h ); // Add the VeriDP header to the packet!!!

    modify_field( ipv4.protocol,             IPPROTO_VERIDP );
    modify_field( veridp_h.net_entry_port,   veridp_metadata.input_port );
    modify_field( veridp_h.net_entry_switch, veridp_metadata.switch_id  );
    
    // Mark the IPV4 ToS field
    // bit_or      ( ipv4.tos, ipv4.tos, VERIDP_TAG_TOS_MASK );
    modify_field( ipv4.tos,               1 );
    modify_field( veridp_metadata.marker, 1 );
    
}
table table_veridp_select{
    actions{ do_veridp_select; }
}

action do_veridp_bf_g0_x(){
    modify_field( veridp_metadata.g0_x, veridp_metadata.h1_x );
}
action do_veridp_bf_g1_x(){
    modify_field( veridp_metadata.g1_x, veridp_metadata.h2_x );
    add_to_field( veridp_metadata.g1_x, veridp_metadata.h1_x );
}
action do_veridp_bf_g2_x(){
    modify_field( veridp_metadata.g2_x, veridp_metadata.h2_x );
    shift_left(   veridp_metadata.g2_x, veridp_metadata.g2_x, 1 );
    add_to_field( veridp_metadata.g2_x, veridp_metadata.h1_x );    
}
action do_veridp_calculate_bf_indexes(){
    /* Generate the Murmur hash */
    modify_field_with_hash_based_offset ( veridp_metadata.murmur_hash, 0, veridp_bf_hash, 4294967295); // Max 2^32
    
    /* Calculate H1, H2, G0, G1, G2 */
    bit_and(     veridp_metadata.h2_x, veridp_metadata.murmur_hash, MURMUR_H2_MASK); // H2
    shift_right( veridp_metadata.h1_x, veridp_metadata.murmur_hash, 16);             // H1
    do_veridp_bf_g0_x(); // G0
    do_veridp_bf_g1_x(); // G1
    do_veridp_bf_g2_x(); // G2    

    // Calculate the Bloom Filter bit to be set
    bit_and(veridp_metadata.bf_index_0, veridp_metadata.g0_x, VERIDP_TAG_INDEX_MASK);
    bit_and(veridp_metadata.bf_index_1, veridp_metadata.g1_x, VERIDP_TAG_INDEX_MASK);
    bit_and(veridp_metadata.bf_index_2, veridp_metadata.g2_x, VERIDP_TAG_INDEX_MASK);
    do_veridp_update_bf_tag(veridp_metadata.bf_index_0);
}
table table_veridp_calculate_bf_indexes{
    actions{ do_veridp_calculate_bf_indexes; }
}

action do_veridp_update_bf_tag(tag_mask){
    modify_field( veridp_metadata.bf_tag_value, veridp_h.bf_tag );
    bit_or(       veridp_metadata.bf_tag_value, veridp_metadata.bf_tag_value, tag_mask );
    modify_field( veridp_h.bf_tag,              veridp_metadata.bf_tag_value );
}
table table_veridp_update_bf_0{
    reads  { veridp_metadata.bf_index_0: exact; }
    actions{ do_veridp_update_bf_tag; _no_op; }
    size: 16;
}
table table_veridp_update_bf_1{
    reads  { veridp_metadata.bf_index_1: exact; }
    actions{ do_veridp_update_bf_tag;_no_op;  }
    size: 16;
}
table table_veridp_update_bf_2{
    reads  { veridp_metadata.bf_index_2: exact; }
    actions{ do_veridp_update_bf_tag; _no_op; }
    size: 16;
}

action do_veridp_switch_entry(){
    no_op();
}
table table_veridp_switch_net_entry{
    reads{ veridp_metadata.switch_id: exact; ethernet.srcAddr: exact; }
    actions { do_veridp_switch_entry; _no_op; }
    size: 64;
}
action do_veridp_switch_exit(){
    modify_field( veridp_h.net_exit_port, standard_metadata.egress_spec);
    modify_field( veridp_h.net_exit_switch, veridp_metadata.switch_id);
}
table table_veridp_switch_net_exit{
    reads{ veridp_metadata.switch_id: exact; ethernet.dstAddr: exact;}
    actions { do_veridp_switch_exit; _no_op; }
    size: 64;
}

control ingress {
    apply( ipv4_lpm );
    apply( forward );
    // Load the switch id
    apply( table_veridp_load_switch_id );
    apply( table_veridp_in_out_port    ); // Load the input/output ports of the packet
    
    apply(table_veridp_switch_net_entry){
        hit{
            if( not valid(veridp_h) ){ // Only done by the packet first hop
                apply( table_veridp_sample_interval ){
                    hit{
                        if( veridp_metadata.ts > VERIDP_SAMPLE_INTERVAL ) { apply( table_veridp_select );}
                    }
                }        
            }
        }
    }
    
    
    if( (veridp_metadata.marker == 1) and valid(veridp_h)){ // All switches: update VeriDP Bloom Filter Tag
        apply( table_veridp_calculate_bf_indexes );
        apply( table_veridp_update_bf_0 );
        apply( table_veridp_update_bf_1 );
        apply( table_veridp_update_bf_2 );
    }

    apply(table_veridp_switch_net_exit){
        hit{
            apply(table_veridp_clone);
        }
    }
}

field_list veridp_clone_field_list{
    veridp_metadata;
}

action do_veridp_clone(){
    clone_ingress_pkt_to_egress( VERIDP_REPORT_SESSION_ID, veridp_clone_field_list);
}
table table_veridp_clone{
    actions{ do_veridp_clone; }
}


action do_veridp_report() { 
    add_header(vlan);
    modify_field(vlan.ethertype,     ethernet.ethertype);
    modify_field(vlan.pcp,           0);
    modify_field(vlan.dei,           0);
    modify_field(vlan.vid,           VERIDP_VLAN_ID);
    modify_field(ethernet.ethertype, ETHERTYPE_VLAN);
}
table table_veridp_report {
    reads{ standard_metadata.instance_type: exact; }
    actions { do_veridp_report; _no_op; }
    size: 1;
}



action rewrite_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
}
table send_frame {
    reads { standard_metadata.egress_port: exact; }
    actions { rewrite_mac; _drop; }
    size: 256;
}

control egress {
    apply(table_veridp_report){
        miss{ apply(send_frame); }
    }
}
