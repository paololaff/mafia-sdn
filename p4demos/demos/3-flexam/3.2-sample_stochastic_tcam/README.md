
# 3.1 FleXam Stochastic Sampling

Paper: [FleXam](https://dl.acm.org/citation.cfm?doid=2491185.2491215 "FleXam")

## Demo description
The demo executes the FleXam random sampling scheme.  

The P4 switch is configured to sample packets belonging to TCP flows coming from a source IP address 192.168.0.0/16 with a destination IP address 10.0.0.{1,2,3,4,5,6,7,8}, with different probabilities depeding upon the actual destination.  

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 3.2 9999
```
From another terminal, you can issue the following command:
```
sudo python py/pkt-inject.py --iface veth8 -d 20 -n 1000 --src_ip 192.168.0.99 --dst_ip 10.0.0.x
```

Samples will be sent out of port 0 (iface veth0), unmodified, encapsulated with a VLAN tag whose ID is the same as the rolled probability of the packet.  

You can sniff on this interface to see the generated samples:
```
sudo python py/sniff-iface.py --iface veth0
```
In our current API, the demo's measurement would be expressed as follows:
```
Match(pkt.ipv4.src == 192.168.0.0/16 && pkt.ipv4.dst == 10.0.0.4 && random([0:100]) < 75) >> Sample("collector")
Match(pkt.ipv4.src == 192.168.0.0/16 && pkt.ipv4.dst == 10.0.0.5 && random([0:100]) < 50) >> Sample("collector")
Match(pkt.ipv4.src == 192.168.0.0/16 && pkt.ipv4.dst == 10.0.0.6 && random([0:100]) < 25) >> Sample("collector")
Match(pkt.ipv4.src == 192.168.0.0/16 && pkt.ipv4.dst == 10.0.0.7 && random([0:100]) < 10) >> Sample("collector")
Match(pkt.ipv4.src == 192.168.0.0/16 && pkt.ipv4.dst == 10.0.0.8 && random([0:100]) < 5) >> Sample("collector")
Match(pkt.ipv4.src == 192.168.0.0/16 && pkt.ipv4.dst == 10.0.0.9 && random([0:100]) < 1) >> Sample("collector")
```
The probability of sampling the packet for each flow is used as the value of the VLAN ID.
In this implementation, the "random()" function is implemented via ad-hoc ternary match rules applied to a uniform hash value generated using the P4 built-in "modify_field_rng_uniform(...)".  
The rules define power-of-two probabilities of the form (1/2)^1, (1/2)^2, (1/2)^3, ... (1/2)^N with N [1:12]  

Note: the sample primitive should be able to specify VLAN forwarding.

## P4 code details

### P4 data structures

The demo instantiates 3 registers used as counters: 
- "my_counter_total": tracks the total number packets seen.
- "my_counter_sample": counts the number of generated samples.
- "my_counter_no_sample": counts the number of packets not selected by the sampling rules.


### P4 tables and actions
In file [flexam.p4](p4src/include/flexam.p4 "flexam.p4") there is the core of the demo.  
There are four tables defined: "table_check_sample", "table_sample_probability", "table_sample" and "table_no_sample".

1. "table_check_sample" is the first table applied to every packet, and its purpose is to select flows for which a sampling rule has been configured. The associated action "do_check_sample" will store in the packet metadata the sample probability as configured from the control plane, as well as the index of the register arrays associated to the flows and the eventual destination IP address and port of the collector (not used in this demo).  
Moreover, it will generate a uniform hash to be used as input of the next table to apply the probability.

2. "table_sample_probability" is called only for flows eligible for sampling and will match the uniform hash value generated in previous action with ternary rules to derive the current probability of the packet. The associated action "do_apply_sample_probability" will store in the packet metadata the rolled probability for the packet. 
```
0x1    &&&    0x1 => 2         // Probability (1/2)^1
0x2    &&&    0x3 => 4
0x3    &&&    0x7 => 8
0x8    &&&    0xf => 16        // Probability (1/2)^4
0x10   &&&   0x1f => 32
0x20   &&&   0x3f => 64
0x40   &&&   0x7f => 128       // Probability (1/2)^7
0x80   &&&   0xff => 256
0x100  &&&  0x1ff => 512
0x200  &&&  0x3ff => 1024      // Probability (1/2)^10
0x400  &&&  0x7ff => 2048
0x800  &&&  0xfff => 4096
0x1000 &&& 0x1fff => 8192      // Probability (1/2)^13
```
The full rules configured can be inspected in the file [commands.txt](commands.txt "commands.txt")

3. "table_sample": is associated with the action "do_sample", which will clone the packet and increment the counter for the number of packets sampled so far.

4. "table_no_sample" is a non-mandatory table applied to every packet that are not selected for the sampling process. It is asssociated with the action "do_no_sample" whose purpose is to increment the counter of non-sampled packets.


An example run, sending 10000 packets for each flow configured for sampling:
```
  2^4  , 2^6 ,  2^8  , 2^9  , 2^10 ,  2^11, 2^12   // Sample probabilities 1/x
[ 10000, 10000, 10000, 10000, 10000, 10000, 10000] // Total packets
[ 1300 , 328  , 75   , 39   , 19   , 5    , 9    ] // # sample
[ 8700 , 9672 , 9925 , 9961 , 9981 , 9995 , 9991 ] // # skipped
```

### P4 Control loop

```
control ingress {
    apply(table_check_sample){
        hit{
            apply(table_sample_probability);
            if(my_sample_metadata.p >= my_sample_metadata.probability){ apply(table_sample); } // Probability check
            else{ apply(table_no_sample); }
        }
    }
}
```
