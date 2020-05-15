
/*  DDoS detection implementation using technique presented in OpenSkech */
/*  Count-Min sketch + bitmap */

// Brief description: a count min sketch hashing on each packet's ipv4.srcAddr whose counters are replaced with bitmaps indexed by an hash function
//                    on the ipv4.dstAddr. The original OpenSketch paper also performs sampling of packets to reduce memory usage...

// #define N_BITMAP_HASH 1                      // Not really needed
#define BITMAP_SIZE           64
#define BITMAP_HASH_WIDTH     6               // To index 64 bits...

#define N_COUNTMIN_HASH       4               // Number of hash functions for the countmin sketch
#define COUNTMIN_SIZE_N       N_SKETCH_HASH   // NUmber of sketch rows ( = # hash function)
#define COUNTMIN_SIZE_M       16              // NUmber of sketch columns (eg: # cells per array = 2^HASH_IDX_WIDTH)
#define COUNTMIN_HASH_WIDTH   4               // To index each cell in a sketch row (SKETCH_SIZE_M)
#define COUNTMIN_SIZE         64              // COUNTMIN_SIZE_N * COUNTMIN_SIZE_M

#define DDOS_SKETCH_SIZE      4096            // COUNTMIN_SIZE * BITMAP_SIZE

header_type ssd_metadata_t {
    fields {
        bitmap_idx:     COUNTMIN_HASH_WIDTH;
        countmin_idx_1: COUNTMIN_HASH_WIDTH;
        countmin_idx_2: COUNTMIN_HASH_WIDTH;
        countmin_idx_3: COUNTMIN_HASH_WIDTH;
        countmin_idx_4: COUNTMIN_HASH_WIDTH;
    }
}
metadata ssd_metadata_t ssd_metadata;

/* COUNT-MIN SKETCH */
register ssd_sketch{
    width:          BITMAP_SIZE;
    instance_count: COUNTMIN_SIZE;
}

/* Might be interesting to keep track the # of bits set in the bitmaps of each count-min sketch cell, so that we don't need to export the would structure? */
/* Because: "the number of unique elements of the bitmap can be estimated with b×ln(b/z) where z is the number of unset bits" [OpenSketch] */
// register bitmap_n_bit_set{
//     width:          BITMAP_HASH_WIDTH;
//     instance_count: COUNTMIN_SIZE;
// }

// HASH FUNCTIONS //

field_list countmin_hash_field_list {
    ipv4.srcAddr;
}
field_list bitmap_hash_field_list {
    ipv4.dstAddr;
}

/* HASHES FOR THE BITMAP */
field_list_calculation bitmap_hash {
    input {
        bitmap_hash_field_list;
    }
    algorithm : hash_ex;
    output_width : BITMAP_HASH_WIDTH;
}

/* HASHES FOR THE COUNTMIN SKETCH */
field_list_calculation countmin_hash_1 {
    input {
        countmin_hash_field_list;
    }
    algorithm : murmur_1;
    output_width : COUNTMIN_HASH_WIDTH;
}
field_list_calculation countmin_hash_2 {
    input {
        countmin_hash_field_list;
    }
    algorithm : murmur_2;
    output_width : COUNTMIN_HASH_WIDTH;
}
field_list_calculation countmin_hash_3 {
    input {
        countmin_hash_field_list;
    }
    algorithm : murmur_3;
    output_width : COUNTMIN_HASH_WIDTH;
}
field_list_calculation countmin_hash_4 {
    input {
        countmin_hash_field_list;
    }
    algorithm : murmur_4;
    output_width : COUNTMIN_HASH_WIDTH;
}




