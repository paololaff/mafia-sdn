
# 3.1 FleXam Stochastic Sampling

Paper: [FleXam](https://dl.acm.org/citation.cfm?doid=2491185.2491215 "FleXam")

## Demo description
The demo executes the FleXam random sampling scheme.  

The P4 switch is configured to sample packets belonging to TCP flows coming from a source IP address 192.168.0.0/16 with a destination IP address 10.0.0.{4,5,6,7,8,9}, with different probabilities depeding upon the actual destination.

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 3.1 9999
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
The probability of sampling the packet is used as the value of the VLAN ID.  
In this implementation, the "random()" function is implemented via an ad-hoc hash function implemented in C whose outcome in a value uniformly distributed in range [0:SIZE]. The accuracy of the outcome actually depends on the value of SIZE.  
The SIZE value passed as parameter is in practice the size of the fields passed into the hash function (which are not used). As such, the demo defines a "fake" metadata field of length SIZE to be passed to the C code.

Note: the sample primitive should be able to specify VLAN forwarding.

## P4 code details

### P4 data structures

The demo instantiates 3 registers used as counters: 
- "my_counter_total": tracks the total number packets seen.
- "my_counter_sample": counts the number of generated samples.
- "my_counter_no_sample": counts the number of packets not selected by the sampling rules.


### P4 tables and actions
In file [flexam.p4](p4src/include/flexam.p4 "flexam.p4") there is the core of the demo.  
There are three tables defined: "table_check_sample", "table_sample_probability" and "table_no_sample".

1. "table_check_sample" is the first table applied to every packet, and its purpose is to select flows for which a sampling rule has been configured. The associated action "do_check_sample" will store in the packet metadata the sample probability as configured from the control plane, as well as the index of the register arrays associated to the flows and the eventual destination IP address and port of the collector (not used in this demo).  
Moreover, it will generate a random value taken from an uniform distribution to be compared against the configured sample probability.

2. "table_sample": is associated with the action "do_sample", and is called whenever the generated random value is lower than the configured probability threshold. The action will clone the packet and increment the counter of the number of packets sampled so far.

3. "table_no_sample" is a non-mandatory table applied to every packet that are not selected for the sampling process. It is asssociated with the action "do_no_sample" whose purpose is to increment the counter of non-sampled packets.


An example run, sending 10000 packets for each flow configured for sampling:
```
With SIZE = 512 
   75    50    25    10     5     1     // Sample probabilities
[ 1000, 1000, 1000, 1000, 1000, 1000 ]  // Total packets
[ 1000,  790,  403,  174,   99,   24 ]  // # sample
[    0,  210,  597,  826,  901,  976 ]  // # skipped

With SIZE = 2048
[ 1000, 1000, 1000, 1000, 1000, 1000 ]
[  784,  601,  302,  119,   64,   23 ]
[  216,  399,  698,  881,  936,  977 ]

With SIZE = 4096
[ 1000, 1000, 1000, 1000, 1000, 1000 ]
[  765,  494,  292,  122,   67,   21 ]
[  235,  506,  708,  878,  933,  979 ]

With SIZE = 8192 
[ 1000, 1000, 1000, 1000, 1000, 1000 ] 
[  759,  542,  263,  133,   58,   21 ] 
[  241,  458,  737,  867,  942,  979 ] 

```

### P4 Control loop

```
control ingress {
    apply(table_check_sample){
        hit{
            if(my_sample_metadata.probability_hash_val <= my_sample_metadata.probability){ apply(table_sample); }
            else{ apply(table_no_sample); }
        }
    }
}
```
