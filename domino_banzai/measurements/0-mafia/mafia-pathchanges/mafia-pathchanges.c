
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
  int is_entry_switch;
  int is_exit_switch;

  int bf_idx1;
  int bf_idx2;
  int bf_idx3;
  int bf;
  int local_bf;

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

#define BF_ENTRIES 16
#define NUM_ENTRIES 256*4

int sketch_changes[NUM_ENTRIES] = {0};
int sketch_paths[NUM_ENTRIES] = {0};
int bf[BF_ENTRIES] = {0};

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

  if(p.is_exit_switch == 1){
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
    if(p.bf != sketch_paths[p.sketch1_idx] && p.bf != sketch_paths[p.sketch1_idx] && p.bf != sketch_paths[p.sketch1_idx] ){
         
         sketch_changes[p.sketch1_idx] += 1;
         sketch_changes[p.sketch2_idx] += 1;
         sketch_changes[p.sketch3_idx] += 1;
         sketch_changes[p.sketch4_idx] += 1;

         sketch_paths[p.sketch1_idx] = p.bf;
         sketch_paths[p.sketch2_idx] = p.bf;
         sketch_paths[p.sketch3_idx] = p.bf;
         sketch_paths[p.sketch4_idx] = p.bf;
    }
  }
  
}
