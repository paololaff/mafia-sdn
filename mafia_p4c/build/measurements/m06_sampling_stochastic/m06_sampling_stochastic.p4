
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"



field_list_calculation uniform_probability_hash {
  input{ rng_input; }
  algorithm: my_uniform_probability;
  output_width: 32;
}

field_list sample_copy_fields {
  mafia_metadata; standard_metadata; intrinsic_metadata;
}
field_list rng_input {
  rng_metadata;
}
register n_samples {
  width: 32;
  instance_count: 1024;
}

register n {
  width: 32;
  instance_count: 1024;
}

control ingress{
 apply(t_n_increment);
 apply(t_sample_probability){
   miss{
     if(mafia_metadata.sample_probability<25){
        apply(t_duplicate);
     }
   }
 }
}


control egress{
 if(standard_metadata.instance_type == 1){
   apply(t_n_samples_increment){
      miss{
         apply(t_sample);
      }
   }
 }
}


action a_sample_probability(){
  modify_field_with_hash_based_offset( mafia_metadata.sample_probability, 0, uniform_probability_hash, 100);
}
action a_n_samples_increment(){
  register_read( mafia_metadata.n_samples, n_samples, mafia_metadata.flow_index );
  modify_field( mafia_metadata.n_samples_increment_lambda_val, mafia_metadata.n_samples );
  add_to_field( mafia_metadata.n_samples_increment_lambda_val, 1 );
  register_write( n_samples, mafia_metadata.flow_index, mafia_metadata.n_samples_increment_lambda_val );
}
action a_n_increment(){
  register_read( mafia_metadata.n, n, mafia_metadata.flow_index );
  modify_field( mafia_metadata.n_increment_lambda_val, mafia_metadata.n );
  add_to_field( mafia_metadata.n_increment_lambda_val, 1 );
  register_write( n, mafia_metadata.flow_index, mafia_metadata.n_increment_lambda_val );
}
action a_header_vlan(){
  add_header(vlan);
  modify_field( vlan.vid, 1 );
  modify_field( vlan.ether_type, eth.ether_type );
  modify_field( eth.ether_type, 0x8100 );
}
action a_duplicate(){
  clone_ingress_pkt_to_egress( 1, sample_copy_fields );
}

