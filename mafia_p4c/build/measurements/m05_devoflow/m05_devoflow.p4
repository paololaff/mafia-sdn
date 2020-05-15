
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"

#include <tofino/stateful_alu_blackbox.p4>

field_list sample_copy_fields {
  mafia_metadata;
}
register byte_counter {
  width: 32;
  instance_count: 1024;
}
register byte_counter_fake {
  width: 32;
  instance_count: 1;
}


register packet_counter_fake {
  width: 32;
  instance_count: 1024;
}
register packet_counter {
  width: 32;
  instance_count: 1;
}

control ingress{
 apply(t_byte_counter_add_size){
   miss{
     apply(t_condition_byte_counter_gt_999);
      if(mafia_metadata.condition_byte_counter_gt_999 == 1){
          apply(t_duplicate_4_bytes_exceeded);
      }
     
   }
 }
 apply(t_packet_counter_add_1){
   miss{
     apply(t_condition_packet_counter_gt_999);
     if(mafia_metadata.condition_packet_counter_gt_999 == 1){
         apply(t_duplicate_4_packets_exceeded);
     }
   }
 }
}


control egress{
 if(standard_metadata.instance_type == 1){
   apply(t_tag_byte_counter){
      miss{
         apply(t_sample_bytes);
      }
   }
 }
 if(standard_metadata.instance_type == 1){
   apply(t_tag_packet_counter){
      miss{
         apply(t_samples_packets);
      }
   }
 }
}


blackbox stateful_alu salu_packet_counter_add_1{
  reg: packet_counter;
  update_lo_1_value: register_lo + 1;
  output_value: alu_lo;
  output_dst: mafia_metadata.packet_counter;
}
action a_packet_counter_add_1(){
  salu_packet_counter_add_1.execute_stateful_alu(mafia_metadata.flow_index);
}
blackbox stateful_alu salu_condition_packet_counter_gt_999{
  reg: packet_counter_fake;
  condition_lo: mafia_metadata.packet_counter > 999;
  update_lo_1_predicate: condition_lo;
  update_lo_1_value: 1;
  update_lo_2_predicate: not condition_lo;
  update_lo_2_value: 0;
  output_value: alu_lo;
  output_dst: mafia_metadata.condition_packet_counter_gt_999;
}
action a_condition_packet_counter_gt_999(){
  salu_condition_packet_counter_gt_999.execute_stateful_alu(0);
}

blackbox stateful_alu salu_condition_byte_counter_gt_999{
  reg: byte_counter_fake;
  condition_lo: mafia_metadata.byte_counter > 999;
  update_lo_1_predicate: condition_lo;
  update_lo_1_value: 1;
  update_lo_2_predicate: not condition_lo;
  update_lo_2_value: 0;
  output_value: alu_lo;
  output_dst: mafia_metadata.condition_byte_counter_gt_999;
}
action a_condition_byte_counter_gt_999(){
  salu_condition_byte_counter_gt_999.execute_stateful_alu(0);
}
blackbox stateful_alu salu_byte_counter_add_size{
  reg: byte_counter;
  update_lo_1_value: register_lo + 1;
  output_value: alu_lo;
  output_dst: mafia_metadata.byte_counter;
}
action a_byte_counter_add_size(){
  salu_byte_counter_add_size.execute_stateful_alu(mafia_metadata.flow_index);
}

action a_tag_byte_counter(){
  modify_field( ipv4.identification, mafia_metadata.byte_counter );
}
action a_tag_packet_counter(){
  modify_field( ipv4.identification, mafia_metadata.packet_counter );
}
action a_header_vlan(){
  add_header(vlan);
  modify_field( vlan.vid, 2 );
  modify_field( vlan.ether_type, eth.ether_type );
  modify_field( eth.ether_type, 0x8100 );
}

action a_duplicate_4_packets_exceeded(){
  clone_ingress_pkt_to_egress( 2, sample_copy_fields );
}
action a_duplicate_4_bytes_exceeded(){
  clone_ingress_pkt_to_egress( 1, sample_copy_fields );
}



