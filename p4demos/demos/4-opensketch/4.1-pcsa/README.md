
# 4.1 PCSA cardinality sketch

Used in paper: [OpenSketch](https://www.usenix.org/conference/nsdi13/technical-sessions/presentation/yu "OpenSketch")

## Demo description
The demo executes the PCSA sketch algorithm to estimate the number of distinct flows passing through the switch.  
This sketch has been used in the OpenSketch paper to count the numebr of distinct source IPs contacting a given destination.  
A useful description of the PCSA sketch can be found here: [PCSA Sketch](https://research.neustar.biz/2013/04/02/sketch-of-the-day-probabilistic-counting-with-stochastic-averaging-pcsa/ "PCSA Sketch")  
  
The current demo implementation counts the total number of distinct flows.  
The demo can be launched using the following command:  
```
sudo ./sdm-launcher.sh 4.1 9999
```
From another terminal, you can issue the following command:
```
sudo python py/pkt-inject.py --iface veth2 -c 2500 -d 50 -n 1
```
The script will start to inject packets to the switch using ramoized IPs/PORTs.
You will be able to see the evolution of the PCSA sketch.

In our current API, the demo would be expressed as follows:
```
Match(true) >> Sketch.update(key, U_{Fn}:{1}, pcsa_sketch)
```

## P4 code details

### P4 PCSA data structure

In file [sketch-pcsa.p4](p4src/includes/sketch-pcsa.p4 "sketch-pcsa.p4") there is the definition of the PCSA bitmap sketch, it sizes (eg, the number of bitmap rows, and their width), the field of the packet header used to calculate a 32 bits packet hash (using the hash_ex P4 built-in function) and the number of bits B of the hash used to derive the index of the bitmap array (the row of the sketch) to be updated.

### P4 tables and actions
In file [opensketch-pcsa.p4](p4src/opensketch-pcsa.p4 "opensketch-pcsa.p4") there is the core of the demo.
There are two tables defined: "table_pcsa_apply" and "table_pcsa_update".

1. "table_pcsa_apply" has an associated defualt action "do_pcsa_hash()", which calculates the hash string using the "hash_ex" function on the packet 5-tuple. The hash is stored in a custom packet metadata, and then manipulated to derive:
   - the B highest order bits of the hash, whose value will be used to find which bitmap has to be updated (ie: the row of the sketch)
   - the (HASH_LEN - B) remaining bits of the hash upon which to find the number of consecutive leading zeroes. This value will be used to find which index of the selected bitmap needs to set to 1.
The generated metadata field at point 2) is still declared 32-bit long because it must be used for a TCAM match against special "IPs" whose only purpose is to count the number of leading zeroes. The first B bits of the hash are thus masked to 0 and result stored in the packet metadata.  
Currently the action is set as default for the table, since the demo only counts the number of distinct connection.
If one would like to monitor, for example the number of distinc sources contacting a specific destination, we would need to set up the table to match against the destination IP of the packet (either exact or LPM) and configure the table accordingly. 
2. "table_pcsa_update" table matches against the packet metadata field calculated at step 2) in the previous table's action and reads with the TCAM the number of leading zeroes in the string. To do this, the following table entries needs to be configured (Note that the entries' associated counts always exclude the first B zeroes of the hash string...):
```
 8.0.0.0/5 => 0
 4.0.0.0/6 => 1
 2.0.0.0/7 => 2
 1.0.0.0/8 => 3
 0.128.0.0/9 => 4
 0.64.0.0/10 => 5
 0.32.0.0/11 => 6
 0.16.0.0/12 => 7
 0.8.0.0/13 => 8
 0.4.0.0/14 => 9
 0.2.0.0/15 => 10
 0.1.0.0/16 => 11
 0.0.128.0/17 => 12
 0.0.64.0/18 => 13
 0.0.32.0/19 => 14
 0.0.16.0/20 => 15
 0.0.8.0/21 => 16
 0.0.4.0/22 => 17
 0.0.2.0/23 => 18
 0.0.1.0/24 => 19
 0.0.0.128/25 => 20
 0.0.0.64/26 => 21
 0.0.0.32/27 => 22
 0.0.0.16/28 => 23
 0.0.0.8/29 => 24
 0.0.0.4/30 => 25
 0.0.0.2/31 => 26
 0.0.0.1/32 => 27
 0.0.0.0/32 => 28
```
Where the entries indicate runs of increasing numebr of zeroes, represented as IP CIDR blocks.  
The read value from the TCAM is then passed as parameter to the table's action "do_pcsa_sketch(zeroes_run)", which will update the PCSA sketch register at the appropriate indexes identified.  


### P4 Control loop
The P4 control loop is:
```
control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_pcsa_apply);
            apply(table_pcsa_update);
        }
    }
}
```

In case the PCSA has to be applied to some subset of flows, we need:
```
control ingress {
    if(valid(ipv4)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_pcsa_apply){
                    hit{
                            apply(table_pcsa_update);
                    }
            }
            apply(table_pcsa_update);
        }
    }
}
```
