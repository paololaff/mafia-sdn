
// #include "hashes.h"
// Relative path from where the domino compiler is located
#include "../domino-compiler/examples/hashes.h"

#define low_th 100
#define hi_th  1000

struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;
  int ipv4_id;

  int marked;

  int sketch1_idx;
  int sketch2_idx;
  int sketch3_idx;
  int sketch4_idx;

  int is_entry_switch;
  int is_exit_switch;

  int q_length;
};

#define NUM_ENTRIES 256

int sketch_cnt_1[NUM_ENTRIES] = {0};
int sketch_cnt_2[NUM_ENTRIES] = {0};
int sketch_cnt_3[NUM_ENTRIES] = {0};
int sketch_cnt_4[NUM_ENTRIES] = {0};


void func(struct Packet p) {
  if(p.is_entry_switch == 1){
    p.marked = p.marked | 1;
    p.ipv4_id = p.q_length;
  }

  if(p.is_entry_switch == 0 && p.marked == 1){
    p.ipv4_id = p.ipv4_id + p.q_length;
  }

  if(p.is_exit_switch == 1){
    p.sketch1_idx = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
    p.sketch2_idx = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
    p.sketch3_idx = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;
    p.sketch4_idx = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % NUM_ENTRIES;

    sketch_cnt_1[p.sketch1_idx]+= 1;
    sketch_cnt_2[p.sketch2_idx]+= 1;
    sketch_cnt_3[p.sketch3_idx]+= 1;
    sketch_cnt_4[p.sketch4_idx]+= 1;
  }
}
