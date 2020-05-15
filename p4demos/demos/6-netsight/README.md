
# 6 NetSight

Paper: [NetSight](https://www.usenix.org/node/179784 "NetSight")

## Demo description
The demo executes the NetSight postcard generation.

The P4 switch is configured to 

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 6 9999
```
From another terminal, you can inject packets to the switch using any of the following command(s):
```
sudo python py/pkt-inject.py --iface veth2 -d 20 -n 10 --src_mac 00:00:00:00:00:01 --src_mac 00:00:00:00:00:03  --src_ip 10.0.0.1 --dst_ip 10.0.0.3
sudo python py/pkt-inject.py --iface veth2 -d 20 -n 10 --src_mac 00:00:00:00:00:03 --src_mac 00:00:00:00:00:01  --src_ip 10.0.0.3 --dst_ip 10.0.0.1
```

Postcards will be sent out of port 0 (iface veth0), unmodified, encapsulated with a VLAN tag with ID 0xF.
Note: the sample primitive should be able to specify VLAN forwarding.

You can sniff on this interface to see the generated samples:
```
sudo python py/sniff-iface.py --iface veth0
```
In our current API, the demo's measurement would be expressed as follows:
```
Sample("collector") >> 
(  
    Match(pkt.sample == 1) >> 
    (  
        Tag(pkt.input_port, header_field_1) + Tag(switch.id, header_field_2) + Tag(pkt.output_port, header_field_3)  
    )  
)
```

NOTE: both "switch.metadata.id" and "packet.metadata.input_port" are not available in P4. However, we can abstract away this detail and assume the runtime is aware of the network topology:

1. "switch.metadata.id": the runtime can assign automatically unique identifier for every switch in the network. 
2. "packet.metadata.input_port": the runtime knows the MAC addresses of the interfaces of every switch in the network. As such, it can generate ad-hoc rules matching the ethernet.srcAddr field of the packet and map the corresponding input port.


## P4 code details

### P4 data structures

There are no stateful registers in this demo


### P4 tables and actions
In file [netsight.p4](p4src/netsight.p4 "netsight.p4") there is the core of the demo.
There are two tables defined: "table_netsight" and "table_postcard".

1. "table_netsight" is applied to every packet. Its purpose is to initialize the metadata fields "switch_id", "input_port" and "output_port". The former two need to be confiugured as action parameters of installed rules since, as discussed, are not available in P4. The table can correctly assign the value of the input_port by reading the packet MAC source address and looking for a matching rule in the TCAM. The output port, instead, is handled automatically if we assume the the table is applied *after* the forwarding decision have been made.  The action will as well clone the packet.

2. "table_postcard": is associated with the action "do_postcard", and is called in the egress pipeline for every packet cloned. Its purpose is to encapsulate the postcard using a VLAN header and then tagging the MAC destination field of the packet with the metadata "switch_id", "input_port" and "output_port".


### P4 Control loop

```
control ingress {
    apply(ipv4_lpm);
    apply(forward);
    apply(table_netsight); // Need to be the last table applied, to allow the forwarding rule to decide the output port
}

control egress {
    apply(table_postcard){
        miss{ apply(send_frame); }
    }
}

```
