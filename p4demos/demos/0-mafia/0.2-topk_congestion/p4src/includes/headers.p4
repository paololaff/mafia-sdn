
#define SIZEOF_ETHERNET_H 14 // 112 div 8
#define SIZEOF_VLAN_H      4 // 32  div 8
#define SIZEOF_IPV4_H     20 // 160 div 8
#define SIZEOF_TCP_H      20 // 160 div 8

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header_type vlan_t {
    fields {
        pcp       : 3;  // Priority Code Point
        dei       : 1;  // Drop Eligible Indicator
        vid       : 12;
        ethertype : 16;
    }
}

header_type ipv4_t {
    fields {
        version         : 4;
        ihl             : 4;
        tos             : 8;  // VeriDP marks a bit here to indicate packets selected for verification. We will use the lowest order
        totalLen        : 16;
        identification  : 16;
        flags           : 3;
        fragOffset      : 13;
        ttl             : 8;
        protocol        : 8;
        hdrChecksum     : 16;
        srcAddr         : 32;
        dstAddr         : 32;
    }
}

header_type tcp_t {
    fields {
        srcPort     : 16;
        dstPort     : 16;
        seqNo       : 32;
        ackNo       : 32;
        dataOffset  : 4;
        res         : 3;
        ecn         : 3;
        flags       : 6;
        window      : 16;
        checksum    : 16;
        urgentPtr   : 16;
    }
}

header_type topkc_t {
    fields{
        q_length_tag : 32;
        q_time_tag   : 48;
    }
}

header_type intrinsic_metadata_t {
    fields {
        ingress_global_timestamp : 48;
        lf_field_list            : 32;
        mcast_grp                : 16;
        egress_rid               : 16;
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
