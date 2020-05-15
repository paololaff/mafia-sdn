
// #include "hashes.h"
// Relative path from where the domino-examples repository is located
#include "../domino-compiler/examples/hashes.h"

struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;

  int input_port;
  int output_port;
  int switch_id;
  int bf;
  int local_bf;
  int bf_idx1;
  int bf_idx2;
  int bf_idx3;
};

#define BF_ENTRIES 16


void func(struct Packet p) {
  p.bf_idx1 = hash3(p.input_port, p.switch_id, p.output_port) % BF_ENTRIES;
  p.bf_idx2 = hash3(p.input_port, p.switch_id, p.output_port) % BF_ENTRIES;
  p.bf_idx3 = hash3(p.input_port, p.switch_id, p.output_port) % BF_ENTRIES;
  
  // local_bf[p.bf_idx1] = 1;
  // local_bf[p.bf_idx2] = 1;
  // local_bf[p.bf_idx3] = 1;
  
  p.local_bf = p.local_bf | (1 << p.bf_idx1);
  p.local_bf = p.local_bf | (1 << p.bf_idx2);
  p.local_bf = p.local_bf | (1 << p.bf_idx3);

  p.bf = p.bf | p.local_bf;

}
