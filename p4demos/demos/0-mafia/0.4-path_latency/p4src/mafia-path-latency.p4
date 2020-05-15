
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/routing.p4"

#define SAMPLE_SESSION_ID 999

action _drop() { drop(); }
action _no_op(){ no_op(); }

control ingress {
    if(valid(segway_h)){
        if(segway_h.id == SEGWAY_TYPE_GOOD_TO_MOVE)
            apply(table_sample);
    }
}

control egress {
    apply(table_sample_redirect){
        hit{ apply(table_tag_timestamp); }
        miss{ apply(table_drop); }
    }    
}

action do_sample() {
    clone_ingress_pkt_to_egress(SAMPLE_SESSION_ID, sample_metadata_copy); // Clone packet
}
table table_sample {
    actions { do_sample; }
}


action do_tag_timestamp(){
    modify_field(        segway_h.timestamp,         intrinsic_metadata.ingress_global_timestamp );
    // modify_field(        topkc_hop_metadata.q_time,  queueing_metadata.enq_timestamp );
    // add_to_field(        topkc_hop_metadata.q_time,  queueing_metadata.deq_timedelta );
    // subtract_from_field( topkc_hop_metadata.q_time,  intrinsic_metadata.ingress_global_timestamp);
}
table table_tag_timestamp{
    actions{ do_tag_timestamp; }
}

action do_sample_redirect() {
    // We can add as parameter of the sampling the size of payload to transmit
    //truncate(SIZEOF_SAMPLE_HEADER); 
}
table table_sample_redirect { // Matches a sample clone
    reads{ standard_metadata.instance_type: exact; }
    actions { do_sample_redirect; _no_op; }
}

table table_drop {
    actions { _drop; }
}