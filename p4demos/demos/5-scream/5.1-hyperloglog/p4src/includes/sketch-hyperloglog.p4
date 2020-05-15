
/* HLL SKETCH: https://research.neustar.biz/2012/10/25/sketch-of-the-day-hyperloglog-cornerstone-of-a-big-data-infrastructure/ */

// NOTE: instead of indexing the bitmap using the B lowest order bits and calculating the #zeroes as seen starting from bit B+1,
//       We do the opposite:
//       The B higher order bits are used to index and the zeroes run is calculated from the B+1 highest bit.
//       Doing this way, the calculation of the length of the zeroes-run is easier using an LPM lookup with the TCAM

#define HLL_B               6           // HLL_B recommended to be in [4..16]
#define HLL_B_MASK          0x03FFFFFF  // Masks out the HLL_B=6 highest-order bits of the 32-bits packet hash
#define HLL_SKETCH_SIZE     64          // 2^HLL_B -----> 2^6 = 64 entries
#define HLL_ENTRY_WIDTH     5           // Maximum value held in a HLL cell is equal to #bits used to get the length of te run of zeroes (32-6=26; 2^5=32)
#define HLL_HASH_WIDTH      32          // 


header_type my_metadata_t {
  fields {
    hash:               HLL_HASH_WIDTH;   // Same width as IP address
    hll_index:          HLL_B;            // Will be loaded with the value of the HLL_B highest-order bits of hash
    hll_hash_zeroes:    HLL_HASH_WIDTH;   // The remaining (32-6)=26 bits are used to determine the length of the zero-series. Still is 32 bit wide to allow matching against a CIDR block
    hll_zeroes_new:     HLL_ENTRY_WIDTH;  // The run of zeroes for the current packet// Screw byte-alignment warnings :D
    hll_zeroes_old:     HLL_ENTRY_WIDTH;  // The run of zeroes saved in the sketch // Screw byte-alignment warnings :D
  }
}

metadata my_metadata_t my_metadata;

// Packet header fields to hash upon
field_list hash_field_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}

// HASH FUNCTION //
field_list_calculation hll_hash {
    input {
        hash_field_list;
    }
    algorithm : hash_ex;    
    output_width : HLL_HASH_WIDTH; // Highest order PCSA_B=4 bits are used to determine the Nth bitmap array to be updated
}

// PCSA SKETCH REGISTERS/BITMAPS //
register hll_sketch{
    // This is actually a structure which comprises BITMAP_SIZE_N arrays with BITMAP_SIZE_M bits each
    width: HLL_ENTRY_WIDTH;
    instance_count: HLL_SKETCH_SIZE;
}
