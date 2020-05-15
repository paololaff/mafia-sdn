
#define VERIDP_BF_SIZE 16
#define MURMUR_H1_MASK        0xFFFF0000   // To get h1(x) // We can actally bit-shift-right the hash...
#define MURMUR_H2_MASK        0x0000FFFF   // To get h2(x)
#define VERIDP_TAG_INDEX_MASK 0x000F       // To get the first 4 bits of gi(x)

#define N_HASH_FUNCS 4
#define SKETCH_SIZE_N N_HASH_FUNCS // NUmber of sketch rows ( = # hash function)
#define SKETCH_SIZE_M 16 // NUmber of sketch columns (eg: # cells per array = 2^HASH_IDX_WIDTH)
#define SKETCH_SIZE 64 // SKETCH_SIZE_N * SKETCH_SIZE_M

field_list hash_field_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

field_list veridp_hash_field_list{
    veridp_metadata.input_port;
    veridp_metadata.switch_id;
    veridp_metadata.output_port;
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

field_list_calculation veridp_bf_hash {
    input {
        veridp_hash_field_list;
    }
    algorithm : murmur_22;
    output_width : 32; 
}