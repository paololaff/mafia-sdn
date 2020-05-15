
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"



field_list veridp_hash_fields {
  standard_metadata.ingress_port; mafia_metadata.switch_id; standard_metadata.egress_port;
}
field_list_calculation veridp_hash_3 {
  input{ veridp_hash_fields; }
  algorithm: murmur_3;
  output_width: 4;
}
register bf {
  width: 1;
  instance_count: 16;
}

field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}
field_list_calculation veridp_hash_1 {
  input{ veridp_hash_fields; }
  algorithm: murmur_1;
  output_width: 4;
}

field_list_calculation veridp_hash_2 {
  input{ veridp_hash_fields; }
  algorithm: murmur_2;
  output_width: 4;
}
field_list rng_input {
  rng_metadata;
}
field_list_calculation uniform_probability_hash {
  input{ rng_input; }
  algorithm: my_uniform_probability;
  output_width: 32;
}

control ingress{
 apply(t_check_is_entry_switch);
 if(mafia_metadata.is_first_hop==1){
   apply(t_tag_entry_switch);
 
   apply(t_tag_entry_port);
 
   apply(t_reset_checksum);
 }
 apply(t_veridp_hash_location_bf);
 apply(t_location_bf){
   miss{
     apply(t_tag_location_bf){
        miss{
           apply(t_veridp_hash_reset_location_bf){
               miss{
                   apply(t_reset_location_bf);
               }
           }
        }
     }
   }
 }
 apply(t_check_is_exit_switch);
 if(mafia_metadata.is_last_hop==1){
   apply(t_tag_exit_switch);
 
   apply(t_tag_exit_port){
      miss{
         apply(t_collect_reports);
      }
   }
 }
}


control egress{
 if(standard_metadata.instance_type == 1){
   apply(t_send_reports);
 }
}


action a_location_bf(){
  modify_field( mafia_metadata.location_bf_lambda_val, 1 );
  register_write( bf, mafia_metadata.veridp_hash_index_0, mafia_metadata.location_bf_lambda_val );
  modify_field( mafia_metadata.location_bf_lambda_val, 1 );
  register_write( bf, mafia_metadata.veridp_hash_index_1, mafia_metadata.location_bf_lambda_val );
  modify_field( mafia_metadata.location_bf_lambda_val, 1 );
  register_write( bf, mafia_metadata.veridp_hash_index_2, mafia_metadata.location_bf_lambda_val );
}
action a_reset_location_bf(){
  modify_field( mafia_metadata.reset_location_bf_lambda_val, 0 );
  register_write( bf, mafia_metadata.veridp_hash_index_0, mafia_metadata.reset_location_bf_lambda_val );
  modify_field( mafia_metadata.reset_location_bf_lambda_val, 0 );
  register_write( bf, mafia_metadata.veridp_hash_index_1, mafia_metadata.reset_location_bf_lambda_val );
  modify_field( mafia_metadata.reset_location_bf_lambda_val, 0 );
  register_write( bf, mafia_metadata.veridp_hash_index_2, mafia_metadata.reset_location_bf_lambda_val );
}
action a_is_entry_switch(is_first_hop){
  modify_field( mafia_metadata.is_first_hop, is_first_hop );
}
action a_veridp_hash_reset_location_bf(){
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_0, 0, veridp_hash_1, 16);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_1, 0, veridp_hash_2, 16);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_2, 0, veridp_hash_3, 16);
}
action a_tag_entry_switch(){
  modify_field( mafia_metadata.tag_entry_switch_lambda_val, mafia_metadata.switch_id );
  modify_field( ipv4.identification, mafia_metadata.tag_entry_switch_lambda_val );
}
action a_tag_entry_port(){
  modify_field( mafia_metadata.tag_entry_port_lambda_val, standard_metadata.ingress_port );
  modify_field( ipv4.identification, mafia_metadata.tag_entry_port_lambda_val );
}
action a_tag_exit_port(){
  modify_field( mafia_metadata.tag_exit_port_lambda_val, standard_metadata.egress_port );
  modify_field( ipv4.identification, mafia_metadata.tag_exit_port_lambda_val );
}
action a_tag_location_bf(){
  register_read( mafia_metadata.bf_serialized, bf, 0 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 15 );
  register_read( mafia_metadata.bf_serialized, bf, 1 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 14 );
  register_read( mafia_metadata.bf_serialized, bf, 2 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 13 );
  register_read( mafia_metadata.bf_serialized, bf, 3 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 12 );
  register_read( mafia_metadata.bf_serialized, bf, 4 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 11 );
  register_read( mafia_metadata.bf_serialized, bf, 5 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 10 );
  register_read( mafia_metadata.bf_serialized, bf, 6 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 9 );
  register_read( mafia_metadata.bf_serialized, bf, 7 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 8 );
  register_read( mafia_metadata.bf_serialized, bf, 8 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 7 );
  register_read( mafia_metadata.bf_serialized, bf, 9 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 6 );
  register_read( mafia_metadata.bf_serialized, bf, 10 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 5 );
  register_read( mafia_metadata.bf_serialized, bf, 11 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 4 );
  register_read( mafia_metadata.bf_serialized, bf, 12 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 3 );
  register_read( mafia_metadata.bf_serialized, bf, 13 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 2 );
  register_read( mafia_metadata.bf_serialized, bf, 14 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 1 );
  register_read( mafia_metadata.bf_serialized, bf, 15 );
  shift_left( mafia_metadata.bf_serialized, mafia_metadata.bf_serialized, 0 );
  modify_field( mafia_metadata.tag_location_bf_lambda_val, mafia_metadata.bf_serialized );
  bit_or( mafia_metadata.tag_location_bf_lambda_val, mafia_metadata.tag_location_bf_lambda_val, tcp.checksum );
  modify_field( tcp.checksum, mafia_metadata.tag_location_bf_lambda_val );
}
action a_veridp_hash_location_bf(){
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_0, 0, veridp_hash_1, 16);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_1, 0, veridp_hash_2, 16);
  modify_field_with_hash_based_offset( mafia_metadata.veridp_hash_index_2, 0, veridp_hash_3, 16);
}
action a_tag_exit_switch(){
  modify_field( mafia_metadata.tag_exit_switch_lambda_val, mafia_metadata.switch_id );
  modify_field( ipv4.identification, mafia_metadata.tag_exit_switch_lambda_val );
}
action a_header_vlan(){
  add_header(vlan);
  modify_field( vlan.vid, 9 );
  modify_field( vlan.ether_type, eth.ether_type );
  modify_field( eth.ether_type, 0x8100 );
}
action a_is_exit_switch(is_last_hop){
  modify_field( mafia_metadata.is_last_hop, is_last_hop );
}
action a_collect_reports(){
  clone_ingress_pkt_to_egress( 1, sample_copy_fields );
}
action a_reset_checksum(){
  modify_field( mafia_metadata.reset_checksum_lambda_val, 0 );
  modify_field( tcp.checksum, mafia_metadata.reset_checksum_lambda_val );
}

