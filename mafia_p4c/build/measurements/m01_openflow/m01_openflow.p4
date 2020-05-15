
#include "headers.p4"
#include "tables.p4"
#include "../../routing.p4"
#include "../../parser.p4"



field_list rng_input {
  rng_metadata;
}
register byte_counter {
  width: 32;
  instance_count: 8;
}
field_list_calculation uniform_probability_hash {
  input{ rng_input; }
  algorithm: my_uniform_probability;
  output_width: 32;
}
register flow_duration {
  width: 48;
  instance_count: 8;
}
field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}
register packet_counter {
  width: 32;
  instance_count: 8;
}
register now_ts {
  width: 48;
  instance_count: 8;
}
register start_ts {
  width: 48;
  instance_count: 8;
}

control ingress{
  if(valid(ipv4)){
    apply(table_route_next_hop); 
    if(ipv4.protocol==0x06){
      apply(t_packet_counter_add_1);
    
      apply(t_byte_counter_add_size);
    
      apply(t_load_start_ts);
    
      if(mafia_metadata.start_ts==0){
          apply(t_start_ts);
      }
    
      apply(t_now_ts){
          miss{
            apply(t_flow_duration_update);
          }
      }
    }

  }
}


control egress{

}


action a_byte_counter_add_size(){
  register_read( mafia_metadata.byte_counter, byte_counter, mafia_metadata.flow_index );
  modify_field( mafia_metadata.byte_counter_add_size_lambda_val, mafia_metadata.byte_counter );
  add_to_field( mafia_metadata.byte_counter_add_size_lambda_val, standard_metadata.packet_length );
  register_write( byte_counter, mafia_metadata.flow_index, mafia_metadata.byte_counter_add_size_lambda_val );
}
action a_load_start_ts(){
  register_read( mafia_metadata.start_ts, start_ts, mafia_metadata.flow_index );
}
action a_start_ts(){
  modify_field( mafia_metadata.start_ts, intrinsic_metadata.ingress_global_timestamp );
  register_write( start_ts, mafia_metadata.flow_index, mafia_metadata.start_ts );
}
action a_packet_counter_add_1(){
  modify_field( mafia_metadata.packet_counter_add_1_lambda_val, 1 );
  register_read( mafia_metadata.packet_counter, packet_counter, mafia_metadata.flow_index );
  add_to_field( mafia_metadata.packet_counter_add_1_lambda_val, mafia_metadata.packet_counter );
  register_write( packet_counter, mafia_metadata.flow_index, mafia_metadata.packet_counter_add_1_lambda_val );
}
action a_flow_duration_update(){
  register_read( mafia_metadata.now_ts, now_ts, mafia_metadata.flow_index );
  modify_field( mafia_metadata.flow_duration_update_lambda_val, mafia_metadata.now_ts );
  register_read( mafia_metadata.start_ts, start_ts, mafia_metadata.flow_index );
  subtract_from_field( mafia_metadata.flow_duration_update_lambda_val, mafia_metadata.start_ts );
  register_write( flow_duration, mafia_metadata.flow_index, mafia_metadata.flow_duration_update_lambda_val );
}
action a_now_ts(){
  modify_field( mafia_metadata.now_ts, intrinsic_metadata.ingress_global_timestamp );
  register_write( now_ts, mafia_metadata.flow_index, mafia_metadata.now_ts );
}

