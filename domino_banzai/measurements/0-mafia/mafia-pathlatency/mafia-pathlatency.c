
// #include "hashes.h"
// Relative path from where the domino-examples repository is located
#include "../domino-compiler/examples/hashes.h"

struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;

  int segway_message;
  int segway_latency;
  int timestamp;

  int flow_index;
};

#define NUM_ENTRIES 4096

int change_ts[NUM_ENTRIES] = {0};

void func(struct Packet p) {
 
 p.flow_index = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;

  if(p.segway_message == 0){
    change_ts[p.flow_index] = p.timestamp;
    p.segway_latency = change_ts[p.flow_index];    
  }     
}
