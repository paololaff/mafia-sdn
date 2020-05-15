
#define SIZEOF_ETHERNET_H 14 // 112 div 8
#define SIZEOF_VLAN_H      4 // 32  div 8
#define SIZEOF_IPV4_H     20 // 160 div 8
#define SIZEOF_TCP_H      20 // 160 div 8

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        ethertype : 16;
    }
}

header_type ipv4_t {
    fields {
        version         : 4;
        ihl             : 4;
        tos             : 8;
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

header_type segway_t{ // Header copied from ez-segway report
    fields{
        timestamp   : 48;  // Added
        msg_type    : 8;   // Message type of segway protocol // The only field used here...
        id          : 16;
        vol         : 4;
        old_lnk     : 8;
        new_lnk     : 8;
        pre_lnk     : 8;
        is_send_sw  : 1;
        version     : 8;
    }
}
