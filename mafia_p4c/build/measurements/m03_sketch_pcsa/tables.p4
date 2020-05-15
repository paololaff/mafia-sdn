table t_pcsa_hash_tcam_lookup_zeroes_pcsa_sketch{
 reads{
     mafia_metadata.pcsa_hash_0: exact;
 }
 actions{
     a_pcsa_hash_tcam_lookup_zeroes_pcsa_sketch;
 }
}
table t_pcsa_sketch{
 actions{
     a_pcsa_sketch;
 }
}
table t_pcsa_hash_pcsa_sketch{
 actions{
     a_pcsa_hash_pcsa_sketch;
 }
}
