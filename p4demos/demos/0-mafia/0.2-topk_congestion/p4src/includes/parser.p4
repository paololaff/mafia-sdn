
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_VLAN 0x8100
#define IPPROTO_TCP    6
#define IPPROTO_TOPKC  0xED

header ethernet_t ethernet;
header vlan_t     vlan;
header ipv4_t     ipv4;
header tcp_t      tcp;
header topkc_t    topkc;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.ethertype) {
        ETHERTYPE_VLAN : parse_vlan;
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

parser parse_vlan {
    extract(vlan);
    return select(latest.ethertype) {
        0x800:      parse_ipv4;
        default:    ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        IPPROTO_TCP    : parse_tcp;
        IPPROTO_TOPKC  : parse_topkc;
        default: ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_topkc{
    extract(tcp);
    extract(topkc);
    return ingress;
}


