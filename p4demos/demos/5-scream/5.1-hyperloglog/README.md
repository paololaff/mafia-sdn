
# 5.1 HLL cardinality sketch

Used in paper: [SCREAM](http://dl.acm.org/citation.cfm?doid=2716281.2836099 "SCREAM")

## Demo description
The demo executes the HLL sketch algorithm to estimate the number of distinct flows passing through the switch.
This sketch has been used in the SCREAM paper.  
A useful description of the HLL sketch can be found here: [HLL Sketch](https://research.neustar.biz/2012/10/25/sketch-of-the-day-hyperloglog-cornerstone-of-a-big-data-infrastructure/ "HLL Sketch")

The current demo implementation counts the total number of distinct flows.  
The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 5.1 9999
```
From another terminal, you can issue the following command:
```
sudo python py/pkt-inject.py --iface veth2 -c 2500 -d 50 -n 1
```
The script will start to inject packets to the switch using randomized IPs/PORTs.  
You will be able to see the evolution of the HLL sketch.

In our current API, the demo's measurement would be expressed as follows:
```
Match(true) >> Sketch.update(key, U_{Fn}:{hll_sketch + key}, hll_sketch)
```

## P4 code details

### P4 HLL data structure

In file [sketch-hyperloglog.p4](p4src/includes/sketch-hyperloglog.p4 "sketch-hyperloglog.p4") there is the definition of the HLL sketch, its size, the fields of the packet header used to calculate a 32 bits packet hash (using the hash_ex P4 built-in function) and the number of bits B of the hash used to derive the index of the sketch cell to be updated.

### P4 tables and actions
In file [scream-hll.p4](p4src/scream-hll.p4 "scream-hll.p4") there is the core of the demo.  
There are three tables defined: "table_pcsa_apply", "table_hll_lookup_zeroes" and "table_hll_update".

1. "table_hll_apply" has an associated defualt action "do_hllhash", which calculates the hash string using the "hash_ex" function on the packet 5-tuple. The hash is stored in a custom packet metadata, and then manipulated to derive:
   - the B highest order bits of the hash, whose value will be used to find which entry of the sketch has to be updated.
   - the B+1 bits upon which to find the number of consecutive leading zeroes. This value will be used to update the identified entry if its value is greater than the one currently stored.
The generated metadata field at point 2) still is 32-bit long because it must be used for a TCAM match against special "IPs" whose only purpose is to count the number of leading zeroes. As such, the first B bits of the hash are masked to 0.  
Currently the action is set as default for the table, since the demo only counts the number of distinct connection.
If one would like to monitor, for example the number of distinc sources contacting a specific destination, we would need to set up the table to match against the destination IP of the packet (either exact or LPM) and configure the table accordingly. 
2. "table_hll_lookup_zeroes" is associated with an action "do_hll_save_zeroes". The table matches against the packet metadata field containing the B+1 bits of the calculated packet hash to read with the TCAM the numebr of leading zeroes in the string. To do this, the following entries needs to be configured ("match string" => #zeroes):
```
2.0.0.0/7 => 0
1.0.0.0/8 => 1
0.128.0.0/9 => 2
0.64.0.0/10 => 3
0.32.0.0/11 => 4
0.16.0.0/12 => 5
0.8.0.0/13 => 6
0.4.0.0/14 => 7
0.2.0.0/15 => 8
0.1.0.0/16 => 9
0.0.128.0/17 => 10
0.0.64.0/18 => 11
0.0.32.0/19 => 12
0.0.16.0/20 => 13
0.0.8.0/21 => 14
0.0.4.0/22 => 15
0.0.2.0/23 => 16
0.0.1.0/24 => 17
0.0.0.128/25 => 18
0.0.0.64/26 => 19
0.0.0.32/27 => 20
0.0.0.16/28 => 21
0.0.0.8/29 => 22
0.0.0.4/30 => 23
0.0.0.2/31 => 24
0.0.0.1/32 => 25
0.0.0.0/32 => 26
```
Note that the entries always exclude the first B zeroes of the hash string.
The associated action will store the number of zeroes in custom metadata, as well as read the current value stored in the HLL sketch entry.
3. "table_hll_update" is associated with the default action "do_hll_update" and is only invoked if the calculated number of leading zeroes for the current packet is greater than the value currently stored. The action updates the associated entry with the new value.


### P4 Control loop
The P4 control loop is:
```
control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_hll_apply);
            apply(table_hll_lookup_zeroes);
            if(my_metadata.hll_zeroes_new > my_metadata.hll_zeroes_old){ apply(table_hll_update); }
        }
    }
} 
```
