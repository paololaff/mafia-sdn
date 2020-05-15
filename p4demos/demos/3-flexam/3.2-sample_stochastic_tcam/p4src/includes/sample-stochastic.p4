
// Flexam probabilistic sampling

#define SAMPLE_SESSION_ID 999

header_type my_sample_metadata_t {
    fields {
        // Data for counters
        entry_index    : 8;
        n_packets      : 32;
        n_sample       : 32;
        n_no_sample    : 32;

        c_dst_ip       : 32;  // Collector's IP for the sample
        c_dst_port     : 16;  // Collector's TCP port for the sample
        probability    : 16;  // Configured sample probability for this packet
        hash_val       : 32;  // rng uniform hash
        p              : 16;  // pkt current probability
    }
}
metadata my_sample_metadata_t my_sample_metadata;

field_list sample_metadata_copy {
    my_sample_metadata;    
    standard_metadata; // For "instance_type" field!
}

register my_counter_total{ // Counts how many packets flow by...
    width: 32;
    instance_count: 8;
}
register my_counter_sample{ // Counts how many samples get generated for a flow entry
    width: 32;
    instance_count: 8;
}
register my_counter_no_sample{ // Counts how many packets pass through without generating a sample
    width: 32;
    instance_count: 8;
}
