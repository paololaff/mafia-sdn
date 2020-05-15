
# 1.1 OpenFlow Statistics

## Demo description

Using our API, the demo's measurement would be expressed as follows:
```
Match(pkt.ipv4.src == 10.0.0.0/24 && pkt.ipv4.dst == 10.0.0.0/24 ) >> 
(  
    ( (Counter(byte_counter + pkt.size, byte_counter) + Counter(packet_counter + 1, packet_counter) )  
    +  
    ( Match(start_ts != 0) >> Timestamp(start_ts) ) + Counter(Timestamp() - start_ts, flow_duration) )  
)
```

## P4 code details

### P4 data structures

In file [counters.p4](p4src/includes/counters.p4 "counters.p4") there is the definition of the two register arrays used to store the counts of packets and bytes for monitored flows, as well as two registers to save the timestamp of the first packet seen and the last one and a register to keep the flow duration.

### P4 tables and actions
In file [of.p4](p4src/of.p4 "of.p4") there is the core of the demo.
There are two tables defined: "counter_table" and "duration_table":

1. "counter_table" is associated with the action "do_count" and will retrieve the previous counters (packets and bytes) values and update them accordingly.
2. "duration_table" is associated with the action "update_duration" and will take care to both update the flow start timestamp (if the current is the first packet seen) and update the flow duration value on every packet been handled.

### P4 Control loop
```
control ingress { 
    apply(counter_table);
    apply(duration_table);
}
```
