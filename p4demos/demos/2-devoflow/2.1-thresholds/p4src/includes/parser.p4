
#define ETHERTYPE_IPV4 0x0800
#define IPPROTO_TCP 6

header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
header notification_header_t notification_header;

parser start {
    return select(current(0, 64)) {
        0 : parse_notification_header;
        default: parse_ethernet;
    }
}

parser parse_notification_header{
  extract(notification_header);
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
        default: ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}
