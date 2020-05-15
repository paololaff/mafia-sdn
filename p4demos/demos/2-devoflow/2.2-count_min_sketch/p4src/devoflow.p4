
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/sketch-countmin.p4"


action _drop() { drop(); }
action _no_op(){ no_op(); }


action update_count_min_1(){
    modify_field_with_hash_based_offset(my_metadata.sketch_idx_1, 0, hash_1, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_count_1, count_min_sketch, 0*SKETCH_SIZE_M + my_metadata.sketch_idx_1);
    add_to_field(my_metadata.sketch_count_1, 1);
    register_write(count_min_sketch, 0*SKETCH_SIZE_M + my_metadata.sketch_idx_1, my_metadata.sketch_count_1);
}
action update_count_min_2(){
    modify_field_with_hash_based_offset(my_metadata.sketch_idx_2, 0, hash_2, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_count_2, count_min_sketch, 1*SKETCH_SIZE_M + my_metadata.sketch_idx_2);
    add_to_field(my_metadata.sketch_count_2, 1);
    register_write(count_min_sketch, 1*SKETCH_SIZE_M + my_metadata.sketch_idx_2, my_metadata.sketch_count_2);
}
action update_count_min_3(){
    modify_field_with_hash_based_offset(my_metadata.sketch_idx_3, 0, hash_3, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_count_3, count_min_sketch, 2*SKETCH_SIZE_M + my_metadata.sketch_idx_3);
    add_to_field(my_metadata.sketch_count_3, 1);
    register_write(count_min_sketch, 2*SKETCH_SIZE_M + my_metadata.sketch_idx_3, my_metadata.sketch_count_3);
}
action update_count_min_4(){
    modify_field_with_hash_based_offset(my_metadata.sketch_idx_4, 0, hash_4, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_count_4, count_min_sketch, 3*SKETCH_SIZE_M + my_metadata.sketch_idx_4);
    add_to_field(my_metadata.sketch_count_4, 1);
    register_write(count_min_sketch, 3*SKETCH_SIZE_M + my_metadata.sketch_idx_4, my_metadata.sketch_count_4);
}
action do_count_min_sketch(){
    update_count_min_1();
    update_count_min_2();
    update_count_min_3();
    update_count_min_4();
}
table table_countmin_sketch{
    reads{
        ipv4.srcAddr: lpm;
    }
    actions{ do_count_min_sketch; _no_op; }
}



control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_countmin_sketch);
        }
    }
}

table table_drop {
    actions { _drop; }
}
control egress {
    apply(table_drop);
}
