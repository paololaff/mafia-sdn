
#include "includes/headers.p4"
// #include "includes/metadata.p4"
#include "includes/parser.p4"
#include "includes/tables.p4"



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
register borders {
  width: 32;
  instance_count: 4;
}

control ingress{
 if(ipv4.tos!=0){
 
 }
 if(ipv4.tos==0){
   apply(t_set_border_tag){
      miss{
         apply(t_update_border_counter);
      }
   }
 }
}


control egress{

}


action a_set_border_tag(){
  modify_field( mafia_metadata.set_border_tag_lambda_val, 1 );
  modify_field( ipv4.tos, mafia_metadata.set_border_tag_lambda_val );
}
action a_update_border_counter(){
  register_read( mafia_metadata.borders, borders, mafia_metadata.flow_index );
  modify_field( mafia_metadata.update_border_counter_lambda_val, mafia_metadata.borders );
  add_to_field( mafia_metadata.update_border_counter_lambda_val, 1 );
  register_write( borders, mafia_metadata.flow_index, mafia_metadata.update_border_counter_lambda_val );
}

