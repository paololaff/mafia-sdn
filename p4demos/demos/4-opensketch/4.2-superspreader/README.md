
# 4.2 SuperSpreader detection with CountMin sketch + bitmap

Paper: [OpenSketch](https://www.usenix.org/conference/nsdi13/technical-sessions/presentation/yu "OpenSketch")

## Demo description
The demo performs Superspreader detection using a CountMin sketch combined with bitmaps.
This technique has been used in the OpenSketch paper to count the numebr of distinct destinations contacted by the same source IP address.  
  
The demo can be launched using the following command:
```
sudo ./sdm-launcher.sh 4.2 9999
```
From another terminal, you can issue the following command:
```
sudo python py/pkt-inject.py --iface veth2 -c 2500 -d 25 -n 1 --src_ip 99.99.99.99
```
The script will start to inject packets using randomized dstination IPs/PORTs.  

In our current API, the demo would be expressed as follows:
```

```

## P4 code details

### P4 PCSA data structure

In file [sketch-ssd.p4](p4src/include/sketch-ssd.p4 "sketch-ssd.p4") there is the definition of the CountMin sketch, whose cells are actually bitmaps.


### P4 tables and actions
In file [opensketch-ssd.p4](p4src/include/opensketch-ssd.p4 "opensketch-ssd.p4") there is the core of the demo.
There is one table defined: "table_ssd".

1. "table_ssd" has an associated defualt action "do_ssd_sketch()".



### P4 Control loop
The P4 control loop is:
'''
apply(table_ssd);
'''

