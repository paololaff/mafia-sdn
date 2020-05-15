
#include "includes/headers.p4"
#include "includes/metadata.p4"
#include "includes/parser.p4"
#include "includes/routing.p4"
#include "includes/state.p4"

action _drop() { drop(); }
action _no_op(){ no_op(); }

control ingress {
    apply( table_route_next_hop );
    apply( table_dst_mac_overwrite );
}

control egress {
    apply( table_veridp_load_switch_id );
    apply( table_veridp_in_out_port    ); // Load the input/output ports of the packet
    
    apply(table_veridp_switch_net_entry){
        hit{
            if(not valid(veridp_h)) apply(table_veridp_tag_entry);
        }
    }
    
    if(valid(veridp_h)){ // All switches: update VeriDP Bloom Filter Tag
        apply( table_veridp_calculate_bf_indexes );
        apply( table_veridp_update_bf_0 ); 
        apply( table_veridp_update_bf_1 );
        apply( table_veridp_update_bf_2 );
    }

    apply(table_veridp_switch_net_exit){
        hit{
            if(valid(veridp_h)){
                apply(table_veridp_tag_exit);
                apply(table_sketch_indexes);
                apply(table_sketch_read_path_tags);
                if( (veridp_h.bf_tag != sketch_metadata.sketch_val_1) and 
                    (veridp_h.bf_tag != sketch_metadata.sketch_val_2) and 
                    (veridp_h.bf_tag != sketch_metadata.sketch_val_3) and 
                    (veridp_h.bf_tag != sketch_metadata.sketch_val_4)
                    ){
                        apply(table_sketch_update_path_tags);
                        apply(table_sketch_read_changes);
                        apply(table_sketch_update_changes);
                    }
            }
        }
    }

    apply( table_src_mac_overwrite );
}

action do_veridp_load_switch_id(switch_id){
    modify_field( veridp_metadata.switch_id, switch_id  ); // Save this switch's id
}
table table_veridp_load_switch_id{
    actions { do_veridp_load_switch_id; }
}

action do_veridp_in_out_port(input_port){
    modify_field( veridp_metadata.input_port,  input_port );                     // Save the packet input port
    modify_field( veridp_metadata.output_port, standard_metadata.egress_spec );  // Save the packet output port
}
table table_veridp_in_out_port{
    reads{
        veridp_metadata.switch_id:  exact;
        ethernet.srcAddr:  exact;
    }
    actions{
        do_veridp_in_out_port;
        _no_op;
    }
    size: 128;
}

table table_veridp_switch_net_entry{
    reads{ ethernet.srcAddr: exact; }
    actions { _no_op; }
    size: N_FLOWS_ENTRIES;
}
table table_veridp_switch_net_exit{
    reads{ ethernet.dstAddr: exact;}
    actions { _no_op; }
    size: N_FLOWS_ENTRIES;
}


action do_veridp_tag_entry(){
    add_header( veridp_h );
    modify_field( ipv4.protocol,             IPPROTO_VERIDP );
    modify_field( veridp_h.net_entry_port,   veridp_metadata.input_port );
    modify_field( veridp_h.net_entry_switch, veridp_metadata.switch_id  );
}
table table_veridp_tag_entry{
    actions { do_veridp_tag_entry; }
}
action do_veridp_tag_exit(){
    modify_field( veridp_h.net_exit_port, standard_metadata.egress_spec);
    modify_field( veridp_h.net_exit_switch, veridp_metadata.switch_id);
}
table table_veridp_tag_exit{
    actions { do_veridp_tag_exit; }
}




action do_veridp_bf_g0_x(){
    modify_field( veridp_metadata.g0_x, veridp_metadata.h1_x );
}
action do_veridp_bf_g1_x(){
    modify_field( veridp_metadata.g1_x, veridp_metadata.h2_x );
    add_to_field( veridp_metadata.g1_x, veridp_metadata.h1_x );
}
action do_veridp_bf_g2_x(){
    modify_field( veridp_metadata.g2_x, veridp_metadata.h2_x );
    shift_left(   veridp_metadata.g2_x, veridp_metadata.g2_x, 1 );
    add_to_field( veridp_metadata.g2_x, veridp_metadata.h1_x );    
}
action do_veridp_calculate_bf_indexes(){
    /* Generate the Murmur hash */
    modify_field_with_hash_based_offset ( veridp_metadata.murmur_hash, 0, veridp_bf_hash, 4294967295); // Max 2^32
    
    /* Calculate H1, H2, G0, G1, G2 */
    bit_and(     veridp_metadata.h2_x, veridp_metadata.murmur_hash, MURMUR_H2_MASK); // H2
    shift_right( veridp_metadata.h1_x, veridp_metadata.murmur_hash, 16);             // H1
    do_veridp_bf_g0_x(); // G0
    do_veridp_bf_g1_x(); // G1
    do_veridp_bf_g2_x(); // G2    

    // Calculate the Bloom Filter bit to be set
    bit_and(veridp_metadata.bf_index_0, veridp_metadata.g0_x, VERIDP_TAG_INDEX_MASK);
    bit_and(veridp_metadata.bf_index_1, veridp_metadata.g1_x, VERIDP_TAG_INDEX_MASK);
    bit_and(veridp_metadata.bf_index_2, veridp_metadata.g2_x, VERIDP_TAG_INDEX_MASK);
}
table table_veridp_calculate_bf_indexes{
    actions{ do_veridp_calculate_bf_indexes; }
}

action do_veridp_update_bf_tag(tag_mask){
    modify_field( veridp_metadata.bf_tag_value, veridp_h.bf_tag );
    bit_or(       veridp_metadata.bf_tag_value, veridp_metadata.bf_tag_value, tag_mask );
    modify_field( veridp_h.bf_tag,              veridp_metadata.bf_tag_value );
}
table table_veridp_update_bf_0{
    reads  { veridp_metadata.bf_index_0: exact; }
    actions{ do_veridp_update_bf_tag; _no_op; }
    size: 16;
}
table table_veridp_update_bf_1{
    reads  { veridp_metadata.bf_index_1: exact; }
    actions{ do_veridp_update_bf_tag;_no_op;  }
    size: 16;
}
table table_veridp_update_bf_2{
    reads  { veridp_metadata.bf_index_2: exact; }
    actions{ do_veridp_update_bf_tag; _no_op; }
    size: 16;
}


action do_sketch_indexes(){
    modify_field_with_hash_based_offset(sketch_metadata.sketch_idx_1, 0, hash_1, SKETCH_SIZE_M);
    modify_field_with_hash_based_offset(sketch_metadata.sketch_idx_2, 0, hash_2, SKETCH_SIZE_M);
    modify_field_with_hash_based_offset(sketch_metadata.sketch_idx_3, 0, hash_3, SKETCH_SIZE_M);
    modify_field_with_hash_based_offset(sketch_metadata.sketch_idx_4, 0, hash_4, SKETCH_SIZE_M);
}
table table_sketch_indexes{
    actions{ do_sketch_indexes; }
}

action do_sketch_read_path_tags(){
    register_read(sketch_metadata.sketch_val_1, sketch_path_tags, 0*SKETCH_SIZE_M + sketch_metadata.sketch_idx_1);
    register_read(sketch_metadata.sketch_val_2, sketch_path_tags, 1*SKETCH_SIZE_M + sketch_metadata.sketch_idx_2);
    register_read(sketch_metadata.sketch_val_3, sketch_path_tags, 2*SKETCH_SIZE_M + sketch_metadata.sketch_idx_3);
    register_read(sketch_metadata.sketch_val_4, sketch_path_tags, 3*SKETCH_SIZE_M + sketch_metadata.sketch_idx_4);
}
action do_sketch_update_path_tags(){
    register_write(sketch_path_tags, 0*SKETCH_SIZE_M + sketch_metadata.sketch_idx_1, veridp_h.bf_tag);
    register_write(sketch_path_tags, 1*SKETCH_SIZE_M + sketch_metadata.sketch_idx_2, veridp_h.bf_tag);
    register_write(sketch_path_tags, 2*SKETCH_SIZE_M + sketch_metadata.sketch_idx_3, veridp_h.bf_tag);
    register_write(sketch_path_tags, 3*SKETCH_SIZE_M + sketch_metadata.sketch_idx_4, veridp_h.bf_tag);
}
table table_sketch_read_path_tags{
    actions{ do_sketch_read_path_tags; }
}
table table_sketch_update_path_tags{
    actions{ do_sketch_update_path_tags; }
}

action do_sketch_read_changes(){
    register_read(sketch_metadata.sketch_val_1, sketch_path_changes, 0*SKETCH_SIZE_M + sketch_metadata.sketch_idx_1);
    register_read(sketch_metadata.sketch_val_2, sketch_path_changes, 1*SKETCH_SIZE_M + sketch_metadata.sketch_idx_2);
    register_read(sketch_metadata.sketch_val_3, sketch_path_changes, 2*SKETCH_SIZE_M + sketch_metadata.sketch_idx_3);
    register_read(sketch_metadata.sketch_val_4, sketch_path_changes, 3*SKETCH_SIZE_M + sketch_metadata.sketch_idx_4);
}
action do_sketch_update_changes(){
    add_to_field(sketch_metadata.sketch_val_1, 1); /* Sketch sketch_path_changes row 1 */
    register_write(sketch_path_changes, 0*SKETCH_SIZE_M + sketch_metadata.sketch_idx_1, sketch_metadata.sketch_val_1);
    add_to_field(sketch_metadata.sketch_val_2, 1); /* Sketch sketch_path_changes row 2 */
    register_write(sketch_path_changes, 1*SKETCH_SIZE_M + sketch_metadata.sketch_idx_2, sketch_metadata.sketch_val_2);
    add_to_field(sketch_metadata.sketch_val_3, 1); /* Sketch sketch_path_changes row 3 */
    register_write(sketch_path_changes, 2*SKETCH_SIZE_M + sketch_metadata.sketch_idx_3, sketch_metadata.sketch_val_3);
    add_to_field(sketch_metadata.sketch_val_4, 1); /* Sketch sketch_path_changes row 4 */
    register_write(sketch_path_changes, 3*SKETCH_SIZE_M + sketch_metadata.sketch_idx_4, sketch_metadata.sketch_val_4);
}
table table_sketch_read_changes{
    actions{ do_sketch_read_changes; }
}
table table_sketch_update_changes{
    actions{ do_sketch_update_changes; }
}