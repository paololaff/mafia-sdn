
#define TABLE_INDEX_WIDTH 3 // Number of bits to index the duration register
#define N_FLOWS_ENTRIES 8 // Number of entries for flows (2^3)

header_type devoflow_metadata_t {
  fields {
    byte_count: 32; // The current byte count
    packet_count: 32; // The current packet count
    // The threshold is configured as action param for each table entry by the controller.
    // We load it in metadata so the control loop can do the IF check against the current count
    byte_threshold : 32;
    packet_threshold : 32;

    notification_reason: 8;
    notification_counter_val: 32;
    register_index_bytes: 10;
    register_index_packets: 10;
  }
}
metadata devoflow_metadata_t devoflow_metadata;

register my_byte_counter{ // Custom byte counter register
    width: 32;
    //static: byte_counter_table;
    instance_count: N_FLOWS_ENTRIES;
}
register my_packet_counter{ // Custom packet counter register
    width: 32;
    //static: packet_counter_table;
    instance_count: N_FLOWS_ENTRIES;
}

