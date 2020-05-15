
// #include "hashes.h"
// Relative path from where the domino-examples repository is located
#include "../domino-compiler/examples/hashes.h"

struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;

  int flow_index;
  int pkt_len;
  int timestamp;
};

#define NUM_ENTRIES 4096

int bytes_counter[NUM_ENTRIES] = {0};
int packet_counter[NUM_ENTRIES] = {0};
int now_ts[NUM_ENTRIES] = {0};
int start_ts[NUM_ENTRIES] = {0};
int flow_duration[NUM_ENTRIES] = {0};

void func(struct Packet p) {
  p.flow_index = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  // p.flow_index = 0;
  bytes_counter[p.flow_index] += p.pkt_len;
  packet_counter[p.flow_index] += 1;

  if(start_ts[p.flow_index] == 0) start_ts[p.flow_index] = p.timestamp;
    
  now_ts[p.flow_index] = p.timestamp;
  flow_duration[p.flow_index] = now_ts[p.flow_index] - start_ts[p.flow_index];
}
