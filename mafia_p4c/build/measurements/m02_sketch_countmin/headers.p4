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


header_type vlan_t {
  fields{
      pcp: 3;
      dei: 1;
      vid: 12;
      ether_type: 16;
  }
}
header vlan_t vlan;


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
      countmin_hash_h_0: 2;
      countmin_hash_index_0: 8;
      countmin_hash_h_1: 2;
      countmin_hash_index_1: 8;
      countmin_hash_h_2: 2;
      countmin_hash_index_2: 8;
      countmin_hash_h_3: 2;
      countmin_hash_index_3: 8;
      countmin_sketch: 32;
      countmin_sketch_lambda_val: 32;
  }
}
metadata mafia_metadata_t mafia_metadata;


header_type intrinsic_metadata_t {
  fields{
      ingress_global_timestamp: 48;
      lf_field_list: 32;
      mcast_grp: 16;
      egress_rid: 16;
  }
}
metadata intrinsic_metadata_t intrinsic_metadata;


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


