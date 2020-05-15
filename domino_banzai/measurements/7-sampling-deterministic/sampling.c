
// #include "hashes.h"
// Relative path from where the domino compiler is located
#include "../domino-compiler/examples/hashes.h"

struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;

  int flow_index;
};

#define NUM_ENTRIES 4096

int n[NUM_ENTRIES] = {0};
int m[NUM_ENTRIES] = {0};
int delta[NUM_ENTRIES] = {0};


void func(struct Packet p) {
  p.flow_index = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  // p.flow_index = 0;
  n[p.flow_index] += 1;
  delta[p.flow_index] += 1;

  if(delta[p.flow_index] > 25 && m[p.flow_index] < 10){
      m[p.flow_index] += 1;
  }

  if(n[p.flow_index] > 100){
      n[p.flow_index] = 0;
      m[p.flow_index] = 0;
      delta[p.flow_index] = 0;
  }
}
