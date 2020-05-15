
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"



field_list countmin_hash_fields {
  ipv4.src; ipv4.dst; tcp.src; tcp.dst; ipv4.protocol;
}
field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}
field_list_calculation countmin_hash_3 {
  input{ countmin_hash_fields; }
  algorithm: murmur_3;
  output_width: 8;
}
field_list_calculation uniform_probability_hash {
  input{ rng_input; }
  algorithm: my_uniform_probability;
  output_width: 32;
}
register countmin_sketch {
  width: 32;
  instance_count: 1024;
}
field_list_calculation countmin_hash_2 {
  input{ countmin_hash_fields; }
  algorithm: murmur_2;
  output_width: 8;
}

field_list_calculation countmin_hash_1 {
  input{ countmin_hash_fields; }
  algorithm: murmur_1;
  output_width: 8;
}
field_list_calculation countmin_hash_4 {
  input{ countmin_hash_fields; }
  algorithm: murmur_4;
  output_width: 8;
}
field_list rng_input {
  rng_metadata;
}

control ingress{
 apply(t_countmin_hash_countmin_sketch);
 apply(t_countmin_sketch);
}


control egress{

}


action a_countmin_sketch(){
  register_read( mafia_metadata.countmin_sketch_lambda_val, countmin_sketch, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0 );
  add_to_field( mafia_metadata.countmin_sketch_lambda_val, 1 );
  register_write( countmin_sketch, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0, mafia_metadata.countmin_sketch_lambda_val );
  register_read( mafia_metadata.countmin_sketch_lambda_val, countmin_sketch, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1 );
  add_to_field( mafia_metadata.countmin_sketch_lambda_val, 1 );
  register_write( countmin_sketch, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1, mafia_metadata.countmin_sketch_lambda_val );
  register_read( mafia_metadata.countmin_sketch_lambda_val, countmin_sketch, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2 );
  add_to_field( mafia_metadata.countmin_sketch_lambda_val, 1 );
  register_write( countmin_sketch, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2, mafia_metadata.countmin_sketch_lambda_val );
  register_read( mafia_metadata.countmin_sketch_lambda_val, countmin_sketch, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3 );
  add_to_field( mafia_metadata.countmin_sketch_lambda_val, 1 );
  register_write( countmin_sketch, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3, mafia_metadata.countmin_sketch_lambda_val );
}
action a_countmin_hash_countmin_sketch(){
  modify_field( mafia_metadata.countmin_hash_h_0, 0 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_0, 0, countmin_hash_1, 256);
  modify_field( mafia_metadata.countmin_hash_h_1, 1 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_1, 0, countmin_hash_2, 256);
  modify_field( mafia_metadata.countmin_hash_h_2, 2 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_2, 0, countmin_hash_3, 256);
  modify_field( mafia_metadata.countmin_hash_h_3, 3 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_3, 0, countmin_hash_4, 256);
}

