
#include <tofino/intrinsic_metadata.p4>

header_type vlan_t {
  fields{
      pcp: 3;
      dei: 1;
      vid: 12;
      ether_type: 16;
  }
}
header vlan_t vlan;


header_type ipv4_t {
  fields{
      version: 4;
      ihl: 4;
      tos: 8;
      totalLen: 16;
      identification: 16;
      flags: 3;
      fragOffset: 13;
      ttl: 8;
      protocol: 8;
      checksum: 16;
      src: 32;
      dst: 32;
  }
}
header ipv4_t ipv4;


header_type tcp_t {
  fields{
      src: 16;
      dst: 16;
      seq_n: 32;
      ack_n: 32;
      data_offset: 4;
      res: 3;
      ecn: 3;
      ctrl: 6;
      window: 16;
      checksum: 16;
      urgent: 16;
  }
}
header tcp_t tcp;


header_type ethernet_t {
  fields{
      dst: 48;
      src: 48;
      ether_type: 16;
  }
}
header ethernet_t eth;


header_type rng_metadata_t {
  fields{
      fake_metadata: 4096;
  }
}
metadata rng_metadata_t rng_metadata;


header_type mafia_metadata_t {
  fields{
      switch_id: 8;
      is_first_hop: 1;
      is_last_hop: 1;
      pcsa_hash_0: 32;
      pcsa_hash_1: 32;
      hll_hash_0: 32;
      hll_hash_1: 32;
      flow_index: 64;
  }
}
metadata mafia_metadata_t mafia_metadata;



