
#define SIZEOF_ETHERNET_H 14 // 112 div  8
#define SIZEOF_IPV4_H 20 // 160 div 8
#define SIZEOF_TCP_H 20 // 160 div 8
#define SIZEOF_NOTIFICATION_H 2 // 16 div 8

#define SIZEOF_NOTIFICATION_PACKET 56

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 3;
        ecn : 3;
        flags : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type notification_header_t{
  fields{
    device: 8;
    reason: 8;
    counter_val: 32;
  }
}


header_type intrinsic_metadata_t {
    fields {
        ingress_global_timestamp : 48;
        lf_field_list : 32;
        mcast_grp : 16;
        egress_rid : 16;
    }
}

metadata intrinsic_metadata_t intrinsic_metadata;
