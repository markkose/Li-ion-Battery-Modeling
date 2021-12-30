%

% Copyright 2016-2018 The MathWorks, Inc.
%
% Using MathWorks tools, estimation techniques, and measured lithium-ion 
% or lead acid battery data, you can generate parameters for the 
% Equivalent Circuit Battery block. The Equivalent Circuit Battery 
% block implements a resistor-capacitor (RC) circuit battery with open 
% circuit voltage, series resistance, and 1 through N RC pairs. The 
% number of RC pairs reflects the number of time constants that 
% characterize the battery transients. Typically, the number of RC pairs 
% ranges from 1 through 5.

%% Step 1: Load and Preprocess Data
%
% Create a Pulse Sequence object, which represents a pulse sequence
% experiment
psObj = Battery.PulseSequence;
disp(psObj)

% Load in data
% Specify the file name
FileName = 'par-E22-8C.mat';

% Read the raw data
[time,voltage,current] = Battery.loadDataFromMatFile(FileName);

% Add the data to the PulseSequence
psObj.addData(time,voltage,current);

% Review the data
psObj.plot();

% Break up the data into Battery.Pulse objects
%
% Create the Pulse objects within the PulseSequence. This creates a
% parameter object that contains look-up tables of the correct size, given
% the number of pulses
psObj.createPulses(...
    'CurrentOnThreshold',0.1,... %minimum current magnitude to identify pulse events
    'NumRCBranches',2,... %how many RC pairs in the model
    'RCBranchesUse2TimeConstants',false,... %do RC pairs have different time constant for discharge and rest?
    'PreBufferSamples',10,... %how many samples to include before the current pulse starts
    'PostBufferSamples',15); %how many samples to include after the next pulse starts

% Specify the Simulink model that matches the number of RC branches and
% time constants:
psObj.ModelName = 'BatteryEstim2RC_PTBS';

% Plot the identified pulses in the data
psObj.plotIdentifiedPulses();

%Note: if for some reason we want to exclude some of the pulses, you can do
%something like this:
% psObj.removePulses(indexToRemove);
% psObj.plotIdentifiedPulses();


%% Step 2: Determine the Number of RC Pairs
%
% This step helps us decide how many RC pairs should be used in the model.
% More RC pairs add complexity and might over-fit the data. Too few 
% increases the fit error. Note: If you decide to change the number of
% pairs, you need to rerun createPulses above and change NumRCBranches to
% the new value.

% Pick a pulse near the beginning, middle, and end. Note: you could run all
% of them if you want.
PulsesToTest = [1 floor(psObj.NumPulses/2), psObj.NumPulses-1];

% Perform the comparison
%psObj.Pulse(PulsesToTest).compareRelaxationTau();

%% Step 3: Estimate Parameters
% Set settings
% Pull out the parameters. Only update parameters once because it changes
% the history each time they update.
Params = psObj.Parameters;

% Set Em constraints and initial guesses (or don't and try the defaults)
Params.Em(:) = 3.65;
Params.EmMin(:) = 3;
Params.EmMax(:) = 4.2;

% Set R0 constraints and initial guesses (or don't and try the defaults)
Params.R0(:) = 0.002;
Params.R0Min(:) = 0.0008;
Params.R0Max(:) = 0.1;

% Set Tx constraints and initial guesses. It is important to default each
% time constant Tx to different values, otherwise the optimizer may not
% pull them apart.
Params.Tx(1,:,:) = 1;
Params.Tx(2,:,:) = 20;
%Params.Tx(3,:,:) = 200;

Params.TxMin(1,:,:) = 0.01;
Params.TxMax(1,:,:) = 10;

Params.TxMin(2,:,:) = 2;
Params.TxMax(2,:,:) = 60;

%Params.TxMin(3,:,:) = 10;
%Params.TxMax(3,:,:) = 300; %don't set this bigger than the relaxation time available

% Set Rx constraints and initial guesses (or don't and try the defaults)
Params.Rx(:) = 0.005;
Params.RxMin(:) = 0.0001;
Params.RxMax(:) = 0.5;

% Update parameters
psObj.Parameters = Params;

% Estimate initial Em and R0 values
%
% This step inspects the voltage immediately before and after the current
% is applied and removed at the start and end of each pulse. It uses that
% for a raw calculation estimating what the open-circuit voltage (Em) and
% the series resistance R0 should be.

psObj.estimateInitialEmR0(...
    'SetEmConstraints',false,... %Update EmMin or EmMax values based on what we learn here
    'EstimateEm',true,... %Keep this on to perform Em estimates
    'EstimateR0',true); %Keep this on to perform R0 estimates

% Plot results
psObj.plotLatestParameters();

% Get initial Tx (Tau) values
%
% This step performs curve fitting on the pulse relaxation to estimate the
% RC time constant at each SOC.

psObj.estimateInitialTau(...
    'UpdateEndingEm',false,... %Keep this on to update Em estimates at the end of relaxations, based on the curve fit
    'ShowPlots',true,... %Set this true if you want to see plots while this runs
    'ReusePlotFigure',true,... %Set this true to overwrite the plots in the same figure
    'UseLoadData',false,... %Set this true if you want to estimate Time constants from the load part of the pulse, instead of relaxation
    'PlotDelay',0.5); %Set this to add delay so you can see the plots 

% Plot results
psObj.plotLatestParameters(); %See what the parameters look like so far
psObj.plotSimulationResults(); %See what the result looks like so far

%
% Get initial Em and Rx values using a linear system approach - pulse by 
% pulse
%
% This step takes the data for each pulse and treats it as a linear system
% It attempts to fit the Rx values for each RC branch. Optionally, you can
% allow it to adjust the Em and R0 values, and if these are adjusted, you
% also have the option whether to retain the optimized values of these or
% to discard them.

psObj.estimateInitialEmRx(...
    'IgnoreRelaxation',false,... %Set this true if you want to ignore the relaxation periods during this step
    'ShowPlots',true,...  %Set this true if you want to see plots while this runs
    'ShowBeforePlots',true,... %Set this true if you want to see the 'before' value on the plots
    'PlotDelay',0.5,... %Set this to add delay so you can see the plots 
    'EstimateEm',true,... %Set this true to allow the optimizer to change Em further in this step
    'RetainEm',true,... %Set this true keep any changes made to Em in this step
    'EstimateR0',true,... %Set this true to allow the optimizer to change R0 further in this step
    'RetainR0',true); %Set this true keep any changes made to R0 in this step

% Plot results
psObj.plotLatestParameters(); %See what the parameters look like so far
psObj.plotSimulationResults(); %See what the result looks like so far


% Perform SDO Estimation
SDOOptimizeOptions = sdo.OptimizeOptions(...
    'OptimizedModel',psObj.ModelName,...
    'Method','lsqnonlin',...
    'UseParallel','always');

psObj.estimateParameters(...
    'CarryParamToNextPulse',true,... %Set this true to use the final parameter values from the prior pulse and SOC as initial values for the next pulse and SOC
    'SDOOptimizeOptions',SDOOptimizeOptions,... %Specify the SDO options object
    'ShowPlots',true,... %Set this true if you want to see plots while this runs
    'EstimateEm',true,... %Set this true to allow the optimizer to change Em further in this step
    'RetainEm',true,... %Set this true keep any changes made to Em in this step
    'EstimateR0',true,... %Set this true to allow the optimizer to change R0 further in this step
    'RetainR0',true); %Set this true keep any changes made to R0 in this step

% Plot results
psObj.plotLatestParameters(); %See what the parameters look like so far
psObj.plotSimulationResults(); %See what the result looks like so far


%% Step 4: Set Equivalent Circuit Battery Block Parameters
%
% The experiment was run at ambient temperature (303°K) only.  Repeat 
% the tables across the operating temperature range.  If the discharge 
% experiment was run at 2 different constant temperatures, then include 
% these in the tables below. 
EmPrime = repmat(Em,2,1)';
R0Prime = repmat(R0,2,1)';
SOC_LUTPrime = SOC_LUT;
TempPrime = [303 315.15];
CapacityAhPrime = [CapacityAh CapacityAh];

R1Prime = repmat(Rx(1,:),2,1)';
C1Prime = repmat(Tx(1,:)./Rx(1,:),2,1)';
R2Prime = repmat(Rx(2,:),2,1)';
C2Prime = repmat(Tx(2,:)./Rx(2,:),2,1)';
%R3Prime = repmat(Rx(3,:),2,1)';
%C3Prime = repmat(Tx(3,:)./Rx(3,:),2,1)';

open_system('BatteryEstim2RC_PTBS_EQ');

save LUT-E22-8C C1Prime C2Prime CapacityAh CapacityAhPrime Em EmPrime R0 R0Prime R1Prime R2Prime Rx SOC_LUT SOC_LUTPrime TempPrime Tx InitialCapVoltage InitialChargeDeficitAh;
