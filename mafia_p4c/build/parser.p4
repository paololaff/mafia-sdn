#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_VLAN 0x8100
#define IPPROTO_ICMP   1  // 0x01
#define IPPROTO_TCP    6  // 0x06
#define IPPROTO_UDP    17 // 0x11

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(eth);
    return select(latest.ether_type) {
        ETHERTYPE_VLAN : parse_vlan;
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

parser parse_vlan {
    extract(vlan);
    return select(latest.ether_type) {
        0x800:      parse_ipv4;
        default:    ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        IPPROTO_UDP : parse_udp;
        IPPROTO_TCP : parse_tcp;
        IPPROTO_ICMP : parse_icmp;
        default: ingress;
    }
}

parser parse_udp {
    extract(udp);
    return ingress;
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_icmp {
    extract(icmp);
    return ingress;
}
