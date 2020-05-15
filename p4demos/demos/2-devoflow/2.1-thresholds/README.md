
# 2.2 DevoFlow Thresholds

Paper: [DevoFlow](http://dl.acm.org/citation.cfm?doid=2043164.2018466 "DevoFlow")

## Demo description
The demo executes DevoFlow's threshold-based notifications. The demo monitors 6 flows' packet and byte counters and defines thresholds for each of them. When a threshold get crossed, a notification is sent out a special port (eg. the CPU port) so that a notification can be sent to a controller.

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 2.2 9999
```
From another terminal, you can inject packets to the switch using any of the following command(s):
```
sudo python py/pkt-inject.py --iface veth2 -d 20 -n 10 --src_ip 10.0.0.1 --dst_ip 10.0.0.3
sudo python py/pkt-inject.py --iface veth6 -d 20 -n 10 --src_ip 10.0.0.3 --dst_ip 10.0.0.1
```

In our current API, the demo's measurement would be expressed as follows:
```
Match(pkt.ipv4.dst == 10.0.0.0/24 \&\& pkt.tcp.dst == 80) >>  
(  
    ( Counter(byte_counter + pkt.size, byte_counter) + Counter(packet_counter + 1, packet_counter) )  
    >>  
    ( ( Match(byte_counter > "threshold_bytes") >> Sample("collector") ) + ( Match(packet_counter > "threshold_packets") >> Sample("collector") ) )  
)
```

## P4 code details

### P4 data structures

In file [counters.p4](p4src/includes/counters.p4 "counters.p4") there is the definition of the two register arrays used to store the counts of packets and bytes for monitored flows. The registers are sized to hold counters for up to 8 different flows. 


### P4 tables and actions
In file [devoflow.p4](p4src/devoflow.p4 "devoflow.p4") there is the core of the demo.
There are five tables defined: "packet_counter_table", "byte_counter_table", "clone_packets", "clone_bytes" and "notification":

1. "packet_counter_table" and "byte_counter_table": are configured to exact-match flows with the source/destination IP address in 10.0.0.{1,2,3}, and are associated with the actions "do_count_packets" and "do_count_bytes", respectively. The action take as input parameter a threshold value which is stored in the packets' metadata. The actions will update the counters of packets and bytes for the flows, as well. 

2. "clone_packets" and "clone_packets": are called whenever the current counter value of packet and bytes transfered withing the current packet's flow exceed the configured threshold. If so, the associated actions "clone_packets" and "clone_bytes" will duplicate the packet to be used as notification for the controller.

3. "notification" is the table called in the egress pipeline to match notification packets to be sent to the controller. The associated action "do_notification" will encapsulate the packet with a custom header carrying an identifier as notificatoin reason and current value of the exceeded counter.

### P4 Control loop

```
control ingress {
    apply(byte_counter_table){
        hit{
            if(devoflow_metadata.byte_count > devoflow_metadata.byte_threshold){ apply(clone_bytes); }
        }
    }
    apply(packet_counter_table){
        hit{
            if(devoflow_metadata.packet_count > devoflow_metadata.packet_threshold){ apply(clone_packets); }
        }
    }
}
```
