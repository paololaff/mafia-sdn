
#define TABLE_INDEX_WIDTH 3 // Number of bits to index the duration register
#define N_FLOWS_ENTRIES 8 // Number of entries for flow (2^3)

header_type my_metadata_t {
    fields {
        nhop_ipv4: 32;
        pkt_ts: 48; // Loaded with intrinsic metadata: ingress_global_timestamp
        tmp_ts: 48; // Temporary variable to load start_ts    
        pkt_count: 32;
        byte_count: 32;
        register_index: TABLE_INDEX_WIDTH;
    }
}
metadata my_metadata_t my_metadata;



register my_byte_counter {
    width: 32;
    instance_count: N_FLOWS_ENTRIES;
}

register my_packet_counter {
    width: 32;
    instance_count: N_FLOWS_ENTRIES;
}

register start_ts{
    width: 48;
    instance_count: N_FLOWS_ENTRIES;
}
register last_ts{
    width: 48;
    instance_count: N_FLOWS_ENTRIES;
}
register flow_duration{ // Optional register...Duration can be derived from the two timestamp
    width: 48;
    static: duration_table;
    instance_count: N_FLOWS_ENTRIES;
}
