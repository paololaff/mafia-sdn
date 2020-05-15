
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"


field_list sample_copy_fields {
  mafia_metadata;
}

control ingress{
 apply(t_duplicate_postcards);
}


control egress{
 if(standard_metadata.instance_type == 1){
   apply(t_tag_input_port){
      miss{
         apply(t_tag_switch_id){
             miss{
                 apply(t_tag_output_port){
                      miss{
                           apply(t_collect_postcards);
                      }
                 }
             }
         }
      }
   }
 }
}


action a_tag_input_port(){
  modify_field( eth.src, ig_intr_md.ingress_port );
}
action a_tag_switch_id(){
  modify_field( ipv4.identification, mafia_metadata.switch_id );
}
action a_tag_output_port(){
  modify_field( eth.dst, eg_intr_md.egress_port );
}
action a_header_vlan(){
  add_header(vlan);
  modify_field( vlan.vid, 1 );
  modify_field( vlan.ether_type, eth.ether_type );
  modify_field( eth.ether_type, 0x8100 );
}
action a_duplicate_postcards(){
  clone_ingress_pkt_to_egress( 1, sample_copy_fields );
}

