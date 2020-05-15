
// Flexam probabilistic sampling

#define SAMPLE_SESSION_ID 999
#define FAKE_METADATA_SIZE 8096

header_type my_sample_metadata_t {
    fields {
        // Data for counters
        entry_index          : 8;
        n_packets            : 32;
        n_sample             : 32;
        n_no_sample          : 32;

        c_dst_ip             : 32;  // Collector's IP for the sample
        c_dst_port           : 16;  // Collector's TCP port for the sample
        probability          : 16;  // Configured sample probability for this packet
        probability_hash_val : 32;  // Probability from c++ uniform distribution
    }
}
metadata my_sample_metadata_t my_sample_metadata;

header_type my_fake_metadata_t {
    fields {
        fake_field : FAKE_METADATA_SIZE;
    }
}
metadata my_fake_metadata_t my_fake_metadata;
 // This is actually not used in the c++ implementation of the hash func. However,
 // its size is used as the max range of the probability value to be generated: ie p ∈ [0:FAKE_METADATA_SIZE]
field_list sample_probability_fields{
    my_fake_metadata;
}
field_list_calculation probability_hash {
    input {
        sample_probability_fields;
    }
    algorithm : my_uniform_probability;
    output_width : 32; 
}

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
