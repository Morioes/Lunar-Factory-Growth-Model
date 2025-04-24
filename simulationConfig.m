function config = simulationConfig()
    % SIMULATIONCONFIG Returns the simulation configuration for the lunar factory
    %   This function initializes simulation parameters such as time step size,
    %   number of time steps, initial factory configuration, and bootstrap sequence.
    
    % Create config structure
    config = struct();
    
    % Simulation time parameters
    config.timeStepSize = 4320; % hours (30 days) - Updated to match documentation
    config.numTimeSteps = 10; % Number of time steps (10 years) - Updated to match documentation
    
    % Initial mass and resupply rate
    config.initialLandedMass = 10000; % kg
    config.resupplyRate = 250; % kg/year
    
    % Initial Factory Configuration
    config.initialConfig = struct();
    
    % Extraction
    config.initialConfig.extraction = struct();
    config.initialConfig.extraction.units = 3;
    config.initialConfig.extraction.mass = 90; % kg 
    
    % Processing (MRE)
    config.initialConfig.processingMRE = struct();
    config.initialConfig.processingMRE.units = 1;
    config.initialConfig.processingMRE.mass = 800; % kg 
    
    % Processing (HCl Acid Treatment)
    config.initialConfig.processingHCl = struct();
    config.initialConfig.processingHCl.units = 1;
    config.initialConfig.processingHCl.mass = 500; % kg 
    
    % Processing (Vacuum Pyrolysis)
    config.initialConfig.processingVP = struct();
    config.initialConfig.processingVP.units = 0;
    config.initialConfig.processingVP.mass = 0; % kg
    
    % Manufacturing (L-PBF)
    config.initialConfig.manufacturingLPBF = struct();
    config.initialConfig.manufacturingLPBF.units = 2; 
    config.initialConfig.manufacturingLPBF.mass = 2600; % kg 
    
    % Manufacturing (Thermal Vacuum Deposition)
    config.initialConfig.manufacturingEBPVD = struct();
    config.initialConfig.manufacturingEBPVD.units = 2; 
    config.initialConfig.manufacturingEBPVD.mass = 600; % kg 
    
    % Manufacturing (Sand Casting) - NEW
    config.initialConfig.manufacturingSC = struct();
    config.initialConfig.manufacturingSC.units = 1;
    config.initialConfig.manufacturingSC.mass = 575; % kg 
    
    % Manufacturing (Permanent Casting)
    config.initialConfig.manufacturingPC = struct();
    config.initialConfig.manufacturingPC.units = 0;
    config.initialConfig.manufacturingPC.mass = 0; % kg 
    
    % Manufacturing (Selective Solar Light Sinter)
    config.initialConfig.manufacturingSSLS = struct();
    config.initialConfig.manufacturingSSLS.units = 2; % 
    config.initialConfig.manufacturingSSLS.mass = 130; % kg 
    
    % Assembly
    config.initialConfig.assembly = struct();
    config.initialConfig.assembly.units = 1;
    config.initialConfig.assembly.mass = 1130; % kg
    
    % Power Generation (Landed Solar)
    config.initialConfig.powerLandedSolar = struct();
    config.initialConfig.powerLandedSolar.mass = 2000; % kg
    
    % Power Generation (Lunar Solar)
    config.initialConfig.powerLunarSolar = struct();
    config.initialConfig.powerLunarSolar.mass = 0; % kg
    
    % Power Generation (Solar Concentrators with Stirling Engines)
    config.initialConfig.powerSCSE = struct();
    config.initialConfig.powerSCSE.mass = 0; % kg
    
    % Power Storage (Battery)
    config.initialConfig.storageBattery = struct();
    config.initialConfig.storageBattery.mass = 0; % kg
    
    % Power Storage (Flywheel)
    config.initialConfig.storageFlywheel = struct();
    config.initialConfig.storageFlywheel.mass = 0; % kg
    
    % Initial Spare Parts
    config.initialConfig.initialSpareParts = 500; % kg
    
    % Bootstrap Sequence
    config.bootstrapSequence = struct();
    config.bootstrapSequence.steps = {
        'Power system activation',...
        'Extraction units begin collecting regolith',...
        'Processing units begin refining materials',...
        'Manufacturing units create components from refined materials',...
        'Assembly units integrate components into new subsystems',...
        'Factory transitions to self-expansion mode'
    };
    
    % Optimization Parameters
    config.optimization = struct();
    
    % Objective function weights
    config.optimization.weights = struct();
    config.optimization.weights.expansion = [0.0, 1.0]; % Range
    config.optimization.weights.revenue = [0.0, 1.0]; % Range
    config.optimization.weights.cost = [0.0, 1.0]; % Range
    config.optimization.weights.power = [0.0, 1.0]; % Range

    % Preset scenarios
    config.optimization.presets = struct();
    config.optimization.presets.balancedGrowth = struct('expansion', 0.4, 'revenue', 0.3, 'cost', 0.3);
    config.optimization.presets.rapidExpansion = struct('expansion', 0.6, 'revenue', 0.2, 'cost', 0.2);
    config.optimization.presets.profitFocused = struct('expansion', 0.2, 'revenue', 0.6, 'cost', 0.2);
    config.optimization.presets.costMinimizing = struct('expansion', 0.2, 'revenue', 0.2, 'cost', 0.6);
    config.optimization.presets.powerPriority = struct('expansion', 0.3, 'revenue', 0.2, 'cost', 0.2, 'power', 0.3);

    % Set as default optimization preset
    config.optimizationPreset = 'powerPriority';
    
    % Set default optimization preset
    config.optimizationPreset = 'balancedGrowth';
    
    % Constraints
    config.optimization.constraints = struct();
    config.optimization.constraints.maxPowerDeficit = 0.3; % Max 30% power deficit
    config.optimization.constraints.minCapacityUtilization = 0.6; % Min 60% capacity utilization 
end