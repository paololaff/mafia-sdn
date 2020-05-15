table t_hll_hash_tcam_lookup_zeroes{
 reads{
     mafia_metadata.hll_hash_lo: exact;
 }
 actions{
     a_hll_hash_tcam_lookup_zeroes;
 }
}
table t_hll_hash{
 actions{
     a_hll_hash;
 }
}
table t_hll_sketch{
 actions{
     a_hll_sketch;
 }
}


table t_hll_hash_process_lo{
 actions{
     a_hll_hash_process_lo;
 }
}
table t_hll_hash_process_hi{
 actions{
     a_hll_hash_process_hi;
 }
}
table t_hll_sketch_index{
 actions{
     a_hll_sketch_index;
 }
}
table t_hll_sketch_value{
 actions{
     a_hll_sketch_value;
 }
}