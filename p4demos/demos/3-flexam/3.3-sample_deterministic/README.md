
# 3.3 FleXam Deterministic Sampling

Paper: [FleXam](https://dl.acm.org/citation.cfm?doid=2491185.2491215 "FleXam")

## Demo description
The demo executes the FleXam deterministic sampling scheme.  

The P4 switch is configured to sample packets belonging to TCP flows coming from a source IP address 192.168.0.0/16 with a destination IP address 10.0.0.{1,2,3}, using different N,M and DELTA parameters.

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 3.3 9999
```
From another terminal, you can issue the following command:
```
sudo python py/pkt-inject.py --iface veth8 -c 1 -d 20 -n 1000 --src_ip 192.168.0.99 --dst_ip 10.0.0.x
```

Samples will be sent out of port 0 (iface veth0), to a collector with IP destination address 255.255.255.255 on port 65535.  

You can sniff on this interface to see the generated samples:
```
sudo python py/sniff-iface.py --iface veth0
```

The demo will overwrite the destination IP:port with that of the configured collector.  
Samples carry a custom header field "sample_header" appended after the TCP header with the following fields:
```
header_type sample_t {
    fields {
        id          : 16; // ie: this is the Nth sample.  (M - id) still to be forwarded. 
        n           : 16;
        m           : 16;
        delta       : 16;
    }
}
```

Note that this implies assuming that all switches can interpret the sample packets.  
Alternatively, we can assume that the sample packet is actually sent to the switch's CPU for encapsulation.  

In our current API, the demo's measurement would be expressed as follows:
```
Match(pkt.ipv4.src == 10.0.0.0/24 pkt.ipv4.dst == 10.0.0.0/24 ) >> 
(  
    Counter(n + 1, n)  
    +  
    ( ( Match(delta < delta_config) >> Counter(delta + 1, delta) )  
        +  
      ( Match(delta >= delta_config && m < m_config) >> Sample(collector) )  
        +  
      ( Match(n >= n_config) >> ( Counter(0, n) + Counter(0, m)+ Counter(0, delta) ) )  
    )
)  
>>  
Match( pkt.metadata.sample == 1 ) >>  
    ( Tag(pkt.sample_header.id, "id") + Tag(kt.sample_header.n, "n") + Tag(pkt.sample_header.m, "m") + Tag(pkt.sample_header.delta, "delta") )
```

## P4 code details

### P4 data structures

The demo instantiates 3 arrays whose entries are associated to each flow configured to be sampled:
1. "sampling_state_n": tracks the how many packets have been seen so far
2. "sampling_state_m": tracks the how many packets have been sampled
3. "sampling_state_delta": tracks the how many packets have been skipped

### P4 tables and actions
In file [flexam.p4](p4src/include/flexam.p4 "flexam.p4") there is the core of the demo.  
There are five tables defined: "table_get_sampling_state", "table_sample_take", "table_sample_skip", "table_sample_reset" and "table_sample".

1. "table_get_sampling_state" is the first table applied to every packet, and its purpose is to select flows for which a sampling rule has been configured. The associated action "do_get_sampling_state" saves the N, M and DELTA parameter of the sampling action and retrieves the local "n", "m" and "delta" state for the flow, storing everything in the packet metadata. As well, the action will increment the current value of the number "n" of packets seen so far.

2. "table_sample_take": will be called subsequently if the current packet falls into the [DELTA : DELTA+N-M] interval depending upon the current values for the flow. The associated action "do_update_sample_taken" will increment the current value of "m" for the flow.

3. "table_sample_skip": will be called subsequently if the current packet falls into the [0 : DELTA]. Its "do_update_sample_skipped" will increment the current number of packets "delta" skipped so far.

4. "table_sample_reset": will reset the state of the local "n", "m" and "delta" state for the flow whenever the (N+1)th parameter is reached.

5. "table_sample": is called only on hit of "table_sample_take" and will clone the packet to be prepared for sample.

### P4 Control loop

```
control ingress {
    apply(table_get_sampling_state){
    hit{
            if( my_sample_metadata.delta < my_sample_metadata.delta_config ){ // Skip DELTA
                        apply(table_sample_skip);
            } 
            else if(my_sample_metadata.m < my_sample_metadata.m_config){ // Sample M packets     
                    apply(table_sample_take); 
                    apply(table_sample);
            } 
            else if(my_sample_metadata.n == my_sample_metadata.n_config + 1){ // Reset N,M and DELTA
                    apply(table_sample_reset);
            } 
        }
    }
}
```
