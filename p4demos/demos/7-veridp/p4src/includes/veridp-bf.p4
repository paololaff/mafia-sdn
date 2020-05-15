
/*
    [From Section 5 of VeriDP paper]
    VeriDP Bloom Filter operations:
    First, three hashes are constructed as g_i(x) = h1(x)+ih2(x) for i = 0, 1, 2;
    where h1(x) and h2(x) are the two halves of a 32-bit Murmur3 hash of x.
    Then, we use the first 4 bits of g_i(x) to set the 16-bit Bloom filter for i = 0, 1, 2.
*/

#define VERIDP_BF_SIZE 16

#define MURMUR_H1_MASK        0xFFFF0000   // To get h1(x) // We can actally bit-shift-right the hash...
#define MURMUR_H2_MASK        0x0000FFFF   // To get h2(x)
#define VERIDP_TAG_INDEX_MASK 0x000F       // To get the first 4 bits of gi(x)

// We also need the network entry switch to select packets upon which to perform the verification.
// These switches will need to maintain a register holding the time where the last packet of a flow was selected,
// and probably also an additional table that defines their index inside the register. (or maybe only a sketch?)
#define VERIDP_SAMPLE_INTERVAL 100000 // 100 ms
#define VERIDP_TAG_TOS_MASK    0x01   // To mask the highest order bit of the ToS
#define VERIDP_NUM_FLOWS       1024

header_type veridp_metadata_t{
    fields{
        /* Metadata for time-based sampling check */
        entry_index : 10;
        ts          : 48;
        ts_last     : 48;
        marker      : 1;    // Flag indicating that route verification is enabled for this packet.

        /* Metadata for BF tag calculation */
        input_port  : 8;    // Input port where the packet was received at this switch
        output_port : 8;    // Output port where the packet was forwarded to from this switch
        switch_id   : 8;
        bf_index_0  : 4;
        bf_index_1  : 4;
        bf_index_2  : 4;
        murmur_hash : 32;   // murmur hash
        bf_tag_value: VERIDP_BF_SIZE;

        /* See description on top: */
        h1_x        : 16;
        h2_x        : 16;
        g0_x        : 16;
        g1_x        : 16;
        g2_x        : 16;
        
    }
}
metadata veridp_metadata_t veridp_metadata;

register veridp_sample_timestamps{
    width: 48;
    instance_count: VERIDP_NUM_FLOWS;
}

field_list veridp_hash_field_list{
    veridp_metadata.input_port;
    veridp_metadata.switch_id;
    veridp_metadata.output_port;
}

field_list_calculation veridp_bf_hash {
    input {
        veridp_hash_field_list;
    }
    algorithm : murmur_7;
    output_width : 32; 
}

// register veridp_bf_tag{
//     width: 1;
//     instance_count: VERIDP_BF_SIZE;
// }

// // This action reset the above register...
// action do_reset_veridp_bf_register(){
//     register_write(veridp_bf_tag, 0, 0);
//     register_write(veridp_bf_tag, 1, 0);
//     register_write(veridp_bf_tag, 2, 0);
//     register_write(veridp_bf_tag, 3, 0);
//     register_write(veridp_bf_tag, 4, 0);
//     register_write(veridp_bf_tag, 5, 0);
//     register_write(veridp_bf_tag, 6, 0);
//     register_write(veridp_bf_tag, 7, 0);
//     register_write(veridp_bf_tag, 8, 0);
//     register_write(veridp_bf_tag, 9, 0);
//     register_write(veridp_bf_tag, 10, 0);
//     register_write(veridp_bf_tag, 11, 0);
//     register_write(veridp_bf_tag, 12, 0);
//     register_write(veridp_bf_tag, 13, 0);
//     register_write(veridp_bf_tag, 14, 0);
//     register_write(veridp_bf_tag, 15, 0);    
// }