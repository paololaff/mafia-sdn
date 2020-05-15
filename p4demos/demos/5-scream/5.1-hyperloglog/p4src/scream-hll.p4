
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/sketch-hyperloglog.p4"


action _drop() { drop(); }
action _no_op(){ no_op(); }

action do_hll_hash(){
    // The max range is set to so 2^32-1 so that my_metadata.hash_value holds the original value of the hash function...
    modify_field_with_hash_based_offset(my_metadata.hash, 0, hll_hash, 4294967295); 
    // bit_and(my_metadata.pcsa_row, my_metadata.hash_value, PCSA_B_MASK);
    shift_right(my_metadata.hll_index, my_metadata.hash, HLL_HASH_WIDTH - HLL_B);  // Take the HLL_B highest order bits of hll_hash to index the sketch
    bit_and(my_metadata.hll_hash_zeroes, my_metadata.hash, HLL_B_MASK); // The remaining 26 bits of hll_hash
}
table table_hll_apply{
    // reads{} // We can add a match on some fields to filter traffic of interest. For the demo, we will apply PCSA to all traffic to determine # distinct flows
    actions{do_hll_hash; _no_op;}
}

// Save the length of zeroes of the current packet hash and read the current value from the sketch
action do_hll_save_zeroes(zeroes_run){
    modify_field(my_metadata.hll_zeroes_new, zeroes_run);
    register_read(my_metadata.hll_zeroes_old, hll_sketch, my_metadata.hll_index);
}
// Look up in the TCAM the length of the zeroes run in my_metadata.hll_hash_zeroes.
table table_hll_lookup_zeroes{     
    reads{ my_metadata.hll_hash_zeroes: lpm; }
    actions{ do_hll_save_zeroes; _no_op; }
}

// Update the HLL sketch if the new zeroes length is bigger than the previously stored one
action do_hll_update(){
    register_write(hll_sketch, my_metadata.hll_index, my_metadata.hll_zeroes_new);
}
table table_hll_update{ 
    actions{ do_hll_update; }
}

control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_hll_apply);
            apply(table_hll_lookup_zeroes);
            if(my_metadata.hll_zeroes_new > my_metadata.hll_zeroes_old){ apply(table_hll_update); }
        }
    }
}

table table_drop {
    actions { _drop; }
}
control egress {
    apply(table_drop);
}
