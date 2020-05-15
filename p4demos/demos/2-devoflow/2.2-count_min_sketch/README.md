
# 2.2 DevoFlow CountMin Sketch

Paper: [DevoFlow](http://dl.acm.org/citation.cfm?doid=2043164.2018466 "DevoFlow")

## Demo description
The demo executes DevoFlow's aggregate monitoring using a CountMin sketch.  
The P4 switch is configured to monitor the aggregate 10.0.0.0/24

The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 2.2 9999
```
From another terminal, you can inject packets to the switch using any of the following command(s):
```
sudo python py/pkt-inject.py --iface veth2 -d 20 -n 10 --src_mac 00:00:00:00:00:01 --dst_mac 00:00:00:00:00:03  --src_ip 10.0.0.1 --dst_ip 10.0.0.3
sudo python py/pkt-inject.py --iface veth6 -d 20 -n 10 --src_mac 00:00:00:00:00:03 --dst_mac 00:00:00:00:00:01  --src_ip 10.0.0.3 --dst_ip 10.0.0.1
```

In our current API, the demo's measurement would be expressed as follows:
```
Match(pkt.ipv4.dst == 10.0.0.0/24) >> Sketch.update(key, U_{Fn}:{countmin_sketch + 1}, countmin_sketch)
```

## P4 code details

### P4 data structures

In file [sketch-countmin.p4](p4src/includes/sketch-countmin.p4 "sketch-countmin.p4") there is the definition of the CountMin sketch, its size (4x16), the fields of the packet header used to calculate a 32 bits packet hash (using the hash_ex P4 built-in function) and the 4 hash function (using murmur3 hashing)


### P4 tables and actions
In file [devoflow.p4](p4src/devoflow.p4 "devoflow.p4") there is the core of the demo.
There is one table defined: "table_countmin_sketch":

1. "table_countmin_sketch": is configured to match flows with destination IP address in 10.0.0.0/24, and is associated with the action "do_count_min_sketch". The action will compute, for each hash function defined (i=4), an index that identifies the cell to be updated. 


### P4 Control loop

```
control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){ // We apply the sketch only on TCP flows in this demo
            apply(sketch_table);
        }
    }
}
```
