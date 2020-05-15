
#include "includes/headers.p4"
#include "includes/parser.p4"

#define TABLE_INDEX_WIDTH   10 
#define N_FLOWS_ENTRIES     1024 // Number of entries for flows (2^10)
#define NETSIGHT_VLAN_ID 0xFF
#define NETSIGHT_POSTCARD_SESSION_ID 999

header_type netsight_metadata_t {
  fields {
    switch_id   : 16;
    input_port  : 8;
    output_port : 8;
    postcard_tag: 32;
  }
}
metadata netsight_metadata_t netsight_metadata;

action _drop() { drop(); }
action _no_op(){ no_op(); }

field_list clone_fields_copy {
    netsight_metadata;
    standard_metadata; // For "instance_type" field!
}

action set_nhop(nhop_ipv4, port) {
    modify_field( fwd_metadata.nhop_ipv4, nhop_ipv4 );
    modify_field( standard_metadata.egress_spec, port );
    add_to_field( ipv4.ttl, -1);
}
table ipv4_lpm {
    reads { ipv4.dstAddr : lpm; }
    actions { set_nhop; _drop; }
    size: N_FLOWS_ENTRIES;
}

action set_dmac(dmac) {
    modify_field(ethernet.dstAddr, dmac);
}
table forward {
    reads { fwd_metadata.nhop_ipv4 : exact; }
    actions { set_dmac; _drop; }
    size: 512;
}

action do_netsight_postcard(switch_id, input_port){
    modify_field( netsight_metadata.switch_id,   switch_id );
    modify_field( netsight_metadata.input_port,  input_port );
    modify_field( netsight_metadata.output_port, standard_metadata.egress_spec );

    clone_ingress_pkt_to_egress( NETSIGHT_POSTCARD_SESSION_ID, clone_fields_copy );
}
table table_netsight{
    reads{
        ethernet.srcAddr:  exact;
    }
    actions{
        do_netsight_postcard;
        _no_op;
    }
}

control ingress {
    apply( ipv4_lpm );
    apply( forward );
    apply( table_netsight );
}




action do_postcard(payload_size_trunc) { 
    add_header(vlan);
    modify_field( vlan.ethertype,     ethernet.ethertype);
    modify_field( vlan.pcp,           VLAN_PCP_BESTEFFORT);
    modify_field( vlan.dei,           0);
    modify_field( vlan.vid,           NETSIGHT_VLAN_ID); // Set the VID as the rolled probability for the sample :)
    modify_field( ethernet.ethertype, ETHERTYPE_VLAN);

    // Tag the MAC destination address with the postcard info...
    modify_field( ethernet.dstAddr, 0);
    modify_field( netsight_metadata.postcard_tag,   netsight_metadata.input_port);
    shift_left  ( netsight_metadata.postcard_tag,   netsight_metadata.postcard_tag, 16); // make space for 16-bit switch id
    bit_or      ( netsight_metadata.postcard_tag,   netsight_metadata.postcard_tag, netsight_metadata.switch_id);
    shift_left  ( netsight_metadata.postcard_tag,   netsight_metadata.postcard_tag, 8); // make space for 8-bit output port
    bit_or      ( netsight_metadata.postcard_tag,   netsight_metadata.postcard_tag, netsight_metadata.output_port);
    modify_field( ethernet.dstAddr,                 netsight_metadata.postcard_tag);    // Tag the destination MAC address with the tag

    truncate(SIZEOF_POSTCARD_H + payload_size_trunc);
}
table table_postcard {
    reads{ standard_metadata.instance_type: exact; }
    actions { do_postcard; _no_op; }
    size : N_FLOWS_ENTRIES;
}



action rewrite_mac(smac) {
    modify_field( ethernet.srcAddr, smac );
}
table send_frame {
    reads { standard_metadata.egress_port: exact; }
    actions { rewrite_mac; _drop; }
    size: 256;
}

control egress {
    apply(table_postcard){
        miss{ apply(send_frame); }
    }
}
