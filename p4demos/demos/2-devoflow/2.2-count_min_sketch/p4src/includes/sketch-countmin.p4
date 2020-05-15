

#define N_HASH_FUNCS 4
#define HASH_IDX_WIDTH 4
#define SKETCH_SIZE_N N_HASH_FUNCS // NUmber of sketch rows ( = # hash function)
#define SKETCH_SIZE_M 16 // NUmber of sketch columns (eg: # cells per array = 2^HASH_IDX_WIDTH)
#define SKETCH_SIZE 64 // SKETCH_SIZE_N * SKETCH_SIZE_M


header_type my_metadata_t {
  fields {
    nhop_ipv4: 32;
    // Only one of this metdata field is strictly necessary...However they might be required if we want to implement in the control
    // loop some additional logic, eg. to determine the minimum value in the sketch for the current packet's flow.
    sketch_idx_1: HASH_IDX_WIDTH;
    sketch_idx_2: HASH_IDX_WIDTH;
    sketch_idx_3: HASH_IDX_WIDTH;
    sketch_idx_4: HASH_IDX_WIDTH;
    sketch_count_1: 32;
    sketch_count_2: 32;
    sketch_count_3: 32;
    sketch_count_4: 32;
  }
}
metadata my_metadata_t my_metadata;

/* COUNT-MIN SKETCH */
register count_min_sketch{
    width: 32;
    instance_count: SKETCH_SIZE;
}

// HASH FUNCTIONS //
// Packet header fields to hash upon
field_list hash_field_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

field_list_calculation hash_1 {
    input {
        hash_field_list;
    }
    algorithm : murmur_1;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_2 {
    input {
        hash_field_list;
    }
    algorithm : murmur_2;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_3 {
    input {
        hash_field_list;
    }
    algorithm : murmur_3;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_4 {
    input {
        hash_field_list;
    }
    algorithm : murmur_4;
    output_width : HASH_IDX_WIDTH;
}

