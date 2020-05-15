
#include "hash.p4"

#define TOPKC_TAG_TOS_MASK    0x01   // To mask the highest order bit of the ToS
#define TOPKC_NUM_FLOWS       1024

header_type topkc_hop_metadata_t{
    fields{
        marker      : 1;
        q_time      : 48;
        q_length    : 16;
        // enq_timestamp : 48;
        // enq_qdepth : 16;
        // deq_timedelta : 32;
        // deq_qdepth : 16;
    }
}
metadata topkc_hop_metadata_t topkc_hop_metadata;



header_type topkc_sketch_metadata_t{
    fields{
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
metadata topkc_sketch_metadata_t topkc_sketch_metadata;

/* COUNT-MIN SKETCHES */
register sketch_n_packets{
    width: 32;
    instance_count: SKETCH_SIZE;
}

register sketch_q_lengths{
    width: 32;
    instance_count: SKETCH_SIZE;
}
