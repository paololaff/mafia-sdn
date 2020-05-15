
#define ETHERTYPE_IPV4 0x0800
#define IPPROTO_TCP 6
#define IPPROTO_SAMPLE 255

header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
header sample_t sample_header;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        IPPROTO_TCP : parse_tcp;
        IPPROTO_SAMPLE: parse_sample;
        default: ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_sample {
    extract(tcp);
    extract(sample_header);
    return ingress;
}
