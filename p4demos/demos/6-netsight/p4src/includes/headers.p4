
#define SIZEOF_ETHERNET_H 14 // 112 div 8
#define SIzEOF_VLAN_H      4 // 32  div 8
#define SIZEOF_IPV4_H     20 // 160 div 8
#define SIZEOF_TCP_H      20 // 160 div 8
#define SIZEOF_POSTCARD_H 58

#define VLAN_PCP_BESTEFFORT     0 // best effort (default)
#define VLAN_PCP_BACKGROUND     1 // background
#define VLAN_PCP_EXCELLENT      2 // excellent effort
#define VLAN_PCP_CRITICAL       3 // critical application
#define VLAN_PCP_VIDEO          4 // video
#define VLAN_PCP_VOICE          5 // voice
#define VLAN_PCP_INTERNET_CTRL  6 // internetwork control
#define VLAN_PCP_NET_CTRL       7 // network control

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
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

header_type intrinsic_metadata_t {
    fields {
        ingress_global_timestamp : 48;
        lf_field_list : 32;
        mcast_grp : 16;
        egress_rid : 16;
    }
}

header_type fwd_metadata_t {
  fields {
    nhop_ipv4   : 32;
  }
}

metadata fwd_metadata_t fwd_metadata;
metadata intrinsic_metadata_t intrinsic_metadata;
