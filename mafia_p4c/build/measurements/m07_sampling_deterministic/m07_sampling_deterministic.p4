
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"




register n {
  width: 32;
  instance_count: 1024;
}
register delta {
  width: 32;
  instance_count: 1024;
}
field_list rng_input {
  rng_metadata;
}
field_list_calculation uniform_probability_hash {
  input{ rng_input; }
  algorithm: my_uniform_probability;
  output_width: 32;
}
field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}
register m {
  width: 32;
  instance_count: 1024;
}

control ingress{
 apply(t_n_increment);
 apply(t_delta_increment);
 apply(t_load_delta);
 if(mafia_metadata.delta>25){
   apply(t_load_m){
      miss{
         if(mafia_metadata.m<10){
             apply(t_m_increment){
                  miss{
                       apply(t_sample);
                  }
             }
         }
      }
   }
 }
 apply(t_load_n);
 if(mafia_metadata.n>100){
   apply(t_n_reset);
 
   apply(t_m_reset);
 
   apply(t_delta_reset);
 }
}


control egress{
 if(standard_metadata.instance_type == 1){
   apply(t_samples);
 }
}


action a_header_vlan(){
  add_header(vlan);
  modify_field( vlan.vid, 1 );
  modify_field( vlan.ether_type, eth.ether_type );
  modify_field( eth.ether_type, 0x8100 );
}
action a_m_increment(){
  register_read( mafia_metadata.m, m, mafia_metadata.flow_index );
  modify_field( mafia_metadata.m_increment_lambda_val, mafia_metadata.m );
  add_to_field( mafia_metadata.m_increment_lambda_val, 1 );
  register_write( m, mafia_metadata.flow_index, mafia_metadata.m_increment_lambda_val );
}
action a_delta_reset(){
  modify_field( mafia_metadata.delta_reset_lambda_val, 0 );
  register_write( delta, mafia_metadata.flow_index, mafia_metadata.delta_reset_lambda_val );
}
action a_n_reset(){
  modify_field( mafia_metadata.n_reset_lambda_val, 0 );
  register_write( n, mafia_metadata.flow_index, mafia_metadata.n_reset_lambda_val );
}
action a_n_increment(){
  register_read( mafia_metadata.n, n, mafia_metadata.flow_index );
  modify_field( mafia_metadata.n_increment_lambda_val, mafia_metadata.n );
  add_to_field( mafia_metadata.n_increment_lambda_val, 1 );
  register_write( n, mafia_metadata.flow_index, mafia_metadata.n_increment_lambda_val );
}
action a_load_delta(){
  register_read( mafia_metadata.delta, delta, mafia_metadata.flow_index );
}
action a_m_reset(){
  modify_field( mafia_metadata.m_reset_lambda_val, 0 );
  register_write( m, mafia_metadata.flow_index, mafia_metadata.m_reset_lambda_val );
}
action a_load_n(){
  register_read( mafia_metadata.n, n, mafia_metadata.flow_index );
}
action a_sample(){
  clone_ingress_pkt_to_egress( 1, sample_copy_fields );
}
action a_load_m(){
  register_read( mafia_metadata.m, m, mafia_metadata.flow_index );
}
action a_delta_increment(){
  register_read( mafia_metadata.delta, delta, mafia_metadata.flow_index );
  modify_field( mafia_metadata.delta_increment_lambda_val, mafia_metadata.delta );
  add_to_field( mafia_metadata.delta_increment_lambda_val, 1 );
  register_write( delta, mafia_metadata.flow_index, mafia_metadata.delta_increment_lambda_val );
}

