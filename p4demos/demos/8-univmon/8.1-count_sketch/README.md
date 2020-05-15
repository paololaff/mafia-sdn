
# 8.1 UnivMon Count Sketch

Paper: [UnivMon](https://dl.acm.org/citation.cfm?doid=2934872.2934906 "UnivMon")

## Demo description
The demo implements UnivMon's Count sketch.  
The P4 switch is configured to monitor the aggregate 10.0.0.0/24

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 8.1 9999
```
From another terminal, you can inject packets to the switch using any of the following command(s):
```
sudo python py/pkt-inject.py --iface veth2 -d 20 -n 10 --src_ip 10.0.0.x --dst_ip 10.0.0.x
```

In our current API, the demo's measurement would be expressed as follows:
```
Match(pkt.ipv4.src == 10.0.0.24) >> Sketch.update(key, U_{Fn}:{count_sketch + ( 1*hash_{-1:1}(key) )}, count_sketch)
```

## P4 code details

### P4 data structures

In file [sketch-count.p4](p4src/include/sketch-count.p4 "sketch-count.p4") there is the definition of the Count sketch, its size (4x8), and 8 hash functions. Four of these (h*_x_hash) are used to calculate, for each row of the sketch, the index of the cells where the current packet falls into, using murmur3 hashing on the packet 5-tuple. The other four hash functions (g*_x_hash) are instead binary hash functions wich map the current packet into the space {-1,1} and their result is used to multiple the packet's value for each sketch cell to be update; these hash functions operate on a 64-bit key as well dereived from the packet's 5 tuple (due to how the C hash functions in [simple_switch.cpp](../../../../bmv2/targets/simple_switch/simple_switch.cpp "simple_switch.cpp") are defined).


### P4 tables and actions
In file [univmon.p4](p4src/univmon.p4 "univmon.p4") there is the core of the demo.
There are five tables defined: "table_countsketch_hashes" and "table_countsketch_update_{1,2,3,4}":

1. "table_countsketch_hashes": is configured to match flows with source IP address in 10.0.0.0/24, and is associated with the action "do_countsketch_hashes". The action will first compute a 64-bit hash from the packet five tuple and, for each hash function defined (i=4), will calculate both the cell index to be updated and the corresponding multiplication factor g_x: {-1,1}. 

2. "table_countsketch_update_*": serve the only purpose to perfor a TCAM lookup against the current outcome of the g*_x_hash functions to distinguish which operations need to be performed on the sketch cells (increment vs decrement). Each of these tables is associated with two possible actions which will opprtunely update the sketch.

### P4 Control loop

```
control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_countsketch_hashes){
                hit{
                    apply(table_countsketch_update_1);
                    apply(table_countsketch_update_2);
                    apply(table_countsketch_update_3);
                    apply(table_countsketch_update_4);
                }
            }
        }
    }
}
```
