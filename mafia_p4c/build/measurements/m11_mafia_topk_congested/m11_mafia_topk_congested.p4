
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"



register total_packets {
  width: 32;
  instance_count: 1024;
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
field_list countmin_hash_fields {
  ipv4.src; ipv4.dst; tcp.src; tcp.dst; ipv4.protocol;
}
field_list rng_input {
  rng_metadata;
}
field_list_calculation countmin_hash_4 {
  input{ countmin_hash_fields; }
  algorithm: murmur_4;
  output_width: 8;
}
field_list_calculation countmin_hash_1 {
  input{ countmin_hash_fields; }
  algorithm: murmur_1;
  output_width: 8;
}
field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}

register q_len_sketch {
  width: 32;
  instance_count: 1024;
}
field_list_calculation countmin_hash_2 {
  input{ countmin_hash_fields; }
  algorithm: murmur_2;
  output_width: 8;
}
register q_len_sum {
  width: 32;
  instance_count: 1024;
}

control ingress{
 apply(t_check_is_entry_switch);
 if(mafia_metadata.is_first_hop==1){
   apply(t_tag_q_length);
 }
 apply(t_check_is_not_entry_switch);
 if(mafia_metadata.is_first_hop!=1){
   apply(t_update_q_length){
      miss{
         apply(t_update_tag);
      }
   }
 }
 apply(t_check_is_exit_switch);
 if(mafia_metadata.is_last_hop==1){
   apply(t_countmin_hash_q_len_sketch);
 
   apply(t_q_len_sketch);
 
   apply(t_countmin_hash_total_packets_sketch);
 
   apply(t_total_packets_sketch);
 }
}


control egress{

}


action a_countmin_hash_total_packets_sketch(){
  modify_field( mafia_metadata.countmin_hash_h_0, 0 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_0, 0, countmin_hash_1, 256);
  modify_field( mafia_metadata.countmin_hash_h_1, 1 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_1, 0, countmin_hash_2, 256);
  modify_field( mafia_metadata.countmin_hash_h_2, 2 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_2, 0, countmin_hash_3, 256);
  modify_field( mafia_metadata.countmin_hash_h_3, 3 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_3, 0, countmin_hash_4, 256);
}
action a_update_q_length(){
  modify_field( mafia_metadata.update_q_length_lambda_val, ipv4.identification );
  add_to_field( mafia_metadata.update_q_length_lambda_val, queueing_metadata.enq_qdepth );
  register_write( q_len_sum, mafia_metadata.flow_index, mafia_metadata.update_q_length_lambda_val );
}
action a_countmin_hash_q_len_sketch(){
  modify_field( mafia_metadata.countmin_hash_h_0, 0 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_0, 0, countmin_hash_1, 256);
  modify_field( mafia_metadata.countmin_hash_h_1, 1 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_1, 0, countmin_hash_2, 256);
  modify_field( mafia_metadata.countmin_hash_h_2, 2 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_2, 0, countmin_hash_3, 256);
  modify_field( mafia_metadata.countmin_hash_h_3, 3 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_3, 0, countmin_hash_4, 256);
}
action a_update_tag(){
  register_read( mafia_metadata.update_tag_lambda_val, q_len_sum, mafia_metadata.flow_index );
  modify_field( ipv4.identification, mafia_metadata.update_tag_lambda_val );
}
action a_is_not_entry_switch(is_first_hop){
  modify_field( mafia_metadata.is_first_hop, is_first_hop );
}
action a_tag_q_length(){
  modify_field( mafia_metadata.tag_q_length_lambda_val, queueing_metadata.enq_qdepth );
  modify_field( ipv4.identification, mafia_metadata.tag_q_length_lambda_val );
}
action a_is_entry_switch(is_first_hop){
  modify_field( mafia_metadata.is_first_hop, is_first_hop );
}
action a_is_exit_switch(is_last_hop){
  modify_field( mafia_metadata.is_last_hop, is_last_hop );
}
action a_q_len_sketch(){
  register_read( mafia_metadata.q_len_sketch_lambda_val, q_len_sketch, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0 );
  add_to_field( mafia_metadata.q_len_sketch_lambda_val, ipv4.identification );
  register_write( q_len_sketch, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0, mafia_metadata.q_len_sketch_lambda_val );
  register_read( mafia_metadata.q_len_sketch_lambda_val, q_len_sketch, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1 );
  add_to_field( mafia_metadata.q_len_sketch_lambda_val, ipv4.identification );
  register_write( q_len_sketch, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1, mafia_metadata.q_len_sketch_lambda_val );
  register_read( mafia_metadata.q_len_sketch_lambda_val, q_len_sketch, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2 );
  add_to_field( mafia_metadata.q_len_sketch_lambda_val, ipv4.identification );
  register_write( q_len_sketch, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2, mafia_metadata.q_len_sketch_lambda_val );
  register_read( mafia_metadata.q_len_sketch_lambda_val, q_len_sketch, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3 );
  add_to_field( mafia_metadata.q_len_sketch_lambda_val, ipv4.identification );
  register_write( q_len_sketch, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3, mafia_metadata.q_len_sketch_lambda_val );
}
action a_total_packets_sketch(){
  register_read( mafia_metadata.total_packets_sketch_lambda_val, total_packets, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0 );
  add_to_field( mafia_metadata.total_packets_sketch_lambda_val, 1 );
  register_write( total_packets, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0, mafia_metadata.total_packets_sketch_lambda_val );
  register_read( mafia_metadata.total_packets_sketch_lambda_val, total_packets, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1 );
  add_to_field( mafia_metadata.total_packets_sketch_lambda_val, 1 );
  register_write( total_packets, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1, mafia_metadata.total_packets_sketch_lambda_val );
  register_read( mafia_metadata.total_packets_sketch_lambda_val, total_packets, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2 );
  add_to_field( mafia_metadata.total_packets_sketch_lambda_val, 1 );
  register_write( total_packets, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2, mafia_metadata.total_packets_sketch_lambda_val );
  register_read( mafia_metadata.total_packets_sketch_lambda_val, total_packets, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3 );
  add_to_field( mafia_metadata.total_packets_sketch_lambda_val, 1 );
  register_write( total_packets, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3, mafia_metadata.total_packets_sketch_lambda_val );
}

