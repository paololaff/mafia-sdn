
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/state.p4"

#define THRESHOLD 999

action _drop() { drop(); }

action update_global_counter(){
    register_read(my_metadata.global_counter_val, global_counter, 0);
    add_to_field(my_metadata.global_counter_val, 1);
    register_write(global_counter, 0, my_metadata.global_counter_val);
}
table table_global_counter{
    actions{ update_global_counter; }
}

action update_flow_counter(){
    modify_field_with_hash_based_offset(my_metadata.flow_counter_idx, 0, hash_flow_counter, 128);
    register_read(my_metadata.flow_counter_val, flow_counter, my_metadata.flow_counter_idx);
    add_to_field(my_metadata.flow_counter_val, 1);
    register_write(flow_counter, my_metadata.flow_counter_idx, my_metadata.flow_counter_val);
}
table table_flow_counter{
    actions{ update_flow_counter; }
}

action do_calculate_bf_indexes(){
    modify_field_with_hash_based_offset(my_metadata.bf_idx_1, 0, hash_bf_1, BLOOM_FILTER_SIZE);
    modify_field_with_hash_based_offset(my_metadata.bf_idx_2, 0, hash_bf_2, BLOOM_FILTER_SIZE);
    modify_field_with_hash_based_offset(my_metadata.bf_idx_3, 0, hash_bf_3, BLOOM_FILTER_SIZE);    
    modify_field_with_hash_based_offset(my_metadata.bf_idx_4, 0, hash_bf_4, BLOOM_FILTER_SIZE);
}
table table_index_bf{
    actions{ do_calculate_bf_indexes; }
}

action do_bf_read(){
    register_read(my_metadata.bf_val_1, bloom_filter, my_metadata.bf_idx_1);
    register_read(my_metadata.bf_val_2, bloom_filter, my_metadata.bf_idx_2);
    register_read(my_metadata.bf_val_3, bloom_filter,  my_metadata.bf_idx_3);
    register_read(my_metadata.bf_val_4, bloom_filter, my_metadata.bf_idx_4);
}
table table_bf_read{
    actions{ do_bf_read; }
}

action do_bf_write(){
    register_write(bloom_filter, my_metadata.bf_idx_1, 1);
    register_write(bloom_filter, my_metadata.bf_idx_2, 1);
    register_write(bloom_filter, my_metadata.bf_idx_3, 1);
    register_write(bloom_filter, my_metadata.bf_idx_4, 1);
}
table table_bf_write{
    actions{ do_bf_write; }
}

action do_count_min_sketch(){
    modify_field_with_hash_based_offset(my_metadata.sketch_idx_1, 0, hash_sketch_1, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_val_1, count_min_sketch, 0*SKETCH_SIZE_M + my_metadata.sketch_idx_1);
    add_to_field(my_metadata.sketch_val_1, 1);
    register_write(count_min_sketch, 0*SKETCH_SIZE_M + my_metadata.sketch_idx_1, my_metadata.sketch_val_1);

    modify_field_with_hash_based_offset(my_metadata.sketch_idx_2, 0, hash_sketch_2, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_val_2, count_min_sketch, 1*SKETCH_SIZE_M + my_metadata.sketch_idx_2);
    add_to_field(my_metadata.sketch_val_2, 1);
    register_write(count_min_sketch, 1*SKETCH_SIZE_M + my_metadata.sketch_idx_2, my_metadata.sketch_val_2);

    modify_field_with_hash_based_offset(my_metadata.sketch_idx_3, 0, hash_sketch_3, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_val_3, count_min_sketch, 2*SKETCH_SIZE_M + my_metadata.sketch_idx_3);
    add_to_field(my_metadata.sketch_val_3, 1);
    register_write(count_min_sketch, 2*SKETCH_SIZE_M + my_metadata.sketch_idx_3, my_metadata.sketch_val_3);
    
    modify_field_with_hash_based_offset(my_metadata.sketch_idx_4, 0, hash_sketch_4, SKETCH_SIZE_M);
    register_read(my_metadata.sketch_val_4, count_min_sketch, 3*SKETCH_SIZE_M + my_metadata.sketch_idx_4);
    add_to_field(my_metadata.sketch_val_4, 1);
    register_write(count_min_sketch, 3*SKETCH_SIZE_M + my_metadata.sketch_idx_4, my_metadata.sketch_val_4);
}
table table_countmin_sketch{
    actions{ do_count_min_sketch; }
}

action do_update_sketch_min_1(){
    modify_field(my_metadata.sketch_val_min, my_metadata.sketch_val_1);
}
table table_sketch_count_min_1{
    actions{ do_update_sketch_min_1;}
}
action do_update_sketch_min_2(){
    modify_field(my_metadata.sketch_val_min, my_metadata.sketch_val_2);
}
table table_sketch_count_min_2{
    actions{ do_update_sketch_min_2;}
}
action do_update_sketch_min_3(){
    modify_field(my_metadata.sketch_val_min, my_metadata.sketch_val_3);
}
table table_sketch_count_min_3{
    actions{ do_update_sketch_min_3;}
}
action do_update_sketch_min_4(){
    modify_field(my_metadata.sketch_val_min, my_metadata.sketch_val_4);
}
table table_sketch_count_min_4{
    actions{ do_update_sketch_min_4;}
}


control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_global_counter);
            apply(table_index_bf);
            apply(table_bf_read);
            if( (my_metadata.bf_val_1 == 1) and (my_metadata.bf_val_2 == 1) and (my_metadata.bf_val_3 == 1) and (my_metadata.bf_val_4 == 1))
                apply(table_flow_counter);
            else{
                apply(table_countmin_sketch);
                if( (my_metadata.sketch_val_1 <= my_metadata.sketch_val_2) and
                    (my_metadata.sketch_val_1 <= my_metadata.sketch_val_3) and 
                    (my_metadata.sketch_val_1 <= my_metadata.sketch_val_4) 
                  )
                   apply(table_sketch_count_min_1);
                else if( (my_metadata.sketch_val_2 <= my_metadata.sketch_val_1) and 
                         (my_metadata.sketch_val_2 <= my_metadata.sketch_val_3) and 
                         (my_metadata.sketch_val_2 <= my_metadata.sketch_val_4) 
                       )
                        apply(table_sketch_count_min_2);
                else if( (my_metadata.sketch_val_3 <= my_metadata.sketch_val_1) and 
                         (my_metadata.sketch_val_3 <= my_metadata.sketch_val_2) and 
                         (my_metadata.sketch_val_3 <= my_metadata.sketch_val_4) 
                       )
                        apply(table_sketch_count_min_3);
                else if( (my_metadata.sketch_val_4 <= my_metadata.sketch_val_1) and 
                         (my_metadata.sketch_val_4 <= my_metadata.sketch_val_2) and 
                         (my_metadata.sketch_val_4 <= my_metadata.sketch_val_3) 
                       )
                        apply(table_sketch_count_min_4);
                if( my_metadata.sketch_val_min / my_metadata.global_counter_val > THRESHOLD)
                    apply(table_bf_write);
            }
        }
    }
}

table table_drop {
    actions { _drop; }
}
control egress {
    apply(table_drop);
}
