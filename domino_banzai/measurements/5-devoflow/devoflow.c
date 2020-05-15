
// #include "hashes.h"
// Relative path from where the domino compiler is located
#include "../domino-compiler/examples/hashes.h"

#define THRESHOLD 999
#define PKTS_TH  THRESHOLD
#define BYTES_TH THRESHOLD

struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;

  int flow_index;
  int pkt_len;
  int timestamp;
  int pkts_th_exceeded;
  int bytes_th_exceeded;
};

#define NUM_ENTRIES 4096

int pkt_counter[NUM_ENTRIES] = {0};
int bytes_counter[NUM_ENTRIES] = {0};


void func(struct Packet p) {
  p.flow_index = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  
  pkt_counter[p.flow_index] += 1;
  bytes_counter[p.flow_index] += p.pkt_len;

  if(pkt_counter[p.flow_index] > PKTS_TH){
      p.pkts_th_exceeded = 1;
  }
  if(bytes_counter[p.flow_index] > BYTES_TH){
      p.bytes_th_exceeded = 1;
  }

}
