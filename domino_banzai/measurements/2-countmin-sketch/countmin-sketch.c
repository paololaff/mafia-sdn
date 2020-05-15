
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

  // Outputs of the hash functions 
  int hash_output_h1;
  int hash_output_h2;
  int hash_output_h3;
  int hash_output_h4;
  int hash_output_idx1;
  int hash_output_idx2;
  int hash_output_idx3;
  int hash_output_idx4;

  // Actual index of the sketch computed with the hash outputs
  int sketch1_idx;
  int sketch2_idx;
  int sketch3_idx;
  int sketch4_idx;
};

#define NUM_ENTRIES 256*4

int sketch_cnt[NUM_ENTRIES] = {0};

void func(struct Packet p) {
  p.hash_output_idx1 = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  p.hash_output_idx2 = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  p.hash_output_idx3 = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
  p.hash_output_idx4 = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;

  p.hash_output_h1 = 0;
  p.hash_output_h2 = 1;
  p.hash_output_h3 = 2;
  p.hash_output_h4 = 3;

  p.sketch1_idx = p.hash_output_h1 * 256 + p.hash_output_idx1;
  p.sketch2_idx = p.hash_output_h2 * 256 + p.hash_output_idx2;
  p.sketch3_idx = p.hash_output_h3 * 256 + p.hash_output_idx3;
  p.sketch4_idx = p.hash_output_h4 * 256 + p.hash_output_idx4;

  sketch_cnt[p.sketch1_idx]+= 1;
	sketch_cnt[p.sketch2_idx]+= 1;
	sketch_cnt[p.sketch3_idx]+= 1;
  sketch_cnt[p.sketch4_idx]+= 1;
}
