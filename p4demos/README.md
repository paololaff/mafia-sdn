# Software Defined Primitives in P4


## P4 installation
See guide here https://github.com/p4lang/tutorials

## Modification of p4 bmv2
Recompile bmv2 after replacing the "bmv2/targets/simple_switch/simple_switch.cpp" file of default P4 bmv2 implementation with this file [simple_switch.cpp](bmv2/targets/simple_switch/simple_switch.cpp "simple_switch.cpp").
The new version define 20 additional hash functions based on murmur hashing.
The provided file has been shamelessly copied from [LossRadar](https://github.com/liyuliang001/LossRadar-P4/tree/master/simple_switch_target "LossRadar implementation repository") implementation

If you are interested in running the demos with the P4 debugger attached, you also should replace the default debugger script "bmv2/tools/p4dbg.py" with this version [p4dbg.py](bmv2/tools/p4dbg.py "p4dbg.py"), to support loading a file with pre-established debug commands during startup (breakpoints, watchs).  
Each demo has custom file "p4dbg-cmd.txt" located in its directory, containing a set of useful breakpoints for the demo. To enable automatic loading of this file, you have to set the DEBUG variable to 1 in the script [sdm-launcher.sh](sdm-launcher.sh "sdm-launcher") (located at the very top of the file).

## Launching a demo
You can launch a demo using the following command:
```
sudo ./sdm-launcher.sh demo-id port
```
where demo-id is any of the x.y of the following list:
```
1.1 - OpenFlow statistics (Counters, Timestamps)
1.2 - OpenFlow TCP flow start/end detection (Samples, Tags)
2.1 - DevoFlow counters with threshold-based notification (Counters, Samples, Tags)
2.2 - DevoFlow aggregate monitoring with CountMin (Sketch)
3.1 - Flexam stochastic sampling with RNG in C (Samples)
3.2 - Flexam stochastic sampling with TCAM-based power-of-two probabilities (Samples)
3.3 - Flexam deterministic sampling (Counters, Samples)
4.1 - OpenSketch flow cardinality with PCSA (Sketch)
4.2 - OpenSketch Superspreader detection with CountMin + bitmap (Sketch)
5.1 - SCREAM flow cardinality with HyperLogLog (Sketch)
6   - NetSight (Samples, Tags)
7   - VeriDP (Bloom Filter, Tags, Samples)
8.1 - UnivMon Count Sketch (Sketch)
```
The script will make two terminals pop-up:

 1. P4 switch terminal: shows the set up of the switch and submits the commands.txt for the selected demo.
 2. Demo terminal: shows the status of P4 registers associated with the demo.
 3. A debugger terminal if you set the variable DEBUG at the top of the script [sdm-launcher.sh](sdm-launcher.sh "sdm-launcher") to 1 (DEBUG=1)