
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

  int min_sketch;

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

  int bf_idx1;
  int bf_idx2;
  int bf_idx3;

  int flow_index;
};

#define THRESHOLD 50
#define BF_ENTRIES 16
#define NUM_ENTRIES 256
#define COUNTER_ENTRIES 512

int total_counter = 0;
int exact_counter[COUNTER_ENTRIES] = {0};
int sketch_countmin[NUM_ENTRIES] = {0};
int bf[BF_ENTRIES] = {0};

void func(struct Packet p) {

  if(p.output_port == 0){

    total_counter += 1;
  
    p.bf_idx1 = hash3(p.input_port, p.switch_id, p.output_port) % BF_ENTRIES;
    p.bf_idx2 = hash3(p.input_port, p.switch_id, p.output_port) % BF_ENTRIES;
    p.bf_idx3 = hash3(p.input_port, p.switch_id, p.output_port) % BF_ENTRIES;

    if(bf[p.bf_idx1] == 0 || bf[p.bf_idx2] == 0 || bf[p.bf_idx3] == 0){

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


      sketch_countmin[p.sketch1_idx]+= 1;
      sketch_countmin[p.sketch2_idx]+= 1;
      sketch_countmin[p.sketch3_idx]+= 1;
      sketch_countmin[p.sketch4_idx]+= 1;

      if(sketch_countmin[p.sketch1_idx] < sketch_countmin[p.sketch2_idx] && 
        sketch_countmin[p.sketch1_idx] < sketch_countmin[p.sketch3_idx] &&
        sketch_countmin[p.sketch1_idx] < sketch_countmin[p.sketch4_idx]){
        p.min_sketch = sketch_countmin[p.sketch1_idx];
      }
      if(sketch_countmin[p.sketch2_idx] < sketch_countmin[p.sketch1_idx] && 
        sketch_countmin[p.sketch2_idx] < sketch_countmin[p.sketch3_idx] &&
        sketch_countmin[p.sketch2_idx] < sketch_countmin[p.sketch4_idx]){
        p.min_sketch = sketch_countmin[p.sketch2_idx];
      }
      if(sketch_countmin[p.sketch3_idx] < sketch_countmin[p.sketch1_idx] && 
        sketch_countmin[p.sketch3_idx] < sketch_countmin[p.sketch2_idx] && 
        sketch_countmin[p.sketch3_idx] < sketch_countmin[p.sketch4_idx]){
        p.min_sketch = sketch_countmin[p.sketch3_idx];
      }
      if(sketch_countmin[p.sketch4_idx] < sketch_countmin[p.sketch1_idx] && 
        sketch_countmin[p.sketch4_idx] < sketch_countmin[p.sketch2_idx] && 
        sketch_countmin[p.sketch4_idx] < sketch_countmin[p.sketch3_idx]){
          p.min_sketch = sketch_countmin[p.sketch4_idx];
      }

      if(p.min_sketch / total_counter > THRESHOLD){        
        bf[p.bf_idx1] = 1;
        bf[p.bf_idx2] = 1;
        bf[p.bf_idx3] = 1;
      }
    }
    else{
      p.flow_index = hash5(p.ipv4_src, p.ipv4_dst, p.tcp_src, p.tcp_dst, p.ipv4_proto) % COUNTER_ENTRIES;
      exact_counter[p.flow_index] += 1;
    }

  }
}
