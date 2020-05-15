
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

  int pcsa_hash;
  int hash_output_bitmap;
  int hash_output_index;

  int pcsa_sketch_idx;
};

#define NUM_ENTRIES 512

int pcsa_sketch[NUM_ENTRIES] = {0};

void func(struct Packet p) {
  p.pcsa_hash = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  p.hash_output_bitmap = p.pcsa_hash >> 28;
  p.hash_output_index = p.pcsa_hash & 0x0FFFFFFF;
  p.pcsa_sketch_idx = p.hash_output_bitmap * 32 + p.hash_output_index;
  // p.pcsa_sketch_idx = ((p.pcsa_hash >> 28) * 32) + (p.pcsa_hash & 0x0FFFFFFF);
  pcsa_sketch[p.pcsa_sketch_idx] = 1;
}
