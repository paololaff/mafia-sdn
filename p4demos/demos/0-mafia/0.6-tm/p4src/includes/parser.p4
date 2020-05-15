
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_VLAN 0x8100
#define IPPROTO_TCP    6

header ethernet_t ethernet;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
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
        IPPROTO_TCP : parse_tcp;
        default: ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}


