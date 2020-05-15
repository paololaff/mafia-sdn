

#define N_HASH_FUNCS 4
#define HASH_IDX_WIDTH 3
#define SKETCH_SIZE_N N_HASH_FUNCS // NUmber of sketch rows ( = # hash function)
#define SKETCH_SIZE_M 8 // Number of sketch columns (eg: # cells per array = 2^HASH_IDX_WIDTH)
#define SKETCH_SIZE 32 // SKETCH_SIZE_N * SKETCH_SIZE_M

/* CountSketch Update: sketch[i][Hi(x)]=Gi(x)*val */
/* Hi(x): murmur hash functions over 5-tuple: */
/* Gi(x): binary hash functions over 64-bit hash of the 5-tuple */

header_type countsketch_metadata_t {
    fields{
        flowkey     : 64; // 64-bit hash of the packet 5-tuple to be passed as input to the binary hashes
        // The following can have value of 0 or 1. If 0, we will decrement the sketch cell by -1 instead of incrmenting +1
        g1_x: 1;
        g2_x: 1;
        g3_x: 1;
        g4_x: 1;
        // The following indexes determines, for each sketch row, the cells to be updated (ie, the column).
        h1_x: HASH_IDX_WIDTH;
        h2_x: HASH_IDX_WIDTH;
        h3_x: HASH_IDX_WIDTH;
        h4_x: HASH_IDX_WIDTH;

        countsketch_val: 32;
  }
}
metadata countsketch_metadata_t countsketch_metadata;

/* COUNT-MIN SKETCH */
register count_sketch{
    width: 32;
    instance_count: SKETCH_SIZE;
}

// HASH FUNCTIONS //
// Packet header fields to hash upon
field_list flowkey_field_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

field_list_calculation flow_key_hash {
    input { flowkey_field_list; }
    algorithm : bmv2_hash;
    output_width : 64;
}

field_list g_x_hash_field {
    countsketch_metadata.flowkey;
}
field_list_calculation g1_x_hash {
    input { g_x_hash_field; }
    algorithm : my_binary_hash_1;
    output_width : 32;
}

field_list_calculation g2_x_hash {
    input { g_x_hash_field; }
    algorithm : my_binary_hash_2;
    output_width : 32;
}

field_list_calculation g3_x_hash{
    input { g_x_hash_field; }
    algorithm : my_binary_hash_3;
    output_width : 32;
}

field_list_calculation g4_x_hash {
    input { g_x_hash_field; }
    algorithm : my_binary_hash_4;
    output_width : 32;
}



field_list_calculation h1_x_hash {
    input { flowkey_field_list; }
    algorithm : murmur_1;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation h2_x_hash {
    input { flowkey_field_list; }
    algorithm : murmur_2;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation h3_x_hash {
    input { flowkey_field_list; }
    algorithm : murmur_3;
    output_width : HASH_IDX_WIDTH;
}
field_list_calculation h4_x_hash {
    input { flowkey_field_list; }
    algorithm : murmur_4;
    output_width : HASH_IDX_WIDTH;
}

