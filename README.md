# MAFIA: Measurements As FIrst-class Artifacts

## Paper

OverLeaf MAFIA InfoCom 2019 Paper: [MAFIA](https://www.overleaf.com/11021339hznvyrqfkpzw#/41508904/ "MAFIA") 
OverLeaf MAFIA SOSR 2018 Paper: [MAFIA](https://www.overleaf.com/11021339hznvyrqfkpzw#/41508904/ "MAFIA") (Rejected)
<!-- OverLeaf Software-defined Measurement Primitives: [SDM-Primitives](https://www.overleaf.com/8361283nxtctdnhfcqz#/38280255/ "SDM-Primitives") (old document)   -->

## Repository structure  

### MAFIA to P4 Compiler: [mafia_p4c](mafia_p4c/ "mafia-p4c")  

### P4 Manual Use-cases Implementation: [p4demos](p4demos/ "p4demos")  

### Domino implementation of the measurement: [domino_banzai](domino_banzai/ "domino_banzai")  

### Modification of the standard P4 Behavioral Model: [p4bm](bmv2/ "bm_mod") 

Some feature of the standard P4 Behavioral Model has been modified from the original source code available on the official P4 repository. 
Make sure you update the simple_switch target with the provided files (Makefile, prng.cpp, prng.h and simple_switch.cpp) and recompile the behavioral model. 
