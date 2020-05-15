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


header_type icmp_t {
  fields{
      icmp_type: 8;
      icmp_code: 8;
      checksum: 16;
      icmp_data: 32;
  }
}
header icmp_t icmp;


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


header_type udp_t {
  fields{
      src: 16;
      dst: 16;
      udp_size: 16;
      checksum: 16;
  }
}
header udp_t udp;


header_type ethernet_t {
  fields{
      dst: 48;
      src: 48;
      ether_type: 16;
  }
}
header ethernet_t eth;


header_type vlan_t {
  fields{
      pcp: 3;
      dei: 1;
      vid: 12;
      ether_type: 16;
  }
}
header vlan_t vlan;


header_type queueing_metadata_t {
  fields{
      enq_ts: 48;
      enq_qdepth: 16;
      deq_timedelta: 32;
      deq_qdepth: 16;
      qid: 8;
  }
}
metadata queueing_metadata_t queueing_metadata;


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
      borders: 32;
      set_border_tag_lambda_val: 16;
      update_border_counter_lambda_val: 32;
  }
}
metadata mafia_metadata_t mafia_metadata;


header_type rng_metadata_t {
  fields{
      fake_metadata: 4096;
  }
}
metadata rng_metadata_t rng_metadata;


header_type intrinsic_metadata_t {
  fields{
      ingress_global_timestamp: 48;
      lf_field_list: 32;
      mcast_grp: 16;
      egress_rid: 16;
  }
}
metadata intrinsic_metadata_t intrinsic_metadata;


header_type fwd_metadata_t {
  fields{
      next_hop_mac: 48;
      prev_hop_mac: 48;
      in_port: 32;
      out_port: 32;
  }
}
metadata fwd_metadata_t fwd_metadata;



