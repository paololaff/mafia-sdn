
#define N_HASH_FUNCS 4
#define HASH_IDX_WIDTH 4
#define SKETCH_SIZE_N N_HASH_FUNCS // NUmber of sketch rows ( = # hash function)
#define SKETCH_SIZE_M 16 // NUmber of sketch columns (eg: # cells per array = 2^HASH_IDX_WIDTH)
#define SKETCH_SIZE 64 // SKETCH_SIZE_N * SKETCH_SIZE_M
#define BLOOM_FILTER_SIZE 64 


// HASH FUNCTIONS //
// Packet header fields to hash upon
field_list hash_field_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

field_list_calculation hash_flow_counter {
    input {
        hash_field_list;
    }
    algorithm : hash_ex;
    output_width : HASH_IDX_WIDTH;
}

field_list_calculation hash_sketch_1 {
    input {
        hash_field_list;
    }
    algorithm : murmur_1;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_sketch_2 {
    input {
        hash_field_list;
    }
    algorithm : murmur_2;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_sketch_3 {
    input {
        hash_field_list;
    }
    algorithm : murmur_3;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_sketch_4 {
    input {
        hash_field_list;
    }
    algorithm : murmur_4;
    output_width : HASH_IDX_WIDTH;
}

field_list_calculation hash_bf_1 {
    input {
        hash_field_list;
    }
    algorithm : murmur_5;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_bf_2 {
    input {
        hash_field_list;
    }
    algorithm : murmur_6;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_bf_3 {
    input {
        hash_field_list;
    }
    algorithm : murmur_7;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation hash_bf_4 {
    input {
        hash_field_list;
    }
    algorithm : murmur_8;
    output_width : HASH_IDX_WIDTH;
}

