# Li-ion Battery Electrical Modeling

### Simulation background

The purpose of this project was to model the electrical behavior of the battery that our team uses (Aristotle University Racing Team Electric - ARISTURTLE). Modeling of the battery requires the calculation of the state of charge of the cells and the knowlegde of the cells' voltages for various currents amplitudes. In parallel, during this process, we took into consideration the variations in the cell capacitance, energy and internal resistance.

For the modeling of the battery, we used the equivalent electrical circuit that is shown below.

![photo](Screenshots/Screenshot_1.png)

The capacitor C_batt indicates the capacitance that is saved in the cell and the dependant current source indicates the amplitude of the current that charges or discharges the battery. Thus, the left circuit simulates the state of charge (SOC) of the battery, which changes dynamically and depends on the values of the parameters of the right circuit.

The right circuit consists of dependant voltage source which depends on the SOC and indicates the open-circuit voltage of the circuit. Then, there is a resistor in series R_series which indicates the internal resistance of the cell and there are some parallel RC branches that simulate the transient behavior of the cell, which happens due to the pollarization inside the cell.

Those parameters depend on the SOC, the temperature and possibly by the charge/discharge current.

The accuracy of the modeling depends a lot by the number of parallel RC branches that we use. It has been proof that for the simulation of the transient response of the cell, it is needed at least, 3+3 RC branches (3 charge transfer polarization and 3 diffusion polarization). The more RC branches we use, the more complex and computational-intence becomes the modeling process.

The program we used for the simulation of the battery cells was Matlab/Simulink of Mathworks. Below, you can see the models we 2 RC branches. The inpouts of the model are the current (if positive, it means discharging and if negative, it means charging) and the initial capacitance of the cell. The outputs are the voltage of the cell, the providing energy and the SOC of the cell.

![photo](Screenshots/Screenshot_2.png)

Following, it is presented the calculations of the model.

![photo](Screenshots/Screenshot_3.png)
![photo](Screenshots/Screenshot_4.png)
![photo](Screenshots/Screenshot_5.png)
![photo](Screenshots/Screenshot_6.png)

In order to find the parameters of the equivalent electrical circuit in LUT form, we used an algorithm from the libraries of MathWorks, called "Example_DischargePulseEstimation" (Matlab->toolbox->autoblks->autodemos). This algorithm takes as inputs data of cell discharge experimetns and by using curve fitting methods and calculates the open-circuit voltage, series resistance and RC branches with respect to the SOC. Those values are, then, assigned in the block Estimation equivalent circuit and Equivalent circuit battery library of MathWorks.

![photo](Screenshots/Screenshot_7.png)
![photo](Screenshots/Screenshot_8.png)
![photo](Screenshots/Screenshot_9.png)
![photo](Screenshots/Screenshot_10.png)

### Experiments

For the first experiments we used cylindrical Li-ion cells (18650). The purpose was to check the function of the experimental topology. Below, it is shown the experimental circuits that we used in order to simulate the cell load and read the voltage values and store them.

![photo](Screenshots/Screenshot_11.png)

Below, we present the results

![photo](Screenshots/Screenshot_13.png)


Then we used some old battery cells (pouch cells) that our team used in our electric vehicle

![photo](Screenshots/Screenshot_12.png)

Below, we present the results

![photo](Screenshots/Screenshot_14.png)

### Modeling

Below, it is presented the simulation voltages in comparison with the real voltages of a battery cell.

![photo](Screenshots/Screenshot_15.png)
![photo](Screenshots/Screenshot_16.png)

Also, below it is presented the simulation voltages in comparison with the real voltages of a battery cell but now in a more real scenario. Here, the current of the battery cell is the current profile of an Endurance Event (22km track) of the race car.

![photo](Screenshots/Screenshot_17.png)
![photo](Screenshots/Screenshot_18.png)
![photo](Screenshots/Screenshot_19.png)
![photo](Screenshots/Screenshot_20.png)
![photo](Screenshots/Screenshot_21.png)
![photo](Screenshots/Screenshot_22.png)
![photo](Screenshots/Screenshot_23.png)

From these diagrams we were able to make some important observations. At first, we saw that the simulation voltages depend a lot by the LUT that we choose. Also, another factor that we ignored for the present moment was the temperature of the cell, which modifies by a lot the internal resistance of the cell and thus its voltage transient response. However, we noticed that the open-circuit voltage, which is subtracted by the voltage drop, is very accurate and depends on the C-Rate of each experiment.

