
#include "headers.p4"
#include "tables.p4"
#include "../../parser.p4"

#include <tofino/stateful_alu_blackbox.p4>


register hll_sketch {
  width: 32;
  instance_count: 64;
}
field_list_calculation hll_hash_fun {
  input{ hll_hash_fields; }
  algorithm: posix;
  output_width: 32;
}

field_list hll_hash_fields {
  ipv4.src; ipv4.dst; tcp.src; tcp.dst; ipv4.protocol;
}

control ingress{
  apply(t_hll_hash);
  apply(t_hll_hash_process_hi);
  apply(t_hll_hash_process_lo);
  apply(t_hll_hash_tcam_lookup_zeroes);
  apply(t_hll_sketch_index);
  apply(t_hll_sketch_value);
  apply(t_hll_sketch);
}


control egress{

}



blackbox stateful_alu salu_hll_sketch{
  reg: hll_sketch;

  update_lo_1_value: mafia_metadata.hll_sketch_update_value;     
  output_value: alu_lo;
  output_dst: mafia_metadata.hll_sketch;
}
action a_hll_sketch(){
  salu_hll_sketch.execute_stateful_alu(mafia_metadata.hll_sketch_index);
}
action a_hll_hash_tcam_lookup_zeroes(zeroes){
  modify_field( mafia_metadata.hll_hash_lo_zeroes, zeroes );
}
action a_hll_hash(){
  modify_field_with_hash_based_offset( mafia_metadata.hll_hash_val, 0, hll_hash_fun, 4294967296);  
}
action a_hll_hash_process_hi(){
  shift_right( mafia_metadata.hll_hash_hi, mafia_metadata.hll_hash_val, 26 );
  // modify_field(mafia_metadata.pcsa_sketch_index, mafia_metadata.pcsa_hash_hi);
}
action a_hll_hash_process_lo(){
  bit_and( mafia_metadata.hll_hash_lo, mafia_metadata.hll_hash_val, 0x03FFFFFF );
}
action a_hll_sketch_index(){
  modify_field(mafia_metadata.hll_sketch_index, mafia_metadata.hll_hash_hi);
}
action a_hll_sketch_value(){
  modify_field(mafia_metadata.hll_sketch_update_value, mafia_metadata.hll_hash_lo_zeroes);
}

