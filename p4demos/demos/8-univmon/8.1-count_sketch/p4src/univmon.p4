
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/sketch-count.p4"

#define TWO_POW_32 4294967295
#define TWO_POW_64 18446744073709551615

action _drop() { drop(); }
action _no_op(){ no_op(); }


action do_h_g_1_x(){
    modify_field_with_hash_based_offset(countsketch_metadata.h1_x, 0, h1_x_hash, 8);
    modify_field_with_hash_based_offset(countsketch_metadata.g1_x, 0, g1_x_hash, TWO_POW_32);
}
action do_h_g_2_x(){
    modify_field_with_hash_based_offset(countsketch_metadata.h2_x, 0, h2_x_hash, 8);
    modify_field_with_hash_based_offset(countsketch_metadata.g2_x, 0, g2_x_hash, TWO_POW_32);
}
action do_h_g_3_x(){
    modify_field_with_hash_based_offset(countsketch_metadata.h3_x, 0, h3_x_hash, 8);
    modify_field_with_hash_based_offset(countsketch_metadata.g3_x, 0, g3_x_hash, TWO_POW_32);
}
action do_h_g_4_x(){
    modify_field_with_hash_based_offset(countsketch_metadata.h4_x, 0, h4_x_hash, 8);
    modify_field_with_hash_based_offset(countsketch_metadata.g4_x, 0, g4_x_hash, TWO_POW_32);
}
action do_countsketch_hashes(){
    modify_field_with_hash_based_offset(countsketch_metadata.flowkey, 0, flow_key_hash, TWO_POW_64);
    do_h_g_1_x();
    do_h_g_2_x();
    do_h_g_3_x();
    do_h_g_4_x();
}
table table_countsketch_hashes{
    reads{
        ipv4.srcAddr: lpm;
    }
    actions{ do_countsketch_hashes; _no_op; }
}

action do_countsketch_increment_1(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 0*SKETCH_SIZE_M + countsketch_metadata.h1_x);
    add_to_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 0*SKETCH_SIZE_M + countsketch_metadata.h1_x, countsketch_metadata.countsketch_val);
}
action do_countsketch_decrement_1(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 0*SKETCH_SIZE_M + countsketch_metadata.h1_x);
    subtract_from_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 0*SKETCH_SIZE_M + countsketch_metadata.h1_x, countsketch_metadata.countsketch_val);
}
table table_countsketch_update_1{
    reads{ countsketch_metadata.g1_x: exact; }
    actions{ do_countsketch_increment_1; do_countsketch_decrement_1; _no_op; }
}

action do_countsketch_increment_2(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 1*SKETCH_SIZE_M + countsketch_metadata.h2_x);
    add_to_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 1*SKETCH_SIZE_M + countsketch_metadata.h2_x, countsketch_metadata.countsketch_val);
}
action do_countsketch_decrement_2(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 1*SKETCH_SIZE_M + countsketch_metadata.h2_x);
    subtract_from_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 1*SKETCH_SIZE_M + countsketch_metadata.h2_x, countsketch_metadata.countsketch_val);
}
table table_countsketch_update_2{
    reads{ countsketch_metadata.g2_x: exact; }
    actions{ do_countsketch_increment_2; do_countsketch_decrement_2; _no_op; }
}

action do_countsketch_increment_3(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 2*SKETCH_SIZE_M + countsketch_metadata.h3_x);
    add_to_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 2*SKETCH_SIZE_M + countsketch_metadata.h3_x, countsketch_metadata.countsketch_val);
}
action do_countsketch_decrement_3(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 2*SKETCH_SIZE_M + countsketch_metadata.h3_x);
    subtract_from_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 2*SKETCH_SIZE_M + countsketch_metadata.h3_x, countsketch_metadata.countsketch_val);
}
table table_countsketch_update_3{
    reads{ countsketch_metadata.g3_x: exact; }
    actions{ do_countsketch_increment_3; do_countsketch_decrement_3; _no_op; }
}

action do_countsketch_increment_4(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 3*SKETCH_SIZE_M + countsketch_metadata.h4_x);
    add_to_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 3*SKETCH_SIZE_M + countsketch_metadata.h4_x, countsketch_metadata.countsketch_val);
}
action do_countsketch_decrement_4(){
    register_read(countsketch_metadata.countsketch_val, count_sketch, 3*SKETCH_SIZE_M + countsketch_metadata.h4_x);
    subtract_from_field(countsketch_metadata.countsketch_val, 1);
    register_write(count_sketch, 3*SKETCH_SIZE_M + countsketch_metadata.h4_x, countsketch_metadata.countsketch_val);
}
table table_countsketch_update_4{
    reads{ countsketch_metadata.g4_x: exact; }
    actions{ do_countsketch_increment_4; do_countsketch_decrement_4; _no_op; }
}


control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_countsketch_hashes){
                hit{
                    apply(table_countsketch_update_1);
                    apply(table_countsketch_update_2);
                    apply(table_countsketch_update_3);
                    apply(table_countsketch_update_4);
                }
            }
        }
    }
}



table table_drop_traffic {
    actions { _drop; }
    size: 1;
}

control egress {
    apply(table_drop_traffic);
}
