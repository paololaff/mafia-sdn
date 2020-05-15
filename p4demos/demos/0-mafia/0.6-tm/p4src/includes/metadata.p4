

header_type intrinsic_metadata_t {
    fields {
        ingress_global_timestamp : 48;
        lf_field_list : 32;
        mcast_grp : 16;
        egress_rid : 16;
    }
}

header_type queueing_metadata_t {
    fields {
        enq_timestamp   : 48;
        enq_qdepth      : 16;
        deq_timedelta   : 32;
        deq_qdepth      : 16;
        qid             : 8;
    }
}

header_type fwd_metadata_t {
  fields {
    nhop_ipv4   : 32;
  }
}

metadata fwd_metadata_t fwd_metadata;
metadata queueing_metadata_t queueing_metadata;
metadata intrinsic_metadata_t intrinsic_metadata;

field_list sample_metadata_copy {    
    standard_metadata; // For "instance_type" field!
    intrinsic_metadata; // For the packet timestamp
    queueing_metadata; 
}
