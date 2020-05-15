
from .p4code import *
from ..util.util import indent_str


class P4Headers(object):
    def __init__(self):
        self.headers = dict()
        self.metadata = dict()

    def to_string(self):
        return '\n'.join("%s" % h.to_string() for name, h in self.headers.items()) \
                + '\n' + \
                '\n'.join("%s" % m.to_string() for name, m in self.metadata.items())

    def __str__(self):
        return self.to_string()

    def lookup(self, header_name, header_field):
        try:
            return ( header_field, self.headers[header_name].fields.lookup(header_field))
        except KeyError:
            return None

    def register_header(self, header):
        if not isinstance(header, P4Header):
            raise  TypeError("P4Header")
        else:
            self.headers[header.instance_name] = header

    def register_metadata(self, metadata):
        if not isinstance(metadata, P4Header):
            raise TypeError("P4Header")
        else:
            self.metadata[metadata.instance_name] = metadata

    def register_mafia_metadata_field(self, fields):
        for tmp in fields:
            (name, width) = tmp
            f = P4HeaderField(name, 0, width)
            self.metadata["mafia_metadata"].add_field(f)

    def declare_ethernet(self):
        eth = P4Header("ethernet_t", "eth", 0)

        dstAddr = P4HeaderField("dst", 0, 48)
        srcAddr = P4HeaderField("src", 0, 48)
        etherType = P4HeaderField("ether_type", 0, 16)

        eth.add_field(dstAddr)
        eth.add_field(srcAddr)
        eth.add_field(etherType)

        self.register_header(eth)

    def declare_vlan(self):
        vlan = P4Header("vlan_t", "vlan", 0)

        pcp = P4HeaderField("pcp", 0, 3)
        dei = P4HeaderField("dei", 0, 1)
        vid = P4HeaderField("vid", 0, 12)
        ethertype = P4HeaderField("ether_type", 0, 16)

        vlan.add_field(pcp)
        vlan.add_field(dei)
        vlan.add_field(vid)
        vlan.add_field(ethertype)

        self.register_header(vlan)

    def declare_ipv4(self):
        ipv4 = P4Header("ipv4_t", "ipv4", 0)

        ipv4_version = P4HeaderField("version", 0, 4)
        ipv4_ihl = P4HeaderField("ihl", 0, 4)
        ipv4_diffserv = P4HeaderField("tos", 0, 8)
        ipv4_totalLen = P4HeaderField("totalLen", 0, 16)
        ipv4_identification = P4HeaderField("identification", 0, 16)
        ipv4_flags = P4HeaderField("flags", 0, 3)
        ipv4_fragOffset = P4HeaderField("fragOffset", 0, 13)
        ipv4_ttl = P4HeaderField("ttl", 0, 8)
        ipv4_protocol = P4HeaderField("protocol", 0, 8)
        ipv4_checksum = P4HeaderField("checksum", 0, 16)
        ipv4_src = P4HeaderField("src", 0, 32)
        ipv4_dst = P4HeaderField("dst", 0, 32)

        ipv4.add_field(ipv4_version)
        ipv4.add_field(ipv4_ihl)
        ipv4.add_field(ipv4_diffserv)
        ipv4.add_field(ipv4_totalLen)
        ipv4.add_field(ipv4_identification)
        ipv4.add_field(ipv4_flags)
        ipv4.add_field(ipv4_fragOffset)
        ipv4.add_field(ipv4_ttl)
        ipv4.add_field(ipv4_protocol)
        ipv4.add_field(ipv4_checksum)
        ipv4.add_field(ipv4_src)
        ipv4.add_field(ipv4_dst)

        self.register_header(ipv4)

    def declare_tcp(self):
        tcp = P4Header("tcp_t", "tcp", 0)

        tcp_src_port = P4HeaderField("src", 0, 16)
        tcp_dst_port = P4HeaderField("dst", 0, 16)
        tcp_seq_n = P4HeaderField("seq_n", 0, 32)
        tcp_ack_n = P4HeaderField("ack_n", 0, 32)
        tcp_data_offset = P4HeaderField("data_offset", 0, 4)
        tcp_res = P4HeaderField("res", 0, 3)
        tcp_ecn = P4HeaderField("ecn", 0, 3)
        tcp_ctrl = P4HeaderField("ctrl", 0, 6)
        tcp_window = P4HeaderField("window", 0, 16)
        tcp_checksum = P4HeaderField("checksum", 0, 16)
        tcp_urgent = P4HeaderField("urgent", 0, 16)

        tcp.add_field(tcp_src_port)
        tcp.add_field(tcp_dst_port)
        tcp.add_field(tcp_seq_n)
        tcp.add_field(tcp_ack_n)
        tcp.add_field(tcp_data_offset)
        tcp.add_field(tcp_res)
        tcp.add_field(tcp_ecn)
        tcp.add_field(tcp_ctrl)
        tcp.add_field(tcp_window)
        tcp.add_field(tcp_checksum)
        tcp.add_field(tcp_urgent)

        self.register_header(tcp)

    def declare_udp(self):
        udp = P4Header("udp_t", "udp", 0)

        udp_src_port = P4HeaderField("src", 0, 16)
        udp_dst_port = P4HeaderField("dst", 0, 16)
        udp_length = P4HeaderField("udp_size", 0, 16)
        udp_checksum = P4HeaderField("checksum", 0, 16)
        

        udp.add_field(udp_src_port)
        udp.add_field(udp_dst_port)
        udp.add_field(udp_length)
        udp.add_field(udp_checksum)
        

        self.register_header(udp)

    def declare_icmp(self):
        icmp = P4Header("icmp_t", "icmp", 0)

        icmp_type = P4HeaderField("icmp_type", 0, 8)
        icmp_code = P4HeaderField("icmp_code", 0, 8)
        icmp_checksum = P4HeaderField("checksum", 0, 16)
        icmp_data = P4HeaderField("icmp_data", 0, 32)
        

        icmp.add_field(icmp_type)
        icmp.add_field(icmp_code)
        icmp.add_field(icmp_checksum)
        icmp.add_field(icmp_data)
        

        self.register_header(icmp)

    def declare_standard_metadata(self):
        # This metadata is already implicit in the P4 compiler
        standard_metadata = P4Header("standard_metadata_t", "standard_metadata", 1, 0)

        metadata_ingress_port = P4HeaderField("ingress_port", 0, 8)
        metadata_egress_port = P4HeaderField("egress_port", 0, 8)
        metadata_egress_spec = P4HeaderField("egress_spec", 0, 16)
        metadata_egress_instance = P4HeaderField("egress_instance", 0, 16)
        metadata_instance_type = P4HeaderField("instance_type", 0, 16)
        metadata_packet_length = P4HeaderField("packet_length", 0, 32)

        standard_metadata.add_field(metadata_ingress_port)
        standard_metadata.add_field(metadata_egress_port)
        standard_metadata.add_field(metadata_egress_spec)
        standard_metadata.add_field(metadata_egress_instance)
        standard_metadata.add_field(metadata_instance_type)
        standard_metadata.add_field(metadata_packet_length)

        self.register_metadata(standard_metadata)

    def declare_intrinsic_metadata(self):
        intrinsic_metadata = P4Header("intrinsic_metadata_t", "intrinsic_metadata", 1)

        metadata_ts = P4HeaderField("ingress_global_timestamp", 0, 48)
        metadata_lf_field_list = P4HeaderField("lf_field_list", 0, 32)
        metadata_mcast_grp = P4HeaderField("mcast_grp", 0, 16)
        metadata_egress_rid = P4HeaderField("egress_rid", 0, 16)

        intrinsic_metadata.add_field(metadata_ts)
        intrinsic_metadata.add_field(metadata_lf_field_list)
        intrinsic_metadata.add_field(metadata_mcast_grp)
        intrinsic_metadata.add_field(metadata_egress_rid)

        self.register_metadata(intrinsic_metadata)

    def declare_queueing_metadata(self):
        queueing_metadata = P4Header("queueing_metadata_t", "queueing_metadata", 1)

        enq_ts = P4HeaderField("enq_ts", 0, 48)
        enq_qdepth = P4HeaderField("enq_qdepth", 0, 16)
        deq_timedelta = P4HeaderField("deq_timedelta", 0, 32)
        deq_qdepth = P4HeaderField("deq_qdepth", 0, 16)
        qid = P4HeaderField("qid", 0, 8)

        queueing_metadata.add_field(enq_ts)
        queueing_metadata.add_field(enq_qdepth)
        queueing_metadata.add_field(deq_timedelta)
        queueing_metadata.add_field(deq_qdepth)
        queueing_metadata.add_field(qid)

        self.register_metadata(queueing_metadata)

    def declare_forwarding_metadata(self):
        fwd_metadata = P4Header("fwd_metadata_t", "fwd_metadata", 1)
        
        next_hop_mac = P4HeaderField("next_hop_mac", 0, 48)
        prev_hop_mac = P4HeaderField("prev_hop_mac", 0, 48)
        in_port = P4HeaderField("in_port", 0, 32)
        out_port = P4HeaderField("out_port", 0, 32)
        fwd_metadata.add_field(next_hop_mac)
        fwd_metadata.add_field(prev_hop_mac)
        fwd_metadata.add_field(in_port)
        fwd_metadata.add_field(out_port)

        self.register_metadata(fwd_metadata)

    def declare_mafia_metadata(self):
        mafia_metadata = P4Header("mafia_metadata_t", "mafia_metadata", 1)
        switch_id = P4HeaderField("switch_id", 0, 8)
        last_hop = P4HeaderField("is_last_hop", 0, 1)
        first_hop = P4HeaderField("is_first_hop", 0, 1)

        mafia_metadata.add_field(switch_id)
        mafia_metadata.add_field(first_hop)
        mafia_metadata.add_field(last_hop)
        self.register_metadata(mafia_metadata)

    def declare_rng_fake_metadata(self):
        rng_metadata = P4Header("rng_metadata_t", "rng_metadata", 1)
        fake_metadata = P4HeaderField("fake_metadata", 0, 4096)

        rng_metadata.add_field(fake_metadata)
        self.register_metadata(rng_metadata)


class P4Header(object):
    def __init__(self, type_name, instance_name, is_metadata, requires_format = 1):
        self.type_name = type_name
        self.instance_name = instance_name
        self.is_metadata = is_metadata
        self.requires_format = requires_format
        self.fields = P4HeaderFieldList()

    def add_field(self, f):
        if(isinstance(f, P4HeaderField)):
            self.fields.add_field(f)
        else:
            raise TypeError("P4HeaderField")

    def to_string(self):
        self_str = p4header % (self.type_name, indent_str(self.fields.to_string(), 2))
        if(self.is_metadata):
            self_str = self_str + "\n" + "metadata " + self.type_name + " " + self.instance_name + ";\n\n"
        else:
            self_str = self_str + "\n" + "header " + self.type_name + " " + self.instance_name + ";\n\n"
        return self_str if (self.requires_format) else ""

    def __str__(self):
        return self.to_string()

class P4HeaderFieldList(object):
    def __init__(self):
        self.fields = list()

    def add_field(self, f):
        if(isinstance(f, P4HeaderField)):
            self.fields.append(f)
        else:
            raise TypeError("P4HeaderField")

    def lookup(self, field):
        for f in self.fields:
            if f.name == field:
                return f
        return None

    def to_string(self):
        # return p4headerfields % ("\t%s\n" % f.to_string() for f in self.fields)
        return p4headerfields % ('\n'.join("%s" % indent_str(f.to_string(), 4) for f in self.fields))

    def __str__(self):
        return self.to_string()

class P4HeaderField(object):
    def __init__(self, name, value, width):
        self.name = name
        self.value = value
        self.width = width

    def to_string(self):
        return "%s: %d;" % (self.name, self.width)

    def __str__(self):
        return self.to_string()
