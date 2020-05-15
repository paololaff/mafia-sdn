
#define HASH_IDX_WIDTH 4

header_type veridp_metadata_t{
    fields{
        /* Metadata for BF tag calculation */
        input_port  : 8;    // Input port where the packet was received at this switch
        output_port : 8;    // Output port where the packet was forwarded to from this switch
        switch_id   : 8;        
        bf_index_0  : 4;
        bf_index_1  : 4;
        bf_index_2  : 4;
        murmur_hash : 32;   // murmur hash
        bf_tag_value: 16;

        h1_x        : 16;
        h2_x        : 16;
        g0_x        : 16;
        g1_x        : 16;
        g2_x        : 16;
    }
}

header_type mafia_sketch_metadata_t{
    fields{
        sketch_idx_1: HASH_IDX_WIDTH;
        sketch_idx_2: HASH_IDX_WIDTH;
        sketch_idx_3: HASH_IDX_WIDTH;
        sketch_idx_4: HASH_IDX_WIDTH;
        sketch_val_1: 32;
        sketch_val_2: 32;
        sketch_val_3: 32;
        sketch_val_4: 32;
    }
}


header_type intrinsic_metadata_t {
    fields {
        ingress_global_timestamp : 48;
        lf_field_list : 32;
        mcast_grp : 16;
        egress_rid : 16;
    }
}

header_type fwd_metadata_t {
  fields {
    nhop_ipv4   : 32;
  }
}

metadata fwd_metadata_t fwd_metadata;
metadata veridp_metadata_t veridp_metadata;
metadata intrinsic_metadata_t intrinsic_metadata;
metadata mafia_sketch_metadata_t sketch_metadata;

