import socket
import struct
from bitarray import bitarray


### DEFINITIONS
LLDP_TYPE = 0x88cc
ARP_TYPE = 0x806
IP_TYPE = 0x800
IPV6_TYPE = 0x86dd
TCP_TYPE = 0x6
UDP_TYPE = 0x11


################################################################################
# Fixed width stuff
################################################################################

class IPPrefix(object):
    def __init__(self, pattern):
        self.masklen = 32
        parts = pattern.split("/")
        self.pattern = IP(parts[0])
        if len(parts) == 2:
            self.masklen = int(parts[1])
        else:
            raise TypeError
        self.prefix = self.pattern.to_bits()[:self.masklen]

    def __eq__(self, other):
        """Match by checking prefix equality"""
        if isinstance(other, IPAddr):
            return self.prefix == other.to_bits()[:self.masklen]
        else:
            return False

    def __ne__(self, other):
        return not (self == other)

    def __hash__(self):
        return hash((self.pattern, self.masklen))

    def __repr__(self):
        return "%s/%d" % (repr(self.pattern), self.masklen)


class IPAddr(object):
    def __init__(self, ip):

        # already a IP object
        if isinstance(ip, IPAddr):
            self.bits = ip.bits

        # otherwise will be in byte or string encoding
        else:
            assert isinstance(ip, basestring)

            b = bitarray()

            # byte encoding
            if len(ip) == 4:
                b.frombytes(ip)

            # string encoding
            else:
                b.frombytes(socket.inet_aton(ip))

            self.bits = b

    def to_bits(self):
        return self.bits

    def to01(self):
        return self.bits.to01()

    def to_bytes(self):
        return self.bits.tobytes()

    def fromRaw(self):
        return self.to_bytes()

    def __repr__(self):
        return socket.inet_ntoa(self.to_bytes())

    def __hash__(self):
        return hash(self.to_bytes())

    def __eq__(self, other):
        return repr(self) == repr(other)

    def __ne__(self, other):
        return not (self == other)


class IP(IPAddr):
    pass


class EthAddr(object):
    def __init__(self, mac):

        # already a MAC object
        if isinstance(mac, EthAddr):
            self.bits = mac.bits

        # otherwise will be in byte or string encoding
        else:
            assert isinstance(mac, basestring)

            b = bitarray()

            # byte encoding
            if len(mac) == 6:
                b.frombytes(mac)

            # string encoding
            else:
                import re
                m = re.match(r"""(?xi)
                             ([0-9a-f]{1,2})[:-]+
                             ([0-9a-f]{1,2})[:-]+
                             ([0-9a-f]{1,2})[:-]+
                             ([0-9a-f]{1,2})[:-]+
                             ([0-9a-f]{1,2})[:-]+
                             ([0-9a-f]{1,2})
                             """, mac)
                if not m:
                    raise ValueError
                else:
                    b.frombytes(struct.pack("!BBBBBB", *(int(s, 16) for s in m.groups())))

            self.bits = b

    def to_bits(self):
        return self.bits

    def to01(self):
        return self.bits.to01()

    def to_bytes(self):
        return self.bits.tobytes()

    def __repr__(self):
        parts = struct.unpack("!BBBBBB", self.to_bytes())
        mac = ":".join(hex(part)[2:].zfill(2) for part in parts)
        return mac

    def __hash__(self):
        return hash(self.to_bytes())

    def __eq__(self, other):
        return repr(self) == repr(other)

    def __ne__(self, other):
        return not (self == other)


class MAC(EthAddr):
    pass


################################################################################
# Tools
################################################################################
class Port(object):
    def __init__(self, port_no, config=True, status=True, port_type=[], linked_to=None):
        self.port_no = port_no
        self.config = config
        self.status = status
        self.linked_to = linked_to
        self.port_type = port_type

    def definitely_down(self):
        return not self.config and not self.status

    def possibly_up(self):
        """User switch reports ports having LINK_DOWN status when in fact link is up"""
        return not self.definitely_down()

    def __hash__(self):
        return hash(self.port_no)

    def __eq__(self, other):
        return (self.port_no == other.port_no and
                self.config == other.config and
                self.status == other.status and
                self.linked_to == other.linked_to)

    def __repr__(self):
        return "%d:config_up=%s:status_up=%s:linked_to=%s:port_type=%s" % (
            self.port_no, self.config, self.status, self.linked_to, self.port_type)


class Location(object):
    def __init__(self, switch, port_no):
        self.switch = switch
        self.port_no = port_no

    def __hash__(self):
        return hash((self.switch, self.port_no))

    def __eq__(self, other):
        if other is None:
            return False
        return self.switch == other.switch and self.port_no == other.port_no

    def __repr__(self):
        return "%s[%s]" % (self.switch, self.port_no)