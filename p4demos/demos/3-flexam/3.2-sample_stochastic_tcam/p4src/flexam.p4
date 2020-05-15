
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/sample-stochastic.p4"

action _drop() { drop(); }
action _no_op(){ no_op(); }
 
action do_check_sample(p, dstAddr, dstPort, entry_index){
    modify_field(my_sample_metadata.entry_index,    entry_index);    // Save register entry index
    modify_field(my_sample_metadata.c_dst_ip,       dstAddr);        // Save destination IP address for the eventual sample
    modify_field(my_sample_metadata.c_dst_port,     dstPort);        // Save destination TCP port for the eventual sample
    modify_field(my_sample_metadata.probability,    p);              // Save sample probability for this packet
    
    modify_field_rng_uniform(my_sample_metadata.hash_val, 0, 65536); //4294967295); // Generate an uniform hash in range

    // Increment counter of total number of packets
    register_read(my_sample_metadata.n_packets, my_counter_total, my_sample_metadata.entry_index);
    add_to_field(my_sample_metadata.n_packets, 1);
    register_write(my_counter_total, my_sample_metadata.entry_index, my_sample_metadata.n_packets);
}
table table_check_sample { // Stores flow entries that needs to be sampled
    reads {
        ipv4.srcAddr : lpm;
        ipv4.dstAddr : exact;
        ipv4.protocol: exact;
    }
    actions {
        do_check_sample;
        _no_op;
    }
    size : 1024;
}

action do_apply_sample_probability(p) { // Saves the rolled probability
    modify_field(my_sample_metadata.p, p);
}
table table_sample_probability { // Applies ternary-match table storing powering-of-2 probabilities
    reads{ my_sample_metadata.hash_val: ternary; }
    actions { do_apply_sample_probability; _no_op; }
}

action do_sample() {
    clone_ingress_pkt_to_egress(SAMPLE_SESSION_ID, sample_metadata_copy); // Clone packet
    // Increment counter of #sample been generated
    register_read(my_sample_metadata.n_sample, my_counter_sample, my_sample_metadata.entry_index);
    add_to_field(my_sample_metadata.n_sample, 1);
    register_write(my_counter_sample, my_sample_metadata.entry_index, my_sample_metadata.n_sample);
}
table table_sample { // Called if the rolled probability was lower than the configured one
    actions { do_sample; }
}

action do_no_sample() { // Only increments counter for #packets not sampled
    register_read(my_sample_metadata.n_no_sample, my_counter_no_sample, my_sample_metadata.entry_index);
    add_to_field(my_sample_metadata.n_no_sample, 1);
    register_write(my_counter_no_sample, my_sample_metadata.entry_index, my_sample_metadata.n_no_sample);
}
table table_no_sample { // Called on packets not selected for sample. Not mandatory
    actions { do_no_sample; }
}

control ingress {
    apply(table_check_sample){
        hit{
            apply(table_sample_probability);
            if(my_sample_metadata.p >= my_sample_metadata.probability){ apply(table_sample); }
            else{ apply(table_no_sample); }
        }
    }
}


action do_sample_redirect() {
    add_header(vlan);
    // modify_field(sample_header.ipProto,     ipv4.protocol);                 // Save original IP protocol
    // modify_field(sample_header.ipDstAddr,   ipv4.dstAddr);                  // Save original destination IP
    // modify_field(sample_header.tcpDstPort,  tcp.dstPort);                   // Save original destination TCP port
    // modify_field(sample_header.probability, my_sample_metadata.probability);// 
    // modify_field(ipv4.protocol,             IPPROTO_SAMPLE);                // Set the IP protocol to that of our custom sampling
    // modify_field(ipv4.dstAddr,              my_sample_metadata.ipDstAddr);  // Overwrite the destination IP
    // modify_field(tcp.dstPort,               my_sample_metadata.tcpDstPort); // Overwrite the destination TCP port

    modify_field(vlan.ethertype,     ethernet.ethertype);
    modify_field(vlan.pcp,           VLAN_PCP_BESTEFFORT);
    modify_field(vlan.dei,           0);
    modify_field(vlan.vid,           my_sample_metadata.probability); // Set the VID as the rolled probability for the sample :)
    modify_field(ethernet.ethertype, ETHERTYPE_VLAN);
    
    // We can add as parameter of the sampling the size of payload to transmit
    //truncate(SIZEOF_SAMPLE_HEADER); 
}

table table_sample_redirect { // Matches a sample clone
    reads{ standard_metadata.instance_type: exact; }
    actions { do_sample_redirect; _no_op; }
}

table table_drop {
    actions { _drop; }
}

// We invoke the forwarding table on normal packets only on a miss of the sampling table. 
// Otherwise the sample will not find an entry and the _drop action will be called...
control egress {
    apply(table_sample_redirect){
        miss{ apply(table_drop); }
    }    
}
