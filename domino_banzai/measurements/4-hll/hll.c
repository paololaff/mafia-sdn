
// #include "hashes.h"
// Relative path from where the domino-examples repository is located
#include "../domino-compiler/examples/hashes.h"

#define low_th 100
#define hi_th  1000

struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;

  int hll_hash;
  int hash_output_idx;
  int hash_output_value;
};

#define NUM_ENTRIES 64

int hll_sketch[NUM_ENTRIES] = {0};

void func(struct Packet p) {
  p.hll_hash = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  p.hash_output_idx = p.hll_hash >> 26;
  p.hash_output_value = p.hll_hash & 0x03FFFFFF;
  hll_sketch[p.hash_output_idx] = p.hash_output_value;
}
