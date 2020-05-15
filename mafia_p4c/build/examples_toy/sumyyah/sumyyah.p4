
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"



field_list_calculation countmin_hash_2 {
  input{ countmin_hash_fields; }
  algorithm: murmur_2;
  output_width: 8;
}
field_list_calculation countmin_hash_4 {
  input{ countmin_hash_fields; }
  algorithm: murmur_4;
  output_width: 8;
}
field_list_calculation veridp_hash_2 {
  input{ veridp_hash_fields; }
  algorithm: murmur_2;
  output_width: 6;
}


field_list_calculation uniform_probability_hash {
  input{ rng_input; }
  algorithm: my_uniform_probability;
  output_width: 32;
}
field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}
field_list veridp_hash_fields {
  ipv4.src; ipv4.dst; tcp.src; tcp.dst;
}
field_list_calculation countmin_hash_3 {
  input{ countmin_hash_fields; }
  algorithm: murmur_3;
  output_width: 8;
}
field_list_calculation veridp_hash_3 {
  input{ veridp_hash_fields; }
  algorithm: murmur_3;
  output_width: 6;
}
register volume_sketch {
  width: 32;
  instance_count: 1024;
}
field_list rng_input {
  rng_metadata;
}
register decrement {
  width: 32;
  instance_count: 1;
}
register nbytes {
  width: 32;
  instance_count: 1024;
}
register connections {
  width: 32;
  instance_count: 1;
}
field_list countmin_hash_fields {
  ipv4.src; ipv4.dst; tcp.src; tcp.dst;
}
register bf {
  width: 1;
  instance_count: 64;
}
field_list_calculation veridp_hash_1 {
  input{ veridp_hash_fields; }
  algorithm: murmur_1;
  output_width: 6;
}
field_list_calculation countmin_hash_1 {
  input{ countmin_hash_fields; }
  algorithm: murmur_1;
  output_width: 8;
}

control ingress{
 apply(t_match_ip_dst){
   hit{
     if(tcp.ctrl & 0x1==1){
     
     }
   }
 }
 apply(t_countmin_hash_update_sketch);
 apply(t_update_sketch){
   miss{
     apply(t_nbytes_increment){
        miss{
           apply(t_veridp_hash_flow_hh){
               miss{
                   apply(t_flow_hh_read_bf){
                        miss{
                             if(mafia_metadata.flow_hh_bf_cell_0!=1 and mafia_metadata.flow_hh_bf_cell_1!=1 and mafia_metadata.flow_hh_bf_cell_2!=1){
                                   apply(t_connections_increment){
                                          miss{
                                                 apply(t_veridp_hash_bf){
                                                         miss{
                                                                 apply(t_bf);
                                                         }
                                                 }
                                          }
                                   }
                             }
                        }
                   }
               }
           }
        }
     }
   }
 }
}


control egress{

}


action a_countmin_hash_update_sketch(){
  modify_field( mafia_metadata.countmin_hash_h_0, 0 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_0, 0, countmin_hash_1, 256);
  modify_field( mafia_metadata.countmin_hash_h_1, 1 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_1, 0, countmin_hash_2, 256);
  modify_field( mafia_metadata.countmin_hash_h_2, 2 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_2, 0, countmin_hash_3, 256);
  modify_field( mafia_metadata.countmin_hash_h_3, 3 );
  modify_field_with_hash_based_offset( mafia_metadata.countmin_hash_index_3, 0, countmin_hash_4, 256);
}
action a_nbytes_increment(){
  register_read( mafia_metadata.nbytes, nbytes, mafia_metadata.flow_index );
  modify_field( mafia_metadata.nbytes_increment_lambda_val, mafia_metadata.nbytes );
  add_to_field( mafia_metadata.nbytes_increment_lambda_val, standard_metadata.packet_length );
  register_write( nbytes, mafia_metadata.flow_index, mafia_metadata.nbytes_increment_lambda_val );
}
action a_bf(){
  modify_field( mafia_metadata.bf_lambda_val, 1 );
  register_write( bf, mafia_metadata.veridp_hash_index_0, mafia_metadata.bf_lambda_val );
  modify_field( mafia_metadata.bf_lambda_val, 1 );
  register_write( bf, mafia_metadata.veridp_hash_index_1, mafia_metadata.bf_lambda_val );
  modify_field( mafia_metadata.bf_lambda_val, 1 );
  register_write( bf, mafia_metadata.veridp_hash_index_2, mafia_metadata.bf_lambda_val );
}
action a_update_sketch(){
  register_read( mafia_metadata.update_sketch_lambda_val, volume_sketch, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0 );
  add_to_field( mafia_metadata.update_sketch_lambda_val, standard_metadata.packet_length );
  register_write( volume_sketch, mafia_metadata.countmin_hash_h_0*256+mafia_metadata.countmin_hash_index_0, mafia_metadata.update_sketch_lambda_val );
  register_read( mafia_metadata.update_sketch_lambda_val, volume_sketch, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1 );
  add_to_field( mafia_metadata.update_sketch_lambda_val, standard_metadata.packet_length );
  register_write( volume_sketch, mafia_metadata.countmin_hash_h_1*256+mafia_metadata.countmin_hash_index_1, mafia_metadata.update_sketch_lambda_val );
  register_read( mafia_metadata.update_sketch_lambda_val, volume_sketch, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2 );
  add_to_field( mafia_metadata.update_sketch_lambda_val, standard_metadata.packet_length );
  register_write( volume_sketch, mafia_metadata.countmin_hash_h_2*256+mafia_metadata.countmin_hash_index_2, mafia_metadata.update_sketch_lambda_val );
  register_read( mafia_metadata.update_sketch_lambda_val, volume_sketch, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3 );
  add_to_field( mafia_metadata.update_sketch_lambda_val, standard_metadata.packet_length );
  register_write( volume_sketch, mafia_metadata.countmin_hash_h_3*256+mafia_metadata.countmin_hash_index_3, mafia_metadata.update_sketch_lambda_val );
}
action a_flow_hh(){
  register_read( mafia_metadata.flow_hh_bf_cell_0, bf, mafia_metadata.veridp_hash_index_0 );
  register_read( mafia_metadata.flow_hh_bf_cell_1, bf, mafia_metadata.veridp_hash_index_1 );
  register_read( mafia_metadata.flow_hh_bf_cell_2, bf, mafia_metadata.veridp_hash_index_2 );
}
action _no_op(){
  no_op();
}
action a_veridp_hash_bf(){
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_0, 0, veridp_hash_1, 64);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_1, 0, veridp_hash_2, 64);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_2, 0, veridp_hash_3, 64);
}
action a_set_flow_index(flow_index){
  modify_field( mafia_metadata.flow_index, flow_index );
}
action a_connections_increment(){
  register_read( mafia_metadata.connections, connections, mafia_metadata.flow_index );
  modify_field( mafia_metadata.connections_increment_lambda_val, mafia_metadata.connections );
  add_to_field( mafia_metadata.connections_increment_lambda_val, 1 );
  register_write( connections, mafia_metadata.flow_index, mafia_metadata.connections_increment_lambda_val );
}
action a_veridp_hash_flow_hh(){
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_0, 0, veridp_hash_1, 64);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_1, 0, veridp_hash_2, 64);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_2, 0, veridp_hash_3, 64);
}

