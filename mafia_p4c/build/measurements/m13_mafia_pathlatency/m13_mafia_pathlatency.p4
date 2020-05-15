
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
register ts_change {
  width: 48;
  instance_count: 1024;
}


control ingress{
 if(ipv4.identification==999){
   apply(t_check_is_last_switch){
      hit{
         if(mafia_metadata.is_last_hop==1){
             apply(t_ts_change){
                  miss{
                       apply(t_generate_segway_report);
                  }
             }
         }
      }
   }
 }
}


control egress{
 if(standard_metadata.instance_type == 1){
   apply(t_tag_end_update){
      miss{
         apply(t_send_segway_report);
      }
   }
 }
}


action a_is_last_switch(is_last_hop){
  modify_field( mafia_metadata.is_last_hop, is_last_hop );
}
action a_generate_segway_report(){
  clone_ingress_pkt_to_egress( 1, sample_copy_fields );
}
action a_ts_change(){
  modify_field( mafia_metadata.ts_change, intrinsic_metadata.ingress_global_timestamp );
  register_write( ts_change, mafia_metadata.flow_index, mafia_metadata.ts_change );
}
action a_header_vlan(){
  add_header(vlan);
  modify_field( vlan.vid, 1 );
  modify_field( vlan.ether_type, eth.ether_type );
  modify_field( eth.ether_type, 0x8100 );
}
action a_tag_end_update(){
  register_read( mafia_metadata.tag_end_update_lambda_val, ts_change, mafia_metadata.flow_index );
  modify_field( tcp.checksum, mafia_metadata.tag_end_update_lambda_val );
}

