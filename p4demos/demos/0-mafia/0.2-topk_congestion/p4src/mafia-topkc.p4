
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/state.p4"

#define N_FLOWS_ENTRIES     1024 // Number of entries for flows (2^10)

metadata queueing_metadata_t  queueing_metadata;
metadata intrinsic_metadata_t intrinsic_metadata;

// action _drop() { drop(); }
action _no_op(){ no_op(); }

control ingress {
    
}

control egress {
    apply(table_topkc_switch_net_entry){
        hit{
            if(not valid(topkc)) apply(table_topkc_select);
        }
    }

    apply(table_topkc_check){
        miss{
            if(topkc_hop_metadata.marker == 0x01){
                if(valid(topkc)){
                    apply( table_topkc_accumulate_q_len );
                    apply( table_topkc_accumulate_q_time );
                }
            }
        }
    }

    apply(table_veridp_switch_net_exit){
        hit{
            if(valid(topkc)) apply(table_topkc_sketch);
        }
    }
}

table table_topkc_switch_net_entry{
    reads{ ethernet.srcAddr: exact; }
    actions { _no_op; }
    size: N_FLOWS_ENTRIES;
}
table table_veridp_switch_net_exit{
    reads{ ethernet.dstAddr: exact;}
    actions { _no_op; }
    size: N_FLOWS_ENTRIES;
}


action do_topkc_select(){
    add_header  ( topkc );
    bit_or      ( ipv4.tos, ipv4.tos, 0x01 );
    modify_field( ipv4.protocol, IPPROTO_TOPKC);
}
table table_topkc_select{
    actions{do_topkc_select;}
}

action do_topkc_check(){
    bit_and( topkc_hop_metadata.marker, ipv4.tos, 0x01 );
}
table table_topkc_check{
    actions{do_topkc_check;}
}


action do_topkc_accumulate_q_len() {
    modify_field( topkc_hop_metadata.q_length, topkc.q_length_tag );
    add_to_field( topkc_hop_metadata.q_length, queueing_metadata.enq_qdepth );
    modify_field( topkc.q_length_tag,            topkc_hop_metadata.q_length );
}
table table_topkc_accumulate_q_len {
    actions { do_topkc_accumulate_q_len; }
}

action do_topkc_accumulate_q_time() {
    modify_field(        topkc_hop_metadata.q_time,  queueing_metadata.enq_timestamp );
    add_to_field(        topkc_hop_metadata.q_time,  queueing_metadata.deq_timedelta );
    subtract_from_field( topkc_hop_metadata.q_time,  intrinsic_metadata.ingress_global_timestamp);
    modify_field(        topkc.q_time_tag,            topkc_hop_metadata.q_time );
}
table table_topkc_accumulate_q_time {
    actions { do_topkc_accumulate_q_time; }
}


action do_sketch_indexes(){
    modify_field_with_hash_based_offset(topkc_sketch_metadata.sketch_idx_1, 0, hash_1, SKETCH_SIZE_M);
    modify_field_with_hash_based_offset(topkc_sketch_metadata.sketch_idx_2, 0, hash_2, SKETCH_SIZE_M);
    modify_field_with_hash_based_offset(topkc_sketch_metadata.sketch_idx_3, 0, hash_3, SKETCH_SIZE_M);
    modify_field_with_hash_based_offset(topkc_sketch_metadata.sketch_idx_4, 0, hash_4, SKETCH_SIZE_M);
}

action do_sketch_read_n_packets(){
    register_read(topkc_sketch_metadata.sketch_count_1, sketch_n_packets, 0*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_1);
    register_read(topkc_sketch_metadata.sketch_count_2, sketch_n_packets, 1*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_2);
    register_read(topkc_sketch_metadata.sketch_count_3, sketch_n_packets, 2*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_3);
    register_read(topkc_sketch_metadata.sketch_count_4, sketch_n_packets, 3*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_4);
}
action do_sketch_update_n_packets(){
    add_to_field(topkc_sketch_metadata.sketch_count_1, 1); /* Sketch n_packets row 1 */
    register_write(sketch_n_packets, 0*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_1, topkc_sketch_metadata.sketch_count_1);
    add_to_field(topkc_sketch_metadata.sketch_count_2, 1); /* Sketch n_packets row 2 */
    register_write(sketch_n_packets, 1*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_2, topkc_sketch_metadata.sketch_count_2);
    add_to_field(topkc_sketch_metadata.sketch_count_3, 1); /* Sketch n_packets row 3 */
    register_write(sketch_n_packets, 2*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_3, topkc_sketch_metadata.sketch_count_3);
    add_to_field(topkc_sketch_metadata.sketch_count_4, 1); /* Sketch n_packets row 4 */
    register_write(sketch_n_packets, 3*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_4, topkc_sketch_metadata.sketch_count_4);
}

action do_sketch_read_q_lengths(){
    register_read(topkc_sketch_metadata.sketch_count_1, sketch_q_lengths, 0*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_1);
    register_read(topkc_sketch_metadata.sketch_count_2, sketch_q_lengths, 1*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_2);
    register_read(topkc_sketch_metadata.sketch_count_3, sketch_q_lengths, 2*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_3);
    register_read(topkc_sketch_metadata.sketch_count_4, sketch_q_lengths, 3*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_4);
}
action do_sketch_update_q_lengths(){
    add_to_field(topkc_sketch_metadata.sketch_count_1, topkc.q_length_tag); /* Sketch q_lengths row 1 */
    register_write(sketch_q_lengths, 0*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_1, topkc_sketch_metadata.sketch_count_1);
    add_to_field(topkc_sketch_metadata.sketch_count_2, topkc.q_length_tag); /* Sketch q_lengths row 2 */
    register_write(sketch_q_lengths, 1*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_2, topkc_sketch_metadata.sketch_count_2);
    add_to_field(topkc_sketch_metadata.sketch_count_3, topkc.q_length_tag); /* Sketch q_lengths row 3 */
    register_write(sketch_q_lengths, 2*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_3, topkc_sketch_metadata.sketch_count_3);
    add_to_field(topkc_sketch_metadata.sketch_count_4, topkc.q_length_tag); /* Sketch q_lengths row 4 */
    register_write(sketch_q_lengths, 3*SKETCH_SIZE_M + topkc_sketch_metadata.sketch_idx_4, topkc_sketch_metadata.sketch_count_4);
}

action do_topkc_sketch(){
    do_sketch_indexes();
    do_sketch_read_n_packets();
    do_sketch_update_n_packets();
    do_sketch_read_q_lengths();
    do_sketch_update_q_lengths();
}
table table_topkc_sketch{
    actions{ do_topkc_sketch; }
}