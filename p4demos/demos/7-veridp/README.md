
# 7 VeriDP

Paper: [VeriDP](https://dl.acm.org/citation.cfm?doid=2999572.2999605 "VeriDP")

## Demo description
The demo executes the VeriDP routing policy verification.  
Currently the demo only assumes the existance of a single switch which performs all the operations done by VeriDP: sampling packets, Bloom Filter tag update and report generation. To execute the demo on multiple switches, the commands.txt file used to configure the P4 switch needs to be modified accordingly to the network topology.
 

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 7 99999
```
From another terminal, you can inject packets to the switch using any of the following command(s):
```
sudo python py/pkt-inject.py --iface veth2 -d 20 -n 1 --src_mac 00:00:00:00:00:01 --src_mac 00:00:00:00:00:03  --src_ip 10.0.0.1 --dst_ip 10.0.0.3
```

Tag reports will be sent out of port 0 (iface veth0), encapsulated with a VLAN tag with ID 0xF.
The reports consist of a duplicated copy of the packet, with the addition of a custom header carrying the Bloom Filter tag and the identifier of the network ingress/egress points of the packet into the network (the switch itself in this setting).  

You can sniff on the interface to see the generated report:
```
sudo python py/sniff-iface.py --iface veth0
```
In our current API, the demo's measurement would be expressed as follows:
```
(
    Match(is_first_hop(pkt)) >>  
    (  
        Counter(Timestamp() - sample_time, "sample_interval") >>  
        (  
            Match(sample_interval > "threshold") >> ( Timestamp(sample_time) + Tag(pkt.ipv4.tos | 0x1, pkt.ipv4.tos) + Tag(switch.id, pkt.header_field_1) + Tag(pkt.input_port, pkt.header_field_2) )  
        )  
    )  
)  
+  
( Match(pkt.ipv4.tos & 0x1 == 1) >> BloomFilter.update(1, bf) >> Tag(pkt.bf_tag | bf, pkt.bf_tag) )  
+  
( Match(is_last_hop(pkt)) >> ( Tag(switch.id, pkt.header_field_3) + Tag(pkt.output_port, pkt.header_field_4) ) )
```
where the conditions "is_first_hop(pkt)" and "is_last_hop(pkt)" are special purpose query which return whether the current switch is either the first or last hop of the packet's route. The conditions can be automatically crafter given knowledge of the routing policy of flows.  

NOTE: both "switch.metadata.id" and "packet.metadata.input_port" are not available in P4. However, we can abstract away this detail and assume the runtime is aware of the network topology:

1. "switch.metadata.id": the runtime can assign automatically unique identifier for every switch in the network. 
2. "packet.metadata.input_port": the runtime knows the MAC addresses of the interfaces of every switch in the network. As such, it can generate ad-hoc rules matching the ethernet.srcAddr field of the packet and map the corresponding input port.


## P4 code details

### P4 data structures

The only stateful register maintained in this demo is dedicated to track the sampling interval with which VeriDP decides if a packet needs to go through the path verification process. This memory is maintained only by the network ingress points and are not necessary in other switches along a path.  
The control plane needs to configure entry for a dedicated table in order to assign register cells to specific flows. However, to reduce TCAM usage, we could as well maintain a more compact Count-min sketch storing timestamps.  


### P4 tables and actions
In file [veridp.p4](p4src/veridp.p4 "veridp.p4") there is the core of the demo.
There are multiple tables defined:

1. "table_veridp_load_switch_id" is associate with the action "do_load_switch_id" and its purpose is to set-up metadata representing the switch identifier. It needs to be set up with a single entry at every switch so to assign a unique identifier.

2. "table_veridp_in_out_port" is associate with the action "do_load_in_out_port" and is necessary to set up per-packet metadata indicating the input port where packet was received and the assigned output port, subject to the routing policy for the packet. While the latter can be carried out automatically if the table is applied after any routing decision has been made, the former needs specific entries in the table matching the source MAC address of the packet, so to pass the correct input port identifier to the associated action.

3. "table_veridp_calculate_bf_indexes": calls the default action "do_calculate_bf_indexes", which applies the configured murmur hash function over the tuple {input_port, switch_id, output_port} of the packet to determine a 32-bit hash.  The lower and upper 16 bit of this hash are then splitted to derive three additional integer values, whose lower 4 bits will determine the indexes of the Bloom Filter to be set. Citing from VeriDP original paper: "First, three hashes are constructed as gi(x) = h1(x)+ih2(x) for i = 0; 1; 2, where h1(x) and h2(x) are the two halves of a 32-bit Murmur3 hash of x. Then, we use the first 4 bits of gi(x) to set the 16-bit Bloom filter for i = 0, 1, 2."

4. "table_veridp_update_bf_{0,1,2}" are three tables which will determine the actual locations of the Bloom Filter to be updated. The switch-level Bloom Filter is then OR'ed with the value already carried in the packet.

5. "table_veridp_switch_net_entry", "table_veridp_sample_interval" and "table_veridp_select" are tables only needed by entry switches of the network and will take care to determine if the current packet will be selected for verification. The selection process is time-based. In this demo, a default value of 100ms is used.

6. "table_veridp_switch_net_exit", "table_veridp_clone" and "table_veridp_report": are tables needed only by exit switches and their purpose is to generate a copy of the packet that will be used as "report" for the controller.

### P4 Control loop

```
control ingress {
    ... // Forwarding decision tables

    // Load the switch id
    apply( table_veridp_load_switch_id );
    apply( table_veridp_in_out_port    ); // Load the input/output ports of the packet
    
    apply(table_veridp_switch_net_entry){
        hit{    // Only done by the packet first hop
            if( not valid(veridp_h) ){ 
                apply( table_veridp_sample_interval ){
                    hit{
                        if( veridp_metadata.ts > VERIDP_SAMPLE_INTERVAL ) { apply( table_veridp_select );}
                    }
                }        
            }
        }
    }    
    
    if( (veridp_metadata.marker == 1) and valid(veridp_h)){ // All switches: update VeriDP Bloom Filter Tag
        apply( table_veridp_calculate_bf_indexes );
        apply( table_veridp_update_bf_0 );
        apply( table_veridp_update_bf_1 );
        apply( table_veridp_update_bf_2 );
    }

    apply(table_veridp_switch_net_exit){
        hit{
            apply(table_veridp_clone);
        }
    }
}

```
