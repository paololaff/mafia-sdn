
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/sample-deterministic.p4"

action _drop() { drop(); }
action _no_op(){ no_op(); }

action do_get_sampling_state(entry_index, n, m, delta, dstAddr, dstPort){
    modify_field(my_sample_metadata.dstAddr,     dstAddr);      // Save destination IP address for the eventual sample
    modify_field(my_sample_metadata.dstPort,     dstPort);      // Save destination TCP port for the eventual sample
    modify_field(my_sample_metadata.entry_index, entry_index);  // Save index of the registers maintaining state
    
    // Save sampling configuration parameters N, M and DELTA
    modify_field(my_sample_metadata.n_config,       n);
    modify_field(my_sample_metadata.m_config,       m);
    modify_field(my_sample_metadata.delta_config,   delta);

    // Read current value of N, M and DELTA for the flow
    register_read(my_sample_metadata.n,     sampling_state_n,       my_sample_metadata.entry_index);
    register_read(my_sample_metadata.m,     sampling_state_m,       my_sample_metadata.entry_index);
    register_read(my_sample_metadata.delta, sampling_state_delta,   my_sample_metadata.entry_index);
    
    add_to_field(my_sample_metadata.n, 1);
    register_write(sampling_state_n, my_sample_metadata.entry_index, my_sample_metadata.n); // We can write back N already
}
table table_get_sampling_state {
    reads {
        ipv4.srcAddr : lpm;
        ipv4.dstAddr : exact;
        ipv4.protocol: exact;
    }
    actions {
        do_get_sampling_state;
        _no_op;
    }
    size : 8;
}



action do_update_sample_taken() { // Write-back # sample taken
    add_to_field(my_sample_metadata.m, 1);
    register_write(sampling_state_m, my_sample_metadata.entry_index, my_sample_metadata.m);
}
table table_sample_take {
    actions { do_update_sample_taken; }
}

action do_update_sample_skipped() { // Write-back # sample skipped
    add_to_field(my_sample_metadata.delta, 1); 
    register_write(sampling_state_delta, my_sample_metadata.entry_index, my_sample_metadata.delta);
}
table table_sample_skip {
    actions { do_update_sample_skipped; }
}

action do_reset_sample_state() { // Reset couters
    register_write(sampling_state_n,     my_sample_metadata.entry_index, 0);
    register_write(sampling_state_m,     my_sample_metadata.entry_index, 0);
    register_write(sampling_state_delta, my_sample_metadata.entry_index, 0);
}
table table_sample_reset {
    actions { do_reset_sample_state; }
}


/* This can be done in do_update_sample_taken */
action do_sample() {
    clone_ingress_pkt_to_egress(SAMPLE_SESSION_ID, sample_metadata_copy); // Clone packet
}
table table_sample {
    actions { do_sample; }
}

control ingress {
    apply(table_get_sampling_state){
        hit{
            if( my_sample_metadata.delta < my_sample_metadata.delta_config ){   apply(table_sample_skip);                      } // Skip DELTA
            else if(my_sample_metadata.m < my_sample_metadata.m_config){        apply(table_sample_take); apply(table_sample); } // Sample M packets
            else if(my_sample_metadata.n == my_sample_metadata.n_config + 1){       apply(table_sample_reset);                     } // Reset N,M and DELTA
        }
    }
}




action do_sample_redirect() {
    add_header(sample_header);
    
    modify_field(sample_header.id,          my_sample_metadata.m);       // The current sample number
    // Also transmit the configuration
    modify_field(sample_header.n,           my_sample_metadata.n_config);
    modify_field(sample_header.m,           my_sample_metadata.m_config);
    modify_field(sample_header.delta,       my_sample_metadata.delta_config);

    modify_field(sample_header.ipProto,     ipv4.protocol);              // Save original IP protocol
    modify_field(sample_header.ipDstAddr,   ipv4.dstAddr);               // Save original destination IP
    modify_field(sample_header.tcpDstPort,  tcp.dstPort);                // Save original destination TCP port
    modify_field(ipv4.protocol,             IPPROTO_SAMPLE);             // Set the IP protocol to that of our custom sampling
    modify_field(ipv4.dstAddr,              my_sample_metadata.dstAddr); // Overwrite the destination IP
    modify_field(tcp.dstPort,               my_sample_metadata.dstPort); // Overwrite the destination TCP port

    // We can add as parameter of the sampling the size of payload to transmit
    //truncate(SIZEOF_SAMPLE_HEADER); 
}

table table_sample_redirect {
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
