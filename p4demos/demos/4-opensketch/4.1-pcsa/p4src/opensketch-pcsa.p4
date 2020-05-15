
#include "includes/headers.p4"
// #include "includes/metadata.p4"
#include "includes/parser.p4"
#include "includes/sketch-pcsa.p4"


action _drop() { drop(); }
action _no_op(){ no_op(); }

action do_pcsa_hash(){
    // The max range is set to so 2^32-1 so that pcsa_metadata.hash_value holds the original value of the hash function...
    modify_field_with_hash_based_offset(pcsa_metadata.hash_value, 0, pcsa_hash, 4294967295); 
    // bit_and(pcsa_metadata.pcsa_row, pcsa_metadata.hash_value, PCSA_B_MASK);
    shift_right(pcsa_metadata.pcsa_row, pcsa_metadata.hash_value, BITMAP_SIZE_M - PCSA_B);  // Take the PCSA_B highest order bits of hash_value to index bitmap row 
    bit_and(pcsa_metadata.pcsa_leading_zeroes, pcsa_metadata.hash_value, PCSA_B_MASK); // The remaining 28 bits of hash_value
}
table table_pcsa_apply{
    // reads{} // We can add a match on some fields to filter traffic of interest. For the demo, we will apply PCSA to all traffic to determine # distinct flows
    actions{do_pcsa_hash; _no_op;}
}

// Update the PCSA bitmap according to pcsa_row and pcsa_column
action do_pcsa_sketch(zeroes_run){
    modify_field(pcsa_metadata.pcsa_column, zeroes_run);
    register_write(pcsa_bitmap, pcsa_metadata.pcsa_row * BITMAP_SIZE_M + pcsa_metadata.pcsa_column, 1);
}
table table_pcsa_update{ 
    // Look up in the TCAM the length of the zeroes run in pcsa_metadata.pcsa_leading_zeroes and updates the PCSA.
    // Entries are set up so that the first 4 bits (always zero, are excluded)
    reads{ pcsa_metadata.pcsa_leading_zeroes: lpm; }
    actions{ do_pcsa_sketch; _no_op; }
}

control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_pcsa_apply);
            apply(table_pcsa_update);
        }
    }
}

table table_drop {
    actions { _drop; }
}
control egress {
    apply(table_drop);
}
