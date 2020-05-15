
#include "headers.p4"
#include "tables.p4"
#include "../../routing.p4"
#include "../../parser.p4"



field_list rng_input {
  rng_metadata;
}
field_list pcsa_hash_fields {
  ipv4.src; ipv4.dst; tcp.src; tcp.dst; ipv4.protocol;
}
register pcsa_sketch {
  width: 1;
  instance_count: 512;
}

field_list_calculation pcsa_hash_1 {
  input{ pcsa_hash_fields; }
  algorithm: hash_ex;
  output_width: 32;
}
field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}
field_list_calculation uniform_probability_hash {
  input{ rng_input; }
  algorithm: my_uniform_probability;
  output_width: 32;
}

control ingress{
apply(table_route_next_hop); 
 apply(t_pcsa_hash_pcsa_sketch);
 apply(t_pcsa_hash_tcam_lookup_zeroes_pcsa_sketch);
 apply(t_pcsa_sketch);
}


control egress{
apply(table_src_mac_overwrite); 

}


action a_pcsa_hash_pcsa_sketch(){
  modify_field_with_hash_based_offset( mafia_metadata.pcsa_hash_0, 0, pcsa_hash_1, 4294967295);
  shift_right( mafia_metadata.pcsa_hash_bitmap_0, mafia_metadata.pcsa_hash_0, 28 );
  bit_and( mafia_metadata.pcsa_hash_0, mafia_metadata.pcsa_hash_0, 0x0FFFFFFF );
}
action a_pcsa_sketch(){
  modify_field( mafia_metadata.pcsa_sketch_lambda_val, 1 );
  register_write( pcsa_sketch, mafia_metadata.pcsa_hash_bitmap_0*32+mafia_metadata.pcsa_hash_index_0, mafia_metadata.pcsa_sketch_lambda_val );
}
action a_pcsa_hash_tcam_lookup_zeroes_pcsa_sketch(zeroes){
  modify_field( mafia_metadata.pcsa_hash_index_0, zeroes );
}

