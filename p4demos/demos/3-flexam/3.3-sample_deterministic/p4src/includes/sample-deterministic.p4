
// Flexam deterministic sampling: select "m" consecutive packets from each "n" consecutive packets, skipping the first "δ" packets
// k > m + δ

#define SAMPLE_SESSION_ID 999

header_type my_sample_metadata_t {
    fields {
        n           : 16; // # pkts seen 
        m           : 16; // # samples generated 
        delta       : 16; // # samples skipped so far

        n_config    : 16;
        m_config    : 16;
        delta_config: 16;
        
        dstAddr     : 32; // Destination IP for the sample
        dstPort     : 16; // Destination TCP port for the sample
        entry_index : 3;
    }
}
metadata my_sample_metadata_t my_sample_metadata;

field_list sample_metadata_copy {    
    my_sample_metadata;    
    standard_metadata; // For "instance_type" field!
}

register sampling_state_n{     // Keeps state of the "n" packet train
    width: 16;
    instance_count: 8; 
}
register sampling_state_m{     // Keeps counts of the "m" packets selected
    width: 16;
    instance_count: 8; 
}
register sampling_state_delta{ // Keeps counts of the "δ" packets skipped
    width: 16;
    instance_count: 8; 
}