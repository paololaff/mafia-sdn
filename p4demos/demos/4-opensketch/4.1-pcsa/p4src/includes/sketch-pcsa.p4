
/* PCSA SKETCH: https://research.neustar.biz/2013/04/02/sketch-of-the-day-probabilistic-counting-with-stochastic-averaging-pcsa/ */

// NOTE: instead of indexing the bitmap using the B lowest order bits and calculating the #zeroes as seen starting from bit B+1,
//       we do the opposite. The B higher order bits are used to index and the zeroes run is calculated from the B+1 highest bit.
//       Doing this way, the calculation of the length of the zeroes-run is easier using an LPM lookup 

#define BIT 1
// #define PCSA_B 3 // PCSA_B recommended to be in [4..16]
#define PCSA_B 4
#define BITMAP_SIZE_N 16  // Number of PCSA rows (has to be 2^PCSA_B)
#define BITMAP_SIZE_M 32  // Number of sketch columns (eg: # cells per array: 32 x 1bit = 32bit bitmaps) 

// #define BITMAP_SIZE_FULL 256 // BITMAP_SIZE_N x BITMAP_SIZE_M -----> 8 * 32  // BIG register to represent the N x M bitmaps of the sketch...
#define BITMAP_SIZE_FULL 512    // BITMAP_SIZE_N x BITMAP_SIZE_M -----> 16 * 32 // BIG register to represent the N x M bitmaps of the sketch...

// #define PCSA_B_3_MASK_16 0x00001FFF // Masks out the PCSA_B=3 highest-order bits of the packet hash // Use this when BITMAP_SIZE_M=16
// #define PCSA_B_3_MASK_32 0x1FFFFFFF // Masks out the PCSA_B=3 highest-order bits of the packet hash // Use this when BITMAP_SIZE_M=32
// #define PCSA_B_4_MASK_16 0x00000FFF // Masks out the PCSA_B=4 highest-order bits of the packet hash // Use this when BITMAP_SIZE_M=16
#define PCSA_B_4_MASK_32 0x0FFFFFFF // Masks out the PCSA_B=4 highest-order bits of the packet hash // Use this when BITMAP_SIZE_M=32

#define PCSA_B_MASK PCSA_B_4_MASK_32

header_type pcsa_metadata_t {
  fields {
    hash_value: 32;           // Same width has the pcsa_hash algorithm (v. pcsa-sketch.p4)
    pcsa_row: 8;              // Will be loaded with the value of the PCSA_B highest-order bits of pcsa_hash (v. pcsa-sketch.p4 for PCSA_B declaration)
    pcsa_leading_zeroes: 32;  // The remaining (32-4)=28 bits are used to determine the length of the zero-series. Still is 32 bit wide to allow matching against a CIDR block
    pcsa_column: 8;           // Holds the number of the leading zeroes in pcsa_leading_zeroes. 
  }
}
metadata pcsa_metadata_t pcsa_metadata;

// Packet header fields to hash upon
field_list hash_field_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

// HASH FUNCTION //
field_list_calculation pcsa_hash {
    input {
        hash_field_list;
    }
    // Not sure how much the width of the hash is relevant (i'll set it to be equal to the size of a bitmap array: BITMAP_SIZE_M=32) 
    algorithm : hash_ex;    
    output_width : BITMAP_SIZE_M; // Highest order PCSA_B=4 bits are used to determine the Nth bitmap array to be updated
}

// PCSA SKETCH REGISTERS/BITMAPS //
register pcsa_bitmap{
    // This is actually a structure which comprises BITMAP_SIZE_N arrays with BITMAP_SIZE_M bits each
    width: BIT;
    instance_count: BITMAP_SIZE_FULL;
}
