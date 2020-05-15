# MAFIA to P4 Compiler

This folder contains the prototype implementation of the MAFIA compiler, which generates P4-14 code suitable to run with the P4 behavioral model. 
The current implementation is written in python3. 

## Launching the compiler 

The main compiler file is [mafia-p4c.py](mafia-p4c.py "mafia-p4c.py").
The compilation process is launched by issuing the following command on the terminal:

```
python3 mafia-p4c.py
```

The measurements selected by the compilation process is defined by assigning the variable ``example'' to the desired use case. The variable is located at the top of the file, right after the python's import statements; eg: 

```
example = m01_openflow
```

All available measurements are located in the directory [measurements](measurements/ "measurements") and imported in the main file. 
Remember to add the correct import statement when you develop a new in the aforementioned folder. 
The compilation results are put in the [build](build/ "build directory") under a subfolder with the same name as the measurement been compiled. 
The output consists in a main file, also named as the measurement, a file ``headers.p4'' containing the necessary packet header definition, a file containing the required p4 match tables ``tables.p4'' and a file containing the commands to populate the respective tables ``commands.txt'', which needs to be fed as input to the simulated p4 switch at startup. The parser definition is shared between all the measurement and is located in the top build/ directory.

