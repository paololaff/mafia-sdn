
#include "headers.p4"
#include "tables.p4"
#include "../../routing.p4"
#include "../../parser.p4"



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


control ingress{
  if(valid(ipv4)){
    apply(table_route_next_hop); 
  }
}


control egress{

}