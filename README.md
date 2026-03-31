# Overview

This repository contains the design and simulation files for an analog comparator circuit implemented in CMOS. 
It includes SPICE simulations (OrCAD and LTSpice), device models sourced from Razavi's textbook, and a physical layout created in MAGIC. 
This project is intended to be a step into the world of analog design - by no means a comprehensive and exhaustive study of the art. 
We wish we had a repo like this to reference when we were doing our design. You'll find a more detailed, and self-critical, report that explains our design decisions from a theoretical standpoint.
We hope this repo helps you learn as much as doing this project helped us learn.
Also, credit goes to my lab partner Abdullah Abdullah for absolutely doing a killer job in floorplanning and layout analysis. He introduced Hasting's "Art of Analog Layout" book to me, and taught me a lot about the nuances of analog layout. 
Let's work together again, buddy. 

# Simulation

You'll find SPICE simulations for both OrCAD and LTSpice software. We had to use OrCAD for our lab simulations, but the LTSpice simulations are nearly identical.
Simply clone the repo and run the simulation in the software of your choice.
NOTE: if you wish to change the characteristic of the transistors, consider changing the cmos_models.lib text. In LTSpice, the device model is linked to the library using
```
lib cmos_models.lib
```
In OrCAD, however, you'll notice the device model is manually "copied in" to the device parameters section by right-clicking on the device and selecting Edit Part. In OrCAD,
the "default" footprint is taken from the PSPICE Part -> Discrete -> NMOS (Mbreak_N) device, and then edited to suit our requirements.
The device model is taken from Table 2.1 of Razavi's "Design for Analog CMOS Integrated Circuits", 2nd edition. 


# EDA

EDA was done using MAGIC. This runs best on a Linux machine, but can be run from MacOS or a Linux VM on Windows as well. 
Instructions on installing MAGIC and using it: [MAGIC Installation and Tutorial](http://opencircuitdesign.com/magic/tutorials/tut1.html)

# Contributions 

Please feel free to fork + open PR's to contribute. When we have time we'll review it. We're currently working on designing the circuit for a 180nm node process next, so keep an eye out!
