
#include "hash.p4"

header_type my_metadata_t {
  fields {
    nhop_ipv4: 32;
    threshold: 32;
    bf_idx_1: HASH_IDX_WIDTH;
    bf_idx_2: HASH_IDX_WIDTH;
    bf_idx_3: HASH_IDX_WIDTH;
    bf_idx_4: HASH_IDX_WIDTH;
    bf_val_1: 1;
    bf_val_2: 1;
    bf_val_3: 1;
    bf_val_4: 1;
    sketch_idx_1: HASH_IDX_WIDTH;
    sketch_idx_2: HASH_IDX_WIDTH;
    sketch_idx_3: HASH_IDX_WIDTH;
    sketch_idx_4: HASH_IDX_WIDTH;
    sketch_val_1: 32;
    sketch_val_2: 32;
    sketch_val_3: 32;
    sketch_val_4: 32;
    sketch_val_min: 32;
    global_counter_val: 32;
    flow_counter_idx: 8;
    flow_counter_val: 32;
  }
}
metadata my_metadata_t my_metadata;

/* GLOBAL COUNTER OF THE SWITCH PORT */
register global_counter{
    width: 64;
    instance_count: 1;
}

/* COUNTERS FOR THE EXACT FLOW VOLUMES */
register flow_counter{
    width: 64;
    instance_count: 128;
}

/* COUNT-MIN SKETCH */
register count_min_sketch{
    width: 32;
    instance_count: SKETCH_SIZE;
}

/* BLOOM FILTER */
register bloom_filter{
    width: 1;
    instance_count: BLOOM_FILTER_SIZE;
}
