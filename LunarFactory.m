classdef LunarFactory < handle
    % LunarFactory Class for simulating a self-expanding lunar factory
    % This class handles the simulation of a self-expanding lunar factory
    % including all subsystems, material flows, power generation, and economics
    
    properties
        % Configuration
        envConfig           % Environmental configuration
        subConfig           % Subsystem configuration
        econConfig          % Economic configuration
        simConfig           % Simulation configuration
        
        % Subsystems
        extraction          % Extraction subsystem
        processingMRE       % Molten Regolith Electrolysis processing
        processingHCl       % HCl Acid Treatment processing
        processingVP        % Vacuum Pyrolysis processing
        manufacturingLPBF   % Laser Powder Bed Fusion manufacturing
        manufacturingEBPVD    % Thermal Vacuum Deposition manufacturing
        manufacturingSC     % Sand Casting manufacturing
        manufacturingPC     % Permanent Casting manufacturing
        manufacturingSSLS   % Selective Solar Light Sinter manufacturing
        assembly            % Assembly subsystem
        powerLandedSolar    % Landed Solar power
        powerLunarSolar     % Lunar-made Solar power
        
        % Material Inventory
        inventory           % Material inventory
        
        % Simulation State
        currentTimeStep     % Current time step
        totalMass           % Total factory mass
        powerCapacity       % Total power capacity
        powerDemand         % Total power demand
        powerDistribution   % Power distribution across subsystems
        massDistribution    % Mass distribution across subsystems
        productionAllocation % Allocation between replication and sales
        inRecoveryMode      % Flag for recovery mode
        
        % Performance Metrics
        metrics             % Performance metrics over time
        
        % Economic Metrics
        economics           % Economic metrics over time

        % Optimization History
        optimizationHistory % History of optimization runs and results

    end
    
    methods

        function obj = LunarFactory(envConfig, subConfig, econConfig, simConfig)
            % Constructor
            % Initialize the factory with configuration parameters
            
            % Store configurations
            obj.envConfig = envConfig;
            obj.subConfig = subConfig;
            obj.econConfig = econConfig;
            obj.simConfig = simConfig;

            % Initialize subsystems
            obj.initializeSubsystems();
            
            % Initialize material inventory
            obj.initializeInventory();
            
            % Initialize simulation state
            obj.currentTimeStep = 0;
            obj.inRecoveryMode = false;
            
            % Initialize metrics
            obj.initializeMetrics();
            
            % Calculate initial state
            obj.calculateInitialState();
        end
        

        % This artifact contains the updated code for the initializeSubsystems function in LunarFactory.m
        % to properly initialize the powerScalingFactor for the Sand Casting subsystem
        
        function initializeSubsystems(obj)
            % Initialize all subsystems with initial configuration
            
            % Extraction
            obj.extraction.units = obj.simConfig.initialConfig.extraction.units;
            obj.extraction.mass = obj.simConfig.initialConfig.extraction.mass;
            obj.extraction.excavationRate = obj.subConfig.extraction.excavationRate;
            obj.extraction.energyPerKg = obj.subConfig.extraction.energyPerKg;
            
            % Processing - MRE
            obj.processingMRE.units = obj.simConfig.initialConfig.processingMRE.units;
            obj.processingMRE.mass = obj.simConfig.initialConfig.processingMRE.mass;
            obj.processingMRE.dutyCycle = obj.subConfig.processingMRE.dutyCycle;
            % Track which units are Earth-manufactured vs lunar-manufactured
            obj.processingMRE.earthManufacturedUnits = obj.simConfig.initialConfig.processingMRE.units;
            % Store per-unit oxygen production rate
            obj.processingMRE.oxygenPerUnitPerYear = obj.subConfig.processingMRE.oxygenPerYear / obj.processingMRE.units;
            obj.processingMRE.oxygenPerYear = obj.processingMRE.oxygenPerUnitPerYear * obj.processingMRE.units;
            
            % Processing - HCl
            obj.processingHCl.units = obj.simConfig.initialConfig.processingHCl.units;
            obj.processingHCl.mass = obj.simConfig.initialConfig.processingHCl.mass;
            
            % Use the Earth manufactured value for now (can be updated during simulation for lunar-manufactured)
            if isfield(obj.subConfig.processingHCl, 'massScalingFactorHCl')
                obj.processingHCl.massScalingFactor = obj.subConfig.processingHCl.massScalingFactorHCl;
            else
                obj.processingHCl.massScalingFactor = 538; 
            end
            
            obj.processingHCl.powerScalingFactor = obj.subConfig.processingHCl.powerScalingFactor;
            obj.processingHCl.reagentConsumptionRate = obj.subConfig.processingHCl.reagentConsumptionRate;
            
            % Processing - VP (Vacuum Pyrolysis)
            obj.processingVP.units = obj.simConfig.initialConfig.processingVP.units;
            obj.processingVP.mass = obj.simConfig.initialConfig.processingVP.mass;
            obj.processingVP.massScalingFactor = obj.subConfig.processingVP.massScalingFactor;
            obj.processingVP.powerScalingFactor = obj.subConfig.processingVP.powerScalingFactor;
            
            % Manufacturing - LPBF
            obj.manufacturingLPBF.units = obj.simConfig.initialConfig.manufacturingLPBF.units;
            
            % Use the Earth manufactured value for now
            if isfield(obj.subConfig.manufacturingLPBF, 'massPerUnitLunar')
                obj.manufacturingLPBF.mass = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.massPerUnit;
                obj.manufacturingLPBF.massPerUnit = obj.subConfig.manufacturingLPBF.massPerUnit;
            else
                obj.manufacturingLPBF.mass = obj.manufacturingLPBF.units * 1300;
                obj.manufacturingLPBF.massPerUnit = 1300;
            end
            
            obj.manufacturingLPBF.powerPerUnit = obj.subConfig.manufacturingLPBF.powerPerUnit;
            
            % Manufacturing - EBPVD (Thermal Vacuum Deposition)
            obj.manufacturingEBPVD.units = obj.simConfig.initialConfig.manufacturingEBPVD.units;
            obj.manufacturingEBPVD.mass = obj.simConfig.initialConfig.manufacturingEBPVD.mass;
            
            % Use the Earth manufactured mass scaling factor for initial setup
            obj.manufacturingEBPVD.massScalingFactor = obj.subConfig.manufacturingEBPVD.massScalingFactorEarth;
            obj.manufacturingEBPVD.powerScalingFactor = obj.subConfig.manufacturingEBPVD.powerScalingFactor;
            
            % Calculate production capacity based on mass scaling factor
            obj.manufacturingEBPVD.productionCapacity = obj.manufacturingEBPVD.mass / obj.manufacturingEBPVD.massScalingFactor;
            
            % Get deposition parameters for solar thin film components
            obj.manufacturingEBPVD.aluminumThicknessFraction = obj.subConfig.manufacturingEBPVD.aluminumThicknessFraction;
            obj.manufacturingEBPVD.siliconThicknessFraction = obj.subConfig.manufacturingEBPVD.siliconThicknessFraction;
            obj.manufacturingEBPVD.silicaThicknessFraction = obj.subConfig.manufacturingEBPVD.silicaThicknessFraction;
            
            obj.manufacturingEBPVD.aluminumDepositionRate = obj.subConfig.manufacturingEBPVD.aluminumDepositionRate;
            obj.manufacturingEBPVD.siliconDepositionRate = obj.subConfig.manufacturingEBPVD.siliconDepositionRate;
            obj.manufacturingEBPVD.silicaDepositionRate = obj.subConfig.manufacturingEBPVD.silicaDepositionRate;

            % Manufacturing - Sand Casting (SC) (New)
            if isfield(obj.simConfig.initialConfig, 'manufacturingSC')
                obj.manufacturingSC.units = obj.simConfig.initialConfig.manufacturingSC.units;
                obj.manufacturingSC.mass = obj.simConfig.initialConfig.manufacturingSC.mass;
            else
                % Default initialization if not in config
                obj.manufacturingSC.units = 0;
                obj.manufacturingSC.mass = 0;
            end
            

            % Always set default scaling factors first
            obj.manufacturingSC.massScalingFactor = 33.3; 
            obj.manufacturingSC.powerScalingFactor = 43.1; 
            
            % Then override with config values if available
            if isfield(obj.subConfig, 'manufacturingSC')
                if isfield(obj.subConfig.manufacturingSC, 'massScalingFactor')
                    obj.manufacturingSC.massScalingFactor = obj.subConfig.manufacturingSC.massScalingFactor;
                end
                
                if isfield(obj.subConfig.manufacturingSC, 'powerScalingFactor')
                    obj.manufacturingSC.powerScalingFactor = obj.subConfig.manufacturingSC.powerScalingFactor;
                end
            end

            
            % Manufacturing - PC (Permanent Casting)
            obj.manufacturingPC.units = obj.simConfig.initialConfig.manufacturingPC.units;
            obj.manufacturingPC.mass = obj.simConfig.initialConfig.manufacturingPC.mass;
            
            % Use new fields if available, otherwise use old fields with defaults
            if isfield(obj.subConfig.manufacturingPC, 'massScalingFactor')
                obj.manufacturingPC.massScalingFactor = obj.subConfig.manufacturingPC.massScalingFactor;
            else
                obj.manufacturingPC.massScalingFactor = 10;
            end
            
            if isfield(obj.subConfig.manufacturingPC, 'powerScalingFactor')
                obj.manufacturingPC.powerScalingFactor = obj.subConfig.manufacturingPC.powerScalingFactor;
            else
                obj.manufacturingPC.powerScalingFactor = 43.1; 
            end
           
            
            % Manufacturing - SSLS
            obj.manufacturingSSLS.units = obj.simConfig.initialConfig.manufacturingSSLS.units;
            obj.manufacturingSSLS.mass = obj.simConfig.initialConfig.manufacturingSSLS.mass;
            
            % Use Earth manufactured values initially
            if isfield(obj.subConfig.manufacturingSSLS, 'massScalingFactorEarth')
                obj.manufacturingSSLS.massScalingFactor = obj.subConfig.manufacturingSSLS.massScalingFactorEarth;
            else
                obj.manufacturingSSLS.massScalingFactor = obj.subConfig.manufacturingSSLS.massScalingFactorSSLS; 
            end
            
            if isfield(obj.subConfig.manufacturingSSLS, 'powerScalingFactor')
                obj.manufacturingSSLS.powerScalingFactor = obj.subConfig.manufacturingSSLS.powerScalingFactor;
            else
                obj.manufacturingSSLS.powerScalingFactor = obj.subConfig.manufacturingSSLS.powerScalingFactorSSLS;
            end
            
            % Assembly
            obj.assembly.units = obj.simConfig.initialConfig.assembly.units;
            obj.assembly.mass = obj.simConfig.initialConfig.assembly.units * obj.subConfig.assembly.massPerUnit;
            obj.assembly.powerPerUnit = obj.subConfig.assembly.powerPerUnit;
            obj.assembly.assemblyCapacity = obj.subConfig.assembly.assemblyCapacity;
            
            % Power - Landed Solar
            obj.powerLandedSolar.mass = obj.simConfig.initialConfig.powerLandedSolar.mass;
            
            if isfield(obj.subConfig.powerLandedSolar, 'powerScaling')
                obj.powerLandedSolar.capacity = obj.powerLandedSolar.mass * obj.subConfig.powerLandedSolar.powerScaling;
            else
                obj.powerLandedSolar.capacity = obj.powerLandedSolar.mass / obj.subConfig.powerLandedSolar.massPerW;
            end
            
            % Power - Lunar Solar
            obj.powerLunarSolar.mass = obj.simConfig.initialConfig.powerLunarSolar.mass;
            obj.powerLunarSolar.area = obj.powerLunarSolar.mass / obj.subConfig.powerLunarSolar.massPerArea;
            obj.powerLunarSolar.efficiency = obj.subConfig.powerLunarSolar.efficiency;
            obj.powerLunarSolar.capacity = obj.powerLunarSolar.area * obj.envConfig.solarIllumination * obj.powerLunarSolar.efficiency;
        end
        
        function resetFactoryState(obj)
            % Reset factory state while preserving optimized parameters
            
            % Reset time step
            obj.currentTimeStep = 0;
            
            % Reset recovery mode flag
            obj.inRecoveryMode = false;
            
            % Reset inventory to initial values
            obj.initializeInventory();
            
            % Reset subsystems to initial configuration
            obj.initializeSubsystems();
            
            % Reset metrics
            obj.initializeMetrics();
            
            % Calculate initial state with optimized parameters
            obj.calculateInitialState();
            
            disp('Factory state reset while preserving optimization parameters');
        end

        function initializeInventory(obj)
            % Initialize material inventory
            
            % Raw materials
            obj.inventory.rawRegolith = 100000000000000000; % Add a large initial amount of raw regolith
            obj.inventory.regolith = 0;
            
            % Processed materials
            obj.inventory.oxygen = 0;
            obj.inventory.iron = 0;
            obj.inventory.silicon = 0;
            obj.inventory.aluminum = 0;
            obj.inventory.slag = 0;
            obj.inventory.silica = 0;
            obj.inventory.alumina = 0;
            
            % Manufactured materials
            obj.inventory.castAluminum = 0;
            obj.inventory.castIron = 0;
            obj.inventory.castSlag = 0;
            obj.inventory.sinteredAlumina = 0;
            obj.inventory.silicaGlass = 0;
            obj.inventory.sinteredRegolith = 0;
            obj.inventory.precisionAluminum = 0;
            obj.inventory.precisionIron = 0;
            obj.inventory.precisionAlumina = 0;
            obj.inventory.solarThinFilm = 0;
            
            % Non-replicable components
            obj.inventory.nonReplicable = obj.simConfig.initialConfig.initialSpareParts;
        end

        function initializeMetrics(obj)
            % Initialize performance and economic metrics
            
            % Allocate arrays for metrics
            numSteps = obj.simConfig.numTimeSteps;
            
            % Performance metrics
            obj.metrics.totalMass = zeros(1, numSteps);
            obj.metrics.powerCapacity = zeros(1, numSteps);
            obj.metrics.powerDemand = zeros(1, numSteps);
            obj.metrics.monthlyGrowthRate = zeros(1, numSteps);
            obj.metrics.annualGrowthRate = zeros(1, numSteps);
            obj.metrics.replicationFactor = zeros(1, numSteps);
            obj.metrics.extractionRate = zeros(1, numSteps);
            obj.metrics.processingRate = zeros(1, numSteps);
            obj.metrics.manufacturingRate = zeros(1, numSteps);
            obj.metrics.assemblyRate = zeros(1, numSteps);
            
            % Material flow rates
            obj.metrics.materialFlows.regolith = zeros(1, numSteps);
            obj.metrics.materialFlows.oxygen = zeros(1, numSteps);
            obj.metrics.materialFlows.iron = zeros(1, numSteps);
            obj.metrics.materialFlows.silicon = zeros(1, numSteps);
            obj.metrics.materialFlows.aluminum = zeros(1, numSteps);
            obj.metrics.materialFlows.slag = zeros(1, numSteps);
            obj.metrics.materialFlows.silica = zeros(1, numSteps);
            obj.metrics.materialFlows.alumina = zeros(1, numSteps);

            % Track 12 subsystems (added Sand Casting)
            obj.metrics.subsystemMasses = zeros(numSteps, 12); 
            
            % Economic metrics
            obj.economics.revenue = zeros(1, numSteps);
            obj.economics.costs = zeros(1, numSteps);
            obj.economics.profit = zeros(1, numSteps);
            obj.economics.cumulativeProfit = zeros(1, numSteps);
            obj.economics.ROI = zeros(1, numSteps);
        end
        
        function calculateInitialState(obj)
            % Calculate initial state of the factory
            
            % Calculate total mass
            obj.totalMass = obj.calculateTotalMass();
            
            % Calculate power capacity and demand
            obj.calculatePowerCapacity();
            obj.calculatePowerDemand();
            
            % Initialize power and mass distribution
            obj.initializeResourceDistribution();
            
            % Initialize production allocation
            obj.initializeProductionAllocation();
            
            % Record initial metrics
            obj.recordMetrics(1);
        end
        
        function totalMass = calculateTotalMass(obj)
            % Calculate total mass of the factory
            
            totalMass = 0;
            
            % Add subsystem masses
            totalMass = totalMass + obj.extraction.mass;
            totalMass = totalMass + calculateMREMass(obj);
            totalMass = totalMass + obj.processingHCl.mass;
            totalMass = totalMass + obj.processingVP.mass;
            totalMass = totalMass + obj.manufacturingLPBF.mass;
            totalMass = totalMass + obj.manufacturingEBPVD.mass;
            totalMass = totalMass + obj.manufacturingSC.mass; 
            totalMass = totalMass + obj.manufacturingPC.mass;
            totalMass = totalMass + obj.manufacturingSSLS.mass;
            totalMass = totalMass + obj.assembly.mass;
            totalMass = totalMass + obj.powerLandedSolar.mass;
            totalMass = totalMass + obj.powerLunarSolar.mass;
        end
        
        function calculatePowerCapacity(obj)
            % Calculate total power generation capacity
            
            % Base generation during sunlight
            landedSolarCapacity = obj.powerLandedSolar.capacity * obj.envConfig.sunlightFraction;
            lunarSolarCapacity = obj.powerLunarSolar.capacity * obj.envConfig.sunlightFraction;
            
            % Total power capacity
            obj.powerCapacity = landedSolarCapacity + lunarSolarCapacity;
        end

% This artifact contains the updated code for the calculatePowerDemand method in LunarFactory.m
% to safely handle potentially missing powerScalingFactor property in the Sand Casting subsystem

function calculatePowerDemand(obj)
    % Calculate total power demand
    
    % Initialize power demand
    powerDemand = 0;
    
    % Extraction power demand
    extractionPower = obj.extraction.units * obj.extraction.excavationRate * obj.extraction.energyPerKg;
    powerDemand = powerDemand + extractionPower;
    
    % MRE power demand
    totalMrePower = 0;
    % Calculate power for each MRE unit individually
    for i = 1:obj.processingMRE.units
        N = obj.processingMRE.oxygenPerUnitPerYear;
        t = obj.processingMRE.dutyCycle;
        % Apply non-linear formula to each unit
        unitPower = 264 * (N/(2*t))^0.577;
        totalMrePower = totalMrePower + unitPower;
    end
    powerDemand = powerDemand + totalMrePower;
    
    % HCl power demand
    if obj.processingHCl.mass > 0
        hclPower = obj.processingHCl.mass * obj.processingHCl.powerScalingFactor / obj.processingHCl.massScalingFactor;
    else
        hclPower = 0;
    end
    powerDemand = powerDemand + hclPower;
    
    % VP power demand
    vpPower = obj.processingVP.powerScalingFactor * obj.processingVP.mass / obj.processingVP.massScalingFactor;
    powerDemand = powerDemand + vpPower;
    
    % LPBF power demand
    lpbfPower = obj.manufacturingLPBF.units * obj.manufacturingLPBF.powerPerUnit;
    powerDemand = powerDemand + lpbfPower;
    
    % EBPVD power demand - Updated to use production capacity and power scaling factor
    if obj.manufacturingEBPVD.mass > 0
        % Calculate production capacity based on mass scaling factor
        productionCapacity = obj.manufacturingEBPVD.mass / obj.manufacturingEBPVD.massScalingFactor;
        % Calculate power demand using power scaling factor
        EBPVDPower = productionCapacity * obj.manufacturingEBPVD.powerScalingFactor;
        powerDemand = powerDemand + EBPVDPower;
    else
        EBPVDPower = 0;
    end
    
    % Sand Casting power demand
    if obj.manufacturingSC.mass > 0
        % Get powerScalingFactor with fallback to default
        if isfield(obj.manufacturingSC, 'powerScalingFactor')
            powerFactor = obj.manufacturingSC.powerScalingFactor;
        else
            disp('Warning: Missing powerScalingFactor for Sand Casting. Using default value.');
            powerFactor = 43.1; % Default from documentation
        end
        
        % Get massScalingFactor with fallback to default
        if isfield(obj.manufacturingSC, 'massScalingFactor')
            massFactor = obj.manufacturingSC.massScalingFactor;
        else
            disp('Warning: Missing massScalingFactor for Sand Casting. Using default value.');
            massFactor = 33.3; % Default from documentation
        end
        
        % Calculate power using retrieved values
        scPower = powerFactor * obj.manufacturingSC.mass / massFactor;
        powerDemand = powerDemand + scPower;
    end

    % PC power demand
    pcPower = obj.manufacturingPC.powerScalingFactor * obj.manufacturingPC.mass / obj.manufacturingPC.massScalingFactor;
    powerDemand = powerDemand + pcPower;
    
    % SSLS power demand
    sslsPower = obj.manufacturingSSLS.powerScalingFactor * obj.manufacturingSSLS.mass / obj.manufacturingSSLS.massScalingFactor;
    powerDemand = powerDemand + sslsPower;
    
    % Assembly power demand
    assemblyPower = obj.assembly.units * obj.assembly.powerPerUnit;
    powerDemand = powerDemand + assemblyPower;

    % Add safety checks for invalid values
    % Check for NaN or Inf values
    if isnan(powerDemand) || isinf(powerDemand)
        disp('Warning: Invalid power demand calculated (NaN or Inf). Resetting to reasonable value.');
        powerDemand = obj.powerCapacity * 1.2; % Set to 120% of capacity as a reasonable default
    end
    
    % Hard cap on maximum power demand to prevent extreme values
    maxReasonableDemand = obj.powerCapacity * 2.0; % 200% of capacity as a reasonable cap
    if powerDemand > maxReasonableDemand
        disp(['Warning: Excessively high power demand calculated (' num2str(powerDemand) ' W). Capping at ' num2str(maxReasonableDemand) ' W.']);
        powerDemand = maxReasonableDemand;
    end

    % Set total power demand
    obj.powerDemand = powerDemand;
end

        function balanceMaterialInventory(obj)
            % Enhanced version of balanceMaterialInventory with focus on general resource balance
            
            % NEW: Detect and address regolith bottlenecks early
            if obj.inventory.regolith < 1000 && obj.metrics.extractionRate(max(1, obj.currentTimeStep-1)) < 100
                fprintf('Material flow balancing: Regolith shortage detected (%.2f kg), prioritizing extraction\n', ...
                        obj.inventory.regolith);
                
                % Give extraction high priority
                obj.powerDistribution.extraction = max(0.35, obj.powerDistribution.extraction * 1.5);
                
                % Reduce processing temporarily to allow regolith accumulation
                processingFields = {'processingMRE', 'processingHCl', 'processingVP'};
                for i = 1:length(processingFields)
                    field = processingFields{i};
                    if isfield(obj.powerDistribution, field)
                        obj.powerDistribution.(field) = obj.powerDistribution.(field) * 0.8;
                    end
                end
            end
            
            % Normalize power distribution after all adjustments
            totalPower = sum(struct2array(obj.powerDistribution));
            fnames = fieldnames(obj.powerDistribution);
            for i = 1:length(fnames)
                obj.powerDistribution.(fnames{i}) = obj.powerDistribution.(fnames{i}) / totalPower;
            end
        end

        function initializeResourceDistribution(obj)
            % Initialize power and mass distribution
            
            % Power Distribution
            obj.powerDistribution.extraction = 0.05;
            obj.powerDistribution.processingMRE = 0.15;
            obj.powerDistribution.processingHCl = 0.25;
            obj.powerDistribution.processingVP = 0.05;
            obj.powerDistribution.manufacturingLPBF = 0.1;
            obj.powerDistribution.manufacturingEBPVD = 0.25; % Reduced to allocate to SC
            obj.powerDistribution.manufacturingSC = 0.05; % New: Sand Casting
            obj.powerDistribution.manufacturingPC = 0.03;
            obj.powerDistribution.manufacturingSSLS = 0.02;
            obj.powerDistribution.assembly = 0.05;

            % Mass Distribution
            obj.massDistribution.extraction = 0.03;
            obj.massDistribution.processingMRE = 0.05;
            obj.massDistribution.processingHCl = 0.15;
            obj.massDistribution.processingVP = 0.01;
            obj.massDistribution.manufacturingLPBF = 0.05;
            obj.massDistribution.manufacturingEBPVD = 0.08; % Reduced to allocate to SC
            obj.massDistribution.manufacturingSC = 0.02; % New: Sand Casting
            obj.massDistribution.manufacturingPC = 0.05;
            obj.massDistribution.manufacturingSSLS = 0.05;
            obj.massDistribution.assembly = 0.05;
            obj.massDistribution.power = 0.35;
        end
        
        function initializeProductionAllocation(obj)
            % Initialize production allocation between replication and sales
            
            % Production allocation
            obj.productionAllocation.replication = 0.85;
            obj.productionAllocation.sales = 0.15;
            
            % Material-specific allocations
            obj.productionAllocation.oxygen = 0.3;
            obj.productionAllocation.castSlag = 0.4;

            % Add Power-Specific Allocation
            obj.productionAllocation.solarThinFilm = 0.70;
        end
        
        function runSimulationWithUserInput(obj)
            % Run simulation with user input at each time step
            
            % Loop through time steps
            for step = 1:obj.simConfig.numTimeSteps
                obj.currentTimeStep = step;
                
                fprintf('\n==== Time Step %d of %d ====\n', step, obj.simConfig.numTimeSteps);
                
                % Add termination option
                fprintf('Do you want to continue with this time step? (y/n/q to quit): ');
                continueResponse = input('', 's');
                if ~isempty(continueResponse) && (lower(continueResponse) == 'q')
                    fprintf('Simulation terminated by user.\n');
                    break;
                elseif ~isempty(continueResponse) && (lower(continueResponse) == 'n')
                    fprintf('Skipping to next time step.\n');
                    continue;
                end
                
                % 1. Power allocation
                [subsystemPower, availablePower] = obj.calculateMaxPowerDemand();
                allocatedPower = obj.getUserPowerAllocation(subsystemPower, availablePower);
                obj.distributeUserPower(allocatedPower);
                
                % 2. Production allocation
                obj.displayAvailableResources();
                productionAllocation = obj.getUserProductionAllocation();
                obj.executeProduction(productionAllocation);
                
                % 3. Assembly decisions
                obj.displayInventory();
                assemblyDecisions = obj.getUserAssemblyDecisions();
                obj.executeAssembly(assemblyDecisions);
                
                % 4. Process economics and resupply
                obj.executeEconomicOperations();
                obj.processResupply();
                
                % 5. Update factory state and record metrics
                obj.updateFactoryState();
                obj.recordMetrics(step);
                
                % 6. Display summary
                obj.displayTimeStepSummary();
            end
        end

        function [subsystemPower, availablePower, subsystemEnergy, availableEnergy] = calculateMaxPowerDemand(obj)
            % Calculate maximum power demand and energy requirements for each subsystem
            % Returns both instantaneous power (W) and total energy (Wh) for the time step
            
            subsystemPower = struct();
            subsystemEnergy = struct();
            
            % Duration of time step in hours
            timeStepHours = obj.simConfig.timeStepSize;
            
            % Calculate for extraction
            extractionPower = obj.extraction.units * obj.extraction.excavationRate * obj.extraction.energyPerKg;
            subsystemPower.extraction = extractionPower;
            subsystemEnergy.extraction = extractionPower * timeStepHours;
            
            % Calculate for processing subsystems
            % MRE
            N = obj.processingMRE.oxygenPerYear;
            t = obj.processingMRE.dutyCycle;
            mrePower = 264 * (N/(2*t))^0.577;
            subsystemPower.processingMRE = mrePower;
            subsystemEnergy.processingMRE = mrePower * timeStepHours;
            
            % HCl
            if obj.processingHCl.mass > 0
                hclPower = obj.processingHCl.mass * obj.processingHCl.powerScalingFactor / obj.processingHCl.massScalingFactor;
                subsystemPower.processingHCl = hclPower;
                subsystemEnergy.processingHCl = hclPower * timeStepHours;
            else
                subsystemPower.processingHCl = 0;
                subsystemEnergy.processingHCl = 0;
            end
            
            % VP
            vpPower = obj.processingVP.powerScalingFactor * obj.processingVP.mass / obj.processingVP.massScalingFactor;
            subsystemPower.processingVP = vpPower;
            subsystemEnergy.processingVP = vpPower * timeStepHours;
            
            % Manufacturing - LPBF
            lpbfPower = obj.manufacturingLPBF.units * obj.manufacturingLPBF.powerPerUnit;
            subsystemPower.manufacturingLPBF = lpbfPower;
            subsystemEnergy.manufacturingLPBF = lpbfPower * timeStepHours;
            
            % Manufacturing - EBPVD (Updated to use production capacity and power scaling factor)
            if obj.manufacturingEBPVD.mass > 0
                % Calculate production capacity based on mass scaling factor
                productionCapacity = obj.manufacturingEBPVD.mass / obj.manufacturingEBPVD.massScalingFactor;
                % Calculate power demand using power scaling factor
                EBPVDPower = productionCapacity * obj.manufacturingEBPVD.powerScalingFactor;
                subsystemPower.manufacturingEBPVD = EBPVDPower;
                subsystemEnergy.manufacturingEBPVD = EBPVDPower * timeStepHours;
            else
                subsystemPower.manufacturingEBPVD = 0;
                subsystemEnergy.manufacturingEBPVD = 0;
            end
            
            % Manufacturing - SC (Sand Casting)
            if obj.manufacturingSC.mass > 0
                % Get powerScalingFactor with fallback to default
                if isfield(obj.manufacturingSC, 'powerScalingFactor')
                    powerFactor = obj.manufacturingSC.powerScalingFactor;
                else
                    disp('Warning: Missing powerScalingFactor for Sand Casting. Using default value.');
                    powerFactor = 43.1; % Default from documentation
                end
                
                % Get massScalingFactor with fallback to default
                if isfield(obj.manufacturingSC, 'massScalingFactor')
                    massFactor = obj.manufacturingSC.massScalingFactor;
                else
                    disp('Warning: Missing massScalingFactor for Sand Casting. Using default value.');
                    massFactor = 33.3; % Default from documentation
                end
                
                % Calculate power using retrieved values
                scPower = powerFactor * obj.manufacturingSC.mass / massFactor;
                subsystemPower.manufacturingSC = scPower;
                subsystemEnergy.manufacturingSC = scPower * timeStepHours;
            else
                subsystemPower.manufacturingSC = 0;
                subsystemEnergy.manufacturingSC = 0;
            end
            
            % Manufacturing - PC
            if obj.manufacturingPC.mass > 0
                pcPower = obj.manufacturingPC.powerScalingFactor * obj.manufacturingPC.mass / obj.manufacturingPC.massScalingFactor;
                subsystemPower.manufacturingPC = pcPower;
                subsystemEnergy.manufacturingPC = pcPower * timeStepHours;
            else
                subsystemPower.manufacturingPC = 0;
                subsystemEnergy.manufacturingPC = 0;
            end
            
            % Manufacturing - SSLS
            sslsPower = obj.manufacturingSSLS.powerScalingFactor * obj.manufacturingSSLS.mass / obj.manufacturingSSLS.massScalingFactor;
            subsystemPower.manufacturingSSLS = sslsPower;
            subsystemEnergy.manufacturingSSLS = sslsPower * timeStepHours;
            
            % Assembly
            assemblyPower = obj.assembly.units * obj.assembly.powerPerUnit;
            subsystemPower.assembly = assemblyPower;
            subsystemEnergy.assembly = assemblyPower * timeStepHours;
            
            % Calculate available power and energy
            obj.calculatePowerCapacity();
            availablePower = obj.powerCapacity;
            availableEnergy = availablePower * timeStepHours;
            
            % Display energy information to help user understand requirements
            fprintf('\n===== POWER AND ENERGY REQUIREMENTS =====\n');
            fprintf('Time step duration: %.0f hours\n', timeStepHours);
            fprintf('Available power: %.2f W (%.2f Wh total energy)\n', availablePower, availableEnergy);
            fprintf('\nSubsystem Requirements:\n');
            
            % Display power and energy requirements for each subsystem
            subsystemNames = fieldnames(subsystemPower);
            for i = 1:length(subsystemNames)
                name = subsystemNames{i};
                power = subsystemPower.(name);
                energy = subsystemEnergy.(name);
                
                fprintf('  %s:\n', name);
                fprintf('    - Power: %.2f W (%.1f%% of available)\n', power, power/availablePower*100);
                fprintf('    - Energy: %.2f Wh (%.1f%% of available)\n', energy, energy/availableEnergy*100);
                
                % Special case for extraction to show regolith yield
                if strcmp(name, 'extraction')
                    extractionCapacity = obj.extraction.units * obj.extraction.excavationRate * timeStepHours;
                    fprintf('    - Theoretical yield: %.2f kg of regolith with full power\n', extractionCapacity);
                    
                    % Calculate theoretical yield with current power allocation
                    if power > 0
                        extractionCapacityWithPower = extractionCapacity * min(1, availablePower/power);
                        fprintf('    - Theoretical yield with current power: %.2f kg (%.1f%%)\n', ...
                                extractionCapacityWithPower, extractionCapacityWithPower/extractionCapacity*100);
                    end
                end
            end
            fprintf('==========================================\n\n');
        end
        function allocatedPower = getUserPowerAllocation(obj, subsystemPower, availablePower)
            % Display power info and get user input
            fprintf('Available Power: %.2f W (%.2f Wh over the %d hour time step)\n', ...
                    availablePower, availablePower * obj.simConfig.timeStepSize, obj.simConfig.timeStepSize);
            fprintf('Maximum Power Demands:\n');
            
            subsystemNames = fieldnames(subsystemPower);
            for i = 1:length(subsystemNames)
                fprintf('  %s: %.2f W (%.2f Wh total)\n', ...
                        subsystemNames{i}, ...
                        subsystemPower.(subsystemNames{i}),...
                        subsystemPower.(subsystemNames{i}) * obj.simConfig.timeStepSize);
            end
            
            % Calculate and display energy needed for extraction at full capacity
            extractionCapacity = obj.extraction.units * obj.extraction.excavationRate * obj.simConfig.timeStepSize;
            hourlyPowerNeeded = obj.extraction.excavationRate * obj.extraction.energyPerKg;
            totalEnergyRequired = hourlyPowerNeeded * obj.simConfig.timeStepSize;
            
            fprintf('\nNOTE ON ENERGY CALCULATIONS:\n');
            fprintf('- Full extraction capacity (%.2f kg) requires %.2f Wh of energy over %d hours\n', ...
                    extractionCapacity, totalEnergyRequired, obj.simConfig.timeStepSize);
            fprintf('- This is an average power draw of %.2f W maintained for the entire time step\n',...
                    totalEnergyRequired / obj.simConfig.timeStepSize);
            fprintf('- Current extraction power allocation (%.2f W) provides %.2f Wh of energy\n', ...
                    subsystemPower.extraction, subsystemPower.extraction * obj.simConfig.timeStepSize);
            fprintf('- This will extract approximately %.2f kg of regolith (%.1f%% of capacity)\n', ...
                    (subsystemPower.extraction * obj.simConfig.timeStepSize / totalEnergyRequired) * extractionCapacity,...
                    (subsystemPower.extraction * obj.simConfig.timeStepSize / totalEnergyRequired) * 100);
            
            fprintf('\nEnter power allocation for each subsystem (W):\n');
            fprintf('(Press Enter for default value of 50%% of maximum demand)\n');
            
            allocatedPower = struct();
            totalAllocated = 0;
            
            % Get user input for each subsystem
            for i = 1:length(subsystemNames)
                while true
                    subsystem = subsystemNames{i};
                    fprintf('%s (max %.2f W): ', subsystem, subsystemPower.(subsystem));
                    powerStr = input('', 's');
                    
                    % Handle blank input - use default value (50% of max)
                    if isempty(powerStr)
                        power = min(subsystemPower.(subsystem) * 0.5, availablePower - totalAllocated);
                        fprintf('Using default value: %.2f W\n', power);
                    else
                        % Convert string to number
                        power = str2double(powerStr);
                        if isnan(power)
                            fprintf('Invalid input. Please enter a number.\n');
                            continue;
                        end
                    end
                    
                    if power >= 0 && power <= subsystemPower.(subsystem) && totalAllocated + power <= availablePower
                        allocatedPower.(subsystem) = power;
                        totalAllocated = totalAllocated + power;
                        break;
                    else
                        fprintf('Invalid input. Power must be between 0 and %.2f W, and total allocation cannot exceed %.2f W\n', ...
                            subsystemPower.(subsystem), availablePower);
                    end
                end
            end
            
            fprintf('Total Allocated Power: %.2f W (%.1f%% of available)\n', totalAllocated, totalAllocated/availablePower*100);
            fprintf('Total Energy Allocation: %.2f Wh\n', totalAllocated * obj.simConfig.timeStepSize);
        end

        
        function distributeUserPower(obj, allocatedPower)
            % Distribute user-specified power to subsystems
            
            % Set allocated power for each subsystem
            if isfield(allocatedPower, 'extraction')
                obj.extraction.allocatedPower = allocatedPower.extraction;
            end
            
            if isfield(allocatedPower, 'processingMRE')
                obj.processingMRE.allocatedPower = allocatedPower.processingMRE;
            end
            
            if isfield(allocatedPower, 'processingHCl')
                obj.processingHCl.allocatedPower = allocatedPower.processingHCl;
            end
            
            if isfield(allocatedPower, 'processingVP')
                obj.processingVP.allocatedPower = allocatedPower.processingVP;
            end
            
            if isfield(allocatedPower, 'manufacturingLPBF')
                obj.manufacturingLPBF.allocatedPower = allocatedPower.manufacturingLPBF;
            end
            
            if isfield(allocatedPower, 'manufacturingEBPVD')
                obj.manufacturingEBPVD.allocatedPower = allocatedPower.manufacturingEBPVD;
            end
            
            % Add Sand Casting
            if isfield(allocatedPower, 'manufacturingSC')
                obj.manufacturingSC.allocatedPower = allocatedPower.manufacturingSC;
            end
            
            if isfield(allocatedPower, 'manufacturingPC')
                obj.manufacturingPC.allocatedPower = allocatedPower.manufacturingPC;
            end
            
            if isfield(allocatedPower, 'manufacturingSSLS')
                obj.manufacturingSSLS.allocatedPower = allocatedPower.manufacturingSSLS;
            end
            
            if isfield(allocatedPower, 'assembly')
                obj.assembly.allocatedPower = allocatedPower.assembly;
            end
            
            % Track total power demand
            obj.powerDemand = sum(struct2array(allocatedPower));
        end
        
        function displayAvailableResources(obj)
            % Display available resources
            fprintf('\nAvailable Resources:\n');
            
            resources = fieldnames(obj.inventory);
            for i = 1:length(resources)
                if obj.inventory.(resources{i}) > 0
                    fprintf('  %s: %.2f kg\n', resources{i}, obj.inventory.(resources{i}));
                end
            end
        end
            
% This artifact contains the updated code for the getUserProductionAllocation method in LunarFactory.m
% to safely handle potentially missing massScalingFactor property in the Sand Casting subsystem

function productionAllocation = getUserProductionAllocation(obj)
    % Get user input for production allocation with enhanced resource tracking
    fprintf('\nEnter production allocation for manufacturing subsystems:\n');
    fprintf('(You can allocate less than 100%% to reserve resources)\n');
    
    productionAllocation = struct();
    
    % Create a temporary inventory to track changes
    tempInventory = struct();
    fields = fieldnames(obj.inventory);
    for i = 1:length(fields)
        tempInventory.(fields{i}) = obj.inventory.(fields{i});
    end
    
    
    % LPBF allocation
    if obj.manufacturingLPBF.units > 0
        fprintf('\nL-PBF Manufacturing can process: aluminum, iron, alumina\n');
        fprintf('Available resources:\n');
        
        % Calculate theoretical throughput based on factory capacity
        timeStepHours = obj.simConfig.timeStepSize;
        
        % Use the updated fields if available
        if isfield(obj.subConfig.manufacturingLPBF, 'inputRates')
            maxAlThroughput = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.aluminum * timeStepHours;
            maxFeThroughput = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.iron * timeStepHours;
            maxAluminaThroughput = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.alumina * timeStepHours;
        else
            % Use defaults from documentation
            maxAlThroughput = obj.manufacturingLPBF.units * 0.23 * timeStepHours; 
            maxFeThroughput = obj.manufacturingLPBF.units * 0.68 * timeStepHours;
            maxAluminaThroughput = obj.manufacturingLPBF.units * 0.34 * timeStepHours;
        end
        
        % Show resource availability with usage percentages
        if maxAlThroughput > 0
            alPercent = min(100, tempInventory.aluminum/maxAlThroughput*100);
        else
            alPercent = 0;
        end
        
        if maxFeThroughput > 0
            fePercent = min(100, tempInventory.iron/maxFeThroughput*100);
        else
            fePercent = 0;
        end
        
        if maxAluminaThroughput > 0
            aluminaPercent = min(100, tempInventory.alumina/maxAluminaThroughput*100);
        else
            aluminaPercent = 0;
        end
        
        fprintf('  - Aluminum: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.aluminum, maxAlThroughput, alPercent);
        fprintf('  - Iron: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.iron, maxFeThroughput, fePercent);
        fprintf('  - Alumina: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.alumina, maxAluminaThroughput, aluminaPercent);
        
        fprintf('\nEnter percentage allocation for each (can sum to less than 100%%):\n');
        
        while true
            fprintf('Aluminum %% (default: 40): ');
            alPctStr = input('', 's');
            if isempty(alPctStr)
                alPct = 40;
                fprintf('Using default value: 40%%\n');
            else
                alPct = str2double(alPctStr);
                if isnan(alPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            fprintf('Iron %% (default: 30): ');
            fePctStr = input('', 's');
            if isempty(fePctStr)
                fePct = 30;
                fprintf('Using default value: 30%%\n');
            else
                fePct = str2double(fePctStr);
                if isnan(fePct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            fprintf('Alumina %% (default: 30): ');
            aluminaPctStr = input('', 's');
            if isempty(aluminaPctStr)
                aluminaPct = 30;
                fprintf('Using default value: 30%%\n');
            else
                aluminaPct = str2double(aluminaPctStr);
                if isnan(aluminaPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            totalPct = alPct + fePct + aluminaPct;
            
            % Allow total to be less than 100%
            if alPct >= 0 && fePct >= 0 && aluminaPct >= 0 && totalPct <= 100
                productionAllocation.lpbf = struct('aluminum', alPct/100, 'iron', fePct/100, 'alumina', aluminaPct/100);
                fprintf('Total allocation: %.1f%% (%.1f%% resources reserved)\n', totalPct, 100-totalPct);
                
                % Calculate expected resource usage
                alUsage = min(tempInventory.aluminum, maxAlThroughput * (alPct/100));
                feUsage = min(tempInventory.iron, maxFeThroughput * (fePct/100));
                aluminaUsage = min(tempInventory.alumina, maxAluminaThroughput * (aluminaPct/100));
                
                % Update temporary inventory
                tempInventory.aluminum = tempInventory.aluminum - alUsage;
                tempInventory.iron = tempInventory.iron - feUsage;
                tempInventory.alumina = tempInventory.alumina - aluminaUsage;
                
                fprintf('\nEstimated resource usage:\n');
                fprintf('  - Aluminum: %.2f kg (%.2f kg remaining)\n', alUsage, tempInventory.aluminum);
                fprintf('  - Iron: %.2f kg (%.2f kg remaining)\n', feUsage, tempInventory.iron);
                fprintf('  - Alumina: %.2f kg (%.2f kg remaining)\n', aluminaUsage, tempInventory.alumina);
                
                break;
            else
                fprintf('Invalid input. Percentages must be non-negative and sum to less than or equal to 100%%\n');
            end
        end
    end
    
    % Sand Casting allocation (NEW)
    if obj.manufacturingSC.mass > 0
        fprintf('\nSand Casting can process: aluminum, iron, slag\n');
        fprintf('Available resources:\n');
        
        % Calculate theoretical throughput - WITH FIX FOR MISSING massScalingFactor
        % Get massScalingFactor with fallback to default value
        if isfield(obj.manufacturingSC, 'massScalingFactor')
            massScalingFactor = obj.manufacturingSC.massScalingFactor;
        else
            disp('Warning: Missing massScalingFactor for Sand Casting. Using default value.');
            massScalingFactor = 33.3; % Default from documentation
        end
        
        timeStepHours = obj.simConfig.timeStepSize;
        castingCapacity = obj.manufacturingSC.mass / massScalingFactor;
        maxCastingThroughput = castingCapacity * timeStepHours;
        
        % Calculate percentages
        if maxCastingThroughput > 0
            alPercent = min(100, tempInventory.aluminum/maxCastingThroughput*100);
            fePercent = min(100, tempInventory.iron/maxCastingThroughput*100);
            slagPercent = min(100, tempInventory.slag/maxCastingThroughput*100);
        else
            alPercent = 0;
            fePercent = 0;
            slagPercent = 0;
        end
        
        fprintf('  - Aluminum: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.aluminum, maxCastingThroughput, alPercent);
        fprintf('  - Iron: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.iron, maxCastingThroughput, fePercent);
        fprintf('  - Slag: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.slag, maxCastingThroughput, slagPercent);
        
        fprintf('\nEnter percentage allocation for each (can sum to less than 100%%):\n');
        
        while true
            fprintf('Aluminum %% (default: 20): ');
            alPctStr = input('', 's');
            if isempty(alPctStr)
                alPct = 20;
                fprintf('Using default value: 20%%\n');
            else
                alPct = str2double(alPctStr);
                if isnan(alPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            fprintf('Iron %% (default: 40): ');
            fePctStr = input('', 's');
            if isempty(fePctStr)
                fePct = 40;
                fprintf('Using default value: 40%%\n');
            else
                fePct = str2double(fePctStr);
                if isnan(fePct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            fprintf('Slag %% (default: 40): ');
            slagPctStr = input('', 's');
            if isempty(slagPctStr)
                slagPct = 40;
                fprintf('Using default value: 40%%\n');
            else
                slagPct = str2double(slagPctStr);
                if isnan(slagPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            totalPct = alPct + fePct + slagPct;
            
            % Allow total to be less than 100%
            if alPct >= 0 && fePct >= 0 && slagPct >= 0 && totalPct <= 100
                productionAllocation.sc = struct('aluminum', alPct/100, 'iron', fePct/100, 'slag', slagPct/100);
                fprintf('Total allocation: %.1f%% (%.1f%% resources reserved)\n', totalPct, 100-totalPct);
                
                % Calculate expected resource usage
                alUsage = min(tempInventory.aluminum, maxCastingThroughput * (alPct/100));
                feUsage = min(tempInventory.iron, maxCastingThroughput * (fePct/100));
                slagUsage = min(tempInventory.slag, maxCastingThroughput * (slagPct/100));
                
                % Update temporary inventory
                tempInventory.aluminum = tempInventory.aluminum - alUsage;
                tempInventory.iron = tempInventory.iron - feUsage;
                tempInventory.slag = tempInventory.slag - slagUsage;
                
                fprintf('\nEstimated resource usage:\n');
                fprintf('  - Aluminum: %.2f kg (%.2f kg remaining)\n', alUsage, tempInventory.aluminum);
                fprintf('  - Iron: %.2f kg (%.2f kg remaining)\n', feUsage, tempInventory.iron);
                fprintf('  - Slag: %.2f kg (%.2f kg remaining)\n', slagUsage, tempInventory.slag);
                
                break;
            else
                fprintf('Invalid input. Percentages must be non-negative and sum to less than or equal to 100%%\n');
            end
        end
    end
    
    % Permanent Casting allocation - UPDATED TO REMOVE IRON
    if obj.manufacturingPC.units > 0
        fprintf('\nPermanent Casting can process: aluminum, slag\n');
        fprintf('Available resources:\n');
        
        % Calculate theoretical throughput based on factory capacity
        maxCastingThroughput = obj.manufacturingPC.mass / obj.manufacturingPC.massScalingFactor * obj.simConfig.timeStepSize;
    
        % Calculate percentages with proper MATLAB syntax
        if maxCastingThroughput > 0
            alPercent = min(100, tempInventory.aluminum/maxCastingThroughput*100);
            slagPercent = min(100, tempInventory.slag/maxCastingThroughput*100);
        else
            alPercent = 0;
            slagPercent = 0;
        end
        
        fprintf('  - Aluminum: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.aluminum, maxCastingThroughput, alPercent);
        fprintf('  - Slag: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.slag, maxCastingThroughput, slagPercent);
        
        fprintf('\nEnter percentage allocation for each (must sum to 100%%):\n');
        
        while true
            fprintf('Aluminum %% (default: 60): ');
            alPctStr = input('', 's');
            if isempty(alPctStr)
                alPct = 60;  % Increased default since iron is removed
                fprintf('Using default value: 60%%\n');
            else
                alPct = str2double(alPctStr);
                if isnan(alPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            fprintf('Slag %% (default: 40): ');
            slagPctStr = input('', 's');
            if isempty(slagPctStr)
                slagPct = 40;  % Adjusted default since iron is removed
                fprintf('Using default value: 40%%\n');
            else
                slagPct = str2double(slagPctStr);
                if isnan(slagPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            totalPct = alPct + slagPct;
            
            % Must sum to exactly 100% for permanent casting
            if alPct >= 0 && slagPct >= 0 && totalPct == 100
                productionAllocation.pc = struct('aluminum', alPct/100, 'slag', slagPct/100);
                fprintf('Total allocation: %.1f%%\n', totalPct);
                
                % Calculate expected resource usage
                alUsage = min(tempInventory.aluminum, maxCastingThroughput * (alPct/100));
                slagUsage = min(tempInventory.slag, maxCastingThroughput * (slagPct/100));
                
                % Update temporary inventory
                tempInventory.aluminum = tempInventory.aluminum - alUsage;
                tempInventory.slag = tempInventory.slag - slagUsage;
                
                fprintf('\nEstimated resource usage:\n');
                fprintf('  - Aluminum: %.2f kg (%.2f kg remaining)\n', alUsage, tempInventory.aluminum);
                fprintf('  - Slag: %.2f kg (%.2f kg remaining)\n', slagUsage, tempInventory.slag);
                
                break;
            else
                fprintf('Invalid input. Percentages must be non-negative and sum to exactly 100%%\n');
            end
        end
    end
    
    % SSLS allocation
    if obj.manufacturingSSLS.mass > 0
        fprintf('\nSelective Solar Light Sinter can process: silica, alumina, regolith\n');
        fprintf('Available resources:\n');
        
        % Calculate theoretical throughput based on factory capacity
        hourlyCapacity = obj.manufacturingSSLS.mass / obj.manufacturingSSLS.massScalingFactor;
        % Apply power efficiency if needed
        if isfield(obj.manufacturingSSLS, 'allocatedPower')
            hourlyPowerNeeded = hourlyCapacity * obj.manufacturingSSLS.powerScalingFactor;
            totalEnergyRequired = hourlyPowerNeeded * obj.simConfig.timeStepSize;
            availableEnergy = obj.manufacturingSSLS.allocatedPower * obj.simConfig.timeStepSize;
            energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
            hourlyCapacity = hourlyCapacity * energyEfficiencyFactor;
        end
        % Calculate total capacity for the time step
        maxSinteringThroughput = hourlyCapacity * obj.simConfig.timeStepSize;
        
        % Show resource availability with usage percentages
        if maxSinteringThroughput > 0
            silicaPercent = min(100, tempInventory.silica/maxSinteringThroughput*100);
            aluminaPercent = min(100, tempInventory.alumina/maxSinteringThroughput*100);
            regolithPercent = min(100, tempInventory.regolith/maxSinteringThroughput*100);
        else
            silicaPercent = 0;
            aluminaPercent = 0;
            regolithPercent = 0;
        end
        
        fprintf('  - Silica: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.silica, maxSinteringThroughput, silicaPercent);
        fprintf('  - Alumina: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.alumina, maxSinteringThroughput, aluminaPercent);
        fprintf('  - Regolith: %.2f kg available (factory can process up to %.2f kg - resource meets %.1f%% of capacity)\n', ...
                tempInventory.regolith, maxSinteringThroughput, regolithPercent);
        
        fprintf('\nEnter percentage allocation for each (can sum to less than 100%%):\n');
        
        while true
            fprintf('Silica %% (default: 30): ');
            silicaPctStr = input('', 's');
            if isempty(silicaPctStr)
                silicaPct = 30;
                fprintf('Using default value: 30%%\n');
            else
                silicaPct = str2double(silicaPctStr);
                if isnan(silicaPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            fprintf('Alumina %% (default: 25): ');
            aluminaPctStr = input('', 's');
            if isempty(aluminaPctStr)
                aluminaPct = 25;
                fprintf('Using default value: 25%%\n');
            else
                aluminaPct = str2double(aluminaPctStr);
                if isnan(aluminaPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            fprintf('Regolith %% (default: 45): ');
            regolithPctStr = input('', 's');
            if isempty(regolithPctStr)
                regolithPct = 45;
                fprintf('Using default value: 45%%\n');
            else
                regolithPct = str2double(regolithPctStr);
                if isnan(regolithPct)
                    fprintf('Invalid input. Please enter a number.\n');
                    continue;
                end
            end
            
            totalPct = silicaPct + aluminaPct + regolithPct;
            
            % Allow total to be less than 100%
            if silicaPct >= 0 && aluminaPct >= 0 && regolithPct >= 0 && totalPct <= 100
                productionAllocation.ssls = struct('silica', silicaPct/100, 'alumina', aluminaPct/100, 'regolith', regolithPct/100);
                fprintf('Total allocation: %.1f%% (%.1f%% resources reserved)\n', totalPct, 100-totalPct);
                
                % Calculate expected resource usage
                silicaUsage = min(tempInventory.silica, maxSinteringThroughput * (silicaPct/100));
                aluminaUsage = min(tempInventory.alumina, maxSinteringThroughput * (aluminaPct/100));
                regolithUsage = min(tempInventory.regolith, maxSinteringThroughput * (regolithPct/100));
                
                % Update temporary inventory
                tempInventory.silica = tempInventory.silica - silicaUsage;
                tempInventory.alumina = tempInventory.alumina - aluminaUsage;
                tempInventory.regolith = tempInventory.regolith - regolithUsage;
                
                fprintf('\nEstimated resource usage:\n');
                fprintf('  - Silica: %.2f kg (%.2f kg remaining)\n', silicaUsage, tempInventory.silica);
                fprintf('  - Alumina: %.2f kg (%.2f kg remaining)\n', aluminaUsage, tempInventory.alumina);
                fprintf('  - Regolith: %.2f kg (%.2f kg remaining)\n', regolithUsage, tempInventory.regolith);
                
                break;
            else
                fprintf('Invalid input. Percentages must be non-negative and sum to less than or equal to 100%%\n');
            end
        end
    end
    
% EBPVD allocation section for getUserProductionAllocation with updated parameters
if obj.manufacturingEBPVD.mass > 0
    fprintf('\nThermal Vacuum Deposition creates solar thin films using aluminum, silicon, and silica.\n');
    fprintf('Solar thin films are essential components for solar panel production.\n');
    
    % Get configuration parameters for thin film components
    alThicknessFraction = obj.subConfig.manufacturingEBPVD.aluminumThicknessFraction;
    siThicknessFraction = obj.subConfig.manufacturingEBPVD.siliconThicknessFraction;
    silicaThicknessFraction = obj.subConfig.manufacturingEBPVD.silicaThicknessFraction;
    
    % Get deposition rates (kg/m²s)
    alDepRatePerSec = obj.subConfig.manufacturingEBPVD.aluminumDepositionRate;
    siDepRatePerSec = obj.subConfig.manufacturingEBPVD.siliconDepositionRate;
    silicaDepRatePerSec = obj.subConfig.manufacturingEBPVD.silicaDepositionRate;
    
    % Calculate equipment throughput capacity
    % Using mass scaling factor - determines how much solar thin film can be produced
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Use the appropriate mass scaling factor (Earth or Lunar manufactured)
    if obj.currentTimeStep <= 1
        massScalingFactor = obj.subConfig.manufacturingEBPVD.massScalingFactorEarth;
    else
        massScalingFactor = obj.subConfig.manufacturingEBPVD.massScalingFactorLunar;
    end
    
    % Calculate production capacity (kg/hr) based on equipment mass
    productionCapacity = obj.manufacturingEBPVD.mass / massScalingFactor;
    
    % Calculate power requirements based on power scaling factor
    powerRequired = productionCapacity * obj.subConfig.manufacturingEBPVD.powerScalingFactor;
    totalEnergyRequired = powerRequired * timeStepHours;
    
    if isfield(obj.manufacturingEBPVD, 'allocatedPower')
        availableEnergy = obj.manufacturingEBPVD.allocatedPower * timeStepHours;
    else
        % Default to 50% of required energy if no allocation is specified
        availableEnergy = totalEnergyRequired * 0.5;
    end
    
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Apply power efficiency to production capacity
    effectiveCapacity = productionCapacity * energyEfficiencyFactor;
    maxProduction = effectiveCapacity * timeStepHours;
    
    % Available resources
    alAvailable = tempInventory.aluminum;
    siAvailable = tempInventory.silicon;
    silicaAvailable = tempInventory.silica;
    
    % Calculate maximum thin film possible based on material limitations
    maxThinFilmByAl = alAvailable / alThicknessFraction;
    maxThinFilmBySi = siAvailable / siThicknessFraction;
    maxThinFilmBySilica = silicaAvailable / silicaThicknessFraction;
    maxThinFilmByMaterial = min([maxThinFilmByAl, maxThinFilmBySi, maxThinFilmBySilica]);
    
    % Limit by production capacity and material availability
    maxThinFilm = min(maxProduction, maxThinFilmByMaterial);
    
    % Apply 97% efficiency as specified in section 4.9
    potentialThinFilm = maxThinFilm * 0.97;
    
    % Calculate potential solar array metrics using thin film as component
    thinFilmMassFraction = obj.subConfig.powerLunarSolar.components.thinFilm.massFraction;
    potentialArrayMass = potentialThinFilm / thinFilmMassFraction;
    potentialArea = potentialArrayMass / obj.subConfig.powerLunarSolar.massPerArea;
    potentialPower = potentialArea * obj.envConfig.solarIllumination * obj.subConfig.powerLunarSolar.efficiency;
    
    fprintf('Available resources for EBPVD processing:\n');
    fprintf('  - Aluminum: %.2f kg available (%.2f kg needed at max capacity)\n', alAvailable, potentialThinFilm * alThicknessFraction);
    fprintf('  - Silicon: %.2f kg available (%.2f kg needed at max capacity)\n', siAvailable, potentialThinFilm * siThicknessFraction);
    fprintf('  - Silica: %.2f kg available (%.2f kg needed at max capacity)\n', silicaAvailable, potentialThinFilm * silicaThicknessFraction);
    
    fprintf('  - Production capacity: %.2f kg/hr (%.2f%% power efficiency)\n', effectiveCapacity, energyEfficiencyFactor * 100);
    fprintf('  - Can produce up to %.2f kg solar thin film\n', potentialThinFilm);
    fprintf('  - This could be used to create up to %.2f m² of solar panels\n', potentialArea);
    fprintf('  - Potential power generation: %.2f W\n', potentialPower);
    
    % Show limiting factor information
    if maxThinFilmByMaterial <= maxProduction
        limitingFactors = [maxThinFilmByAl, maxThinFilmBySi, maxThinFilmBySilica];
        [~, limitingIndex] = min(limitingFactors);
        
        if limitingIndex == 1
            fprintf('  - Aluminum is the limiting resource\n');
        elseif limitingIndex == 2
            fprintf('  - Silicon is the limiting resource\n');
        else
            fprintf('  - Silica is the limiting resource\n');
        end
    else
        fprintf('  - Production is limited by EBPVD equipment capacity (%.2f kg equipment mass)\n', obj.manufacturingEBPVD.mass);
        fprintf('  - Building more EBPVD equipment would increase production capacity\n');
    end
    
    fprintf('\nDo you want to activate EBPVD processing? (y/n, default: y): ');
    EBPVDStr = input('', 's');
    if isempty(EBPVDStr) || lower(EBPVDStr(1)) == 'y'
        productionAllocation.EBPVD = struct('active', true);
        fprintf('EBPVD processing activated.\n');
        
        % Ask for allocation percentage
        fprintf('Enter percentage of available resources to use (0-100, default: 100): ');
        EBPVDPctStr = input('', 's');
        if isempty(EBPVDPctStr)
            EBPVDPct = 100;
            fprintf('Using default value: 100%%\n');
        else
            EBPVDPct = str2double(EBPVDPctStr);
            if isnan(EBPVDPct) || EBPVDPct < 0 || EBPVDPct > 100
                fprintf('Invalid input. Using default of 100%%\n');
                EBPVDPct = 100;
            end
        end
        
        productionAllocation.EBPVD.percentage = EBPVDPct / 100;
        
        % Calculate expected resource usage
        thinFilmToMake = potentialThinFilm * (EBPVDPct/100);
        alNeeded = thinFilmToMake * alThicknessFraction;
        siNeeded = thinFilmToMake * siThicknessFraction;
        silicaNeeded = thinFilmToMake * silicaThicknessFraction;
        
        % Update temporary inventory
        tempInventory.aluminum = tempInventory.aluminum - alNeeded;
        tempInventory.silicon = tempInventory.silicon - siNeeded;
        tempInventory.silica = tempInventory.silica - silicaNeeded;
        
        fprintf('\nEstimated resource usage:\n');
        fprintf('  - Aluminum: %.2f kg (%.2f kg remaining)\n', alNeeded, tempInventory.aluminum);
        fprintf('  - Silicon: %.2f kg (%.2f kg remaining)\n', siNeeded, tempInventory.silicon);
        fprintf('  - Silica: %.2f kg (%.2f kg remaining)\n', silicaNeeded, tempInventory.silica);
        fprintf('  - Will produce: %.2f kg solar thin film\n', thinFilmToMake);
        
    else
        productionAllocation.EBPVD = struct('active', false);
        fprintf('EBPVD processing deactivated.\n');
    end
end
end

function executeProduction(obj, productionAllocation)
    % Fixed executeProduction function that ensures materials are available for assembly
    
    % 1. Execute extraction
    obj.executeExtraction();
    
    % 2. Execute processing operations
    obj.executeProcessing();
    
    % 3. Priority: Create cast iron if we don't have enough
    castIronNeeded = 1; % Minimum needed for basic assembly
    if obj.inventory.castIron < castIronNeeded && obj.inventory.iron > 0
        % Execute Sand Casting first to create cast iron
        if obj.manufacturingSC.mass > 0
            emergencyAllocation = struct();
            emergencyAllocation.iron = 0.05; % High priority on iron
            emergencyAllocation.aluminum = 0.05;
            emergencyAllocation.slag = 0.05;
            obj.executeSC(emergencyAllocation);
        end
    end
    
    % 4. Execute EBPVD if needed
    if isfield(productionAllocation, 'EBPVD') && productionAllocation.EBPVD.active
        EBPVDPercentage = productionAllocation.EBPVD.percentage;
        obj.executeEBPVD(EBPVDPercentage);
    elseif obj.manufacturingEBPVD.mass > 0
        obj.executeEBPVD(1.0);
    end
    
    % 5. Execute LPBF with material conservation
    if isfield(productionAllocation, 'lpbf')
        % Only give LPBF access to excess iron (after Sand Casting needs)
        if obj.inventory.iron > castIronNeeded
            obj.executeLPBF(productionAllocation.lpbf);
        else
            % Reduce iron allocation to preserve for Sand Casting
            conservativeAllocation = productionAllocation.lpbf;
            conservativeAllocation.iron = conservativeAllocation.iron * 0.2;
            obj.executeLPBF(conservativeAllocation);
        end
    end
    
    % 6. Execute remaining manufacturing processes
    
    % Sand Casting for normal operation
    if isfield(productionAllocation, 'sc') && obj.inventory.castIron < castIronNeeded*2
        obj.executeSC(productionAllocation.sc);
    end
    
    % Permanent Casting
    if isfield(productionAllocation, 'pc')
        obj.executePC(productionAllocation.pc);
    end
    
    % SSLS
    if isfield(productionAllocation, 'ssls')
        obj.executeSSLS(productionAllocation.ssls);
    end
end
function [shouldExecute, percentage] = geEBPVDUserDecision(obj)
    % Helper function to get user decision about EBPVD processing with updated parameters
    
    % Initialize return values
    shouldExecute = false;
    percentage = 1.0; % Default to 100%
    
    % Show information about EBPVD
    fprintf('\nThermal Vacuum Deposition creates solar thin films by combining aluminum, silicon, and silica.\n');
    fprintf('Solar thin films are used to create solar panels for power generation.\n');
    
    % Get configuration parameters for thin film components
    alThicknessFraction = obj.subConfig.manufacturingEBPVD.aluminumThicknessFraction;
    siThicknessFraction = obj.subConfig.manufacturingEBPVD.siliconThicknessFraction;
    silicaThicknessFraction = obj.subConfig.manufacturingEBPVD.silicaThicknessFraction;
    
    % Calculate equipment throughput capacity
    % Using mass scaling factor - determines how much solar thin film can be produced
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Use the appropriate mass scaling factor (Earth or Lunar manufactured)
    if obj.currentTimeStep <= 1
        massScalingFactor = obj.subConfig.manufacturingEBPVD.massScalingFactorEarth;
    else
        massScalingFactor = obj.subConfig.manufacturingEBPVD.massScalingFactorLunar;
    end
    
    % Calculate production capacity (kg/hr) based on equipment mass
    productionCapacity = obj.manufacturingEBPVD.mass / massScalingFactor;
    
    % Calculate power requirements based on power scaling factor
    powerRequired = productionCapacity * obj.subConfig.manufacturingEBPVD.powerScalingFactor;
    totalEnergyRequired = powerRequired * timeStepHours;
    
    if isfield(obj.manufacturingEBPVD, 'allocatedPower')
        availableEnergy = obj.manufacturingEBPVD.allocatedPower * timeStepHours;
    else
        % Default to 50% of required energy if no allocation is specified
        availableEnergy = totalEnergyRequired * 0.5;
    end
    
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Apply power efficiency to production capacity
    effectiveCapacity = productionCapacity * energyEfficiencyFactor;
    maxProduction = effectiveCapacity * timeStepHours;
    
    % Available resources
    alAvailable = obj.inventory.aluminum;
    siAvailable = obj.inventory.silicon;
    silicaAvailable = obj.inventory.silica;
    
    % Calculate maximum thin film possible based on material limitations
    maxThinFilmByAl = alAvailable / alThicknessFraction;
    maxThinFilmBySi = siAvailable / siThicknessFraction;
    maxThinFilmBySilica = silicaAvailable / silicaThicknessFraction;
    maxThinFilmByMaterial = min([maxThinFilmByAl, maxThinFilmBySi, maxThinFilmBySilica]);
    
    % Limit by production capacity and material availability
    maxThinFilm = min(maxProduction, maxThinFilmByMaterial);
    
    % Apply 97% efficiency as specified in section 4.9
    potentialThinFilm = maxThinFilm * 0.97;
    
    % Calculate potential solar array metrics using thin film as component
    thinFilmMassFraction = obj.subConfig.powerLunarSolar.components.thinFilm.massFraction;
    potentialArrayMass = potentialThinFilm / thinFilmMassFraction;
    potentialArea = potentialArrayMass / obj.subConfig.powerLunarSolar.massPerArea;
    potentialPower = potentialArea * obj.envConfig.solarIllumination * obj.subConfig.powerLunarSolar.efficiency;
    
    % Display available resources
    fprintf('Available resources:\n');
    fprintf('  - Aluminum: %.2f kg available (%.2f kg needed for max production)\n', alAvailable, potentialThinFilm * alThicknessFraction);
    fprintf('  - Silicon: %.2f kg available (%.2f kg needed for max production)\n', siAvailable, potentialThinFilm * siThicknessFraction);
    fprintf('  - Silica: %.2f kg available (%.2f kg needed for max production)\n', silicaAvailable, potentialThinFilm * silicaThicknessFraction);
    
    % Show equipment-limited production capacity
    fprintf('  - Production capacity: %.2f kg/hr (%.2f%% power efficiency)\n', effectiveCapacity, energyEfficiencyFactor * 100);
    fprintf('  - Can produce up to %.2f kg solar thin film\n', potentialThinFilm);
    fprintf('  - This could be used to create up to %.2f m² of solar panels\n', potentialArea);
    fprintf('  - Potential power generation: %.2f W\n', potentialPower);
    
    % Show limiting factor information
    if maxThinFilmByMaterial <= maxProduction
        limitingFactors = [maxThinFilmByAl, maxThinFilmBySi, maxThinFilmBySilica];
        [~, limitingIndex] = min(limitingFactors);
        
        if limitingIndex == 1
            fprintf('  - Aluminum is the limiting resource\n');
        elseif limitingIndex == 2
            fprintf('  - Silicon is the limiting resource\n');
        else
            fprintf('  - Silica is the limiting resource\n');
        end
    else
        fprintf('  - Production is limited by EBPVD equipment capacity (%.2f kg equipment mass)\n', obj.manufacturingEBPVD.mass);
        fprintf('  - Building more EBPVD equipment would increase production capacity\n');
    end
    
    % Ask if user wants to activate EBPVD processing
    fprintf('\nDo you want to activate EBPVD processing? (y/n, default: y): ');
    EBPVDStr = input('', 's');
    if isempty(EBPVDStr) || lower(EBPVDStr(1)) == 'y'
        shouldExecute = true;
        
        % Ask for allocation percentage
        fprintf('Enter percentage of available resources to use (0-100, default: 100): ');
        EBPVDPctStr = input('', 's');
        if isempty(EBPVDPctStr)
            percentage = 1.0; % 100%
            fprintf('Using default value: 100%%\n');
        else
            EBPVDPct = str2double(EBPVDPctStr);
            if isnan(EBPVDPct) || EBPVDPct < 0 || EBPVDPct > 100
                fprintf('Invalid input. Using default of 100%%\n');
                percentage = 1.0;
            else
                percentage = EBPVDPct / 100;
            end
        end
    else
        fprintf('EBPVD processing deactivated.\n');
    end
end

function displayInventory(obj)
            % Display current inventory
            fprintf('\nCurrent Inventory:\n');
            
            materials = fieldnames(obj.inventory);
            for i = 1:length(materials)
                if obj.inventory.(materials{i}) > 0
                    fprintf('  %s: %.2f kg\n', materials{i}, obj.inventory.(materials{i}));
                end
            end
        end
        
        function assemblyDecisions = getUserAssemblyDecisions(obj)
    % Flag to track if we have valid assembly decisions
    validAssembly = false;
    maxAttempts = 3;  % Limit number of attempts to avoid infinite loops
    attempt = 0;
    
    while ~validAssembly && attempt < maxAttempts
        attempt = attempt + 1;
        
        if attempt > 1
            fprintf('\nAttempt %d of %d to create valid assembly plan...\n', attempt, maxAttempts);
        end
        
        % Calculate maximum assembly capacity
        basicCapacity = obj.assembly.units * obj.assembly.assemblyCapacity * obj.simConfig.timeStepSize;
        hourlyPowerNeeded = obj.assembly.units * obj.assembly.powerPerUnit;
        totalEnergyRequired = hourlyPowerNeeded * obj.simConfig.timeStepSize;
        availableEnergy = obj.assembly.allocatedPower * obj.simConfig.timeStepSize;
        energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
        maxCapacity = basicCapacity * energyEfficiencyFactor;
        
        fprintf('\n===== ASSEMBLY CAPACITY =====\n');
        fprintf('Assembly units: %d\n', obj.assembly.units);
        fprintf('Per-unit capacity: %.2f kg/hr\n', obj.assembly.assemblyCapacity);
        fprintf('Energy efficiency: %.1f%%\n', energyEfficiencyFactor * 100);
        fprintf('Maximum assembly capacity for this time step: %.2f kg\n', maxCapacity);
        fprintf('=============================\n\n');

        fprintf('Enter mass to assemble for each subsystem (kg):\n');
        fprintf('(Press Enter for default value of 0 kg)\n');
        
        % Initialize assembly decisions
        assemblyDecisions = struct();
        totalAssembly = 0;
        
        % Include Sand Casting in buildable subsystems
        buildableSubsystems = {'extraction', 'processingMRE', 'processingHCl', 'processingVP', ...
            'manufacturingLPBF', 'manufacturingEBPVD', 'manufacturingSC', 'manufacturingPC', 'manufacturingSSLS', ...
            'assembly', 'powerLunarSolar'};
        
        % Get user input for each subsystem
        for i = 1:length(buildableSubsystems)
            subsystem = buildableSubsystems{i};
            [canBuild, maxUnits, requiredMaterials] = obj.checkBuildRequirements(subsystem);
            
            if canBuild
                fprintf('%s (max %.2f kg): ', subsystem, maxUnits * requiredMaterials.total);
                massStr = input('', 's');
                
                if isempty(massStr)
                    mass = 0;
                    fprintf('Using default value: 0 kg\n');
                else
                    mass = str2double(massStr);
                    if isnan(mass)
                        fprintf('Invalid input. Please enter a number.\n');
                        mass = 0;
                    end
                end
                
                % Validate input for this subsystem
                if mass >= 0 && mass <= maxUnits * requiredMaterials.total && totalAssembly + mass <= maxCapacity
                    assemblyDecisions.(subsystem) = mass;
                    totalAssembly = totalAssembly + mass;
                else
                    fprintf('Invalid input. Mass must be between 0 and %.2f kg, and total assembly cannot exceed %.2f kg\n', ...
                        maxUnits * requiredMaterials.total, maxCapacity);
                    assemblyDecisions.(subsystem) = 0;
                end
            else
                fprintf('%s: Cannot build (insufficient materials)\n', subsystem);
                assemblyDecisions.(subsystem) = 0;
            end
        end
        
        fprintf('Total assembly: %.2f kg (%.1f%% of capacity)\n', totalAssembly, totalAssembly/maxCapacity*100);
        
        % Validate the combined resource requirements
        [valid, resourceIssues] = validateTotalResourceRequirements(obj, assemblyDecisions);
        
        if valid
            validAssembly = true;
            fprintf('\nAssembly plan is valid! Processing...\n');
        else
            fprintf('\n⚠️ WARNING: Your assembly plan requires more resources than available:\n');
            for i = 1:length(resourceIssues)
                fprintf('  - %s\n', resourceIssues{i});
            end
            
            % Ask if user wants to try again or cancel
            if attempt < maxAttempts
                fprintf('\nWould you like to adjust your assembly decisions? (y/n): ');
                response = input('', 's');
                if isempty(response) || lower(response(1)) ~= 'y'
                    fprintf('Assembly cancelled. No units will be built.\n');
                    assemblyDecisions = struct();
                    break;
                end
            else
                fprintf('\nReached maximum attempts. Assembly cancelled.\n');
                assemblyDecisions = struct();
                break;
            end
        end
    end
        end


        function [valid, errorMessages] = validateTotalResourceRequirements(obj, assemblyDecisions)
    % Validate that the total resources required for all subsystems don't exceed available resources
    valid = true;
    errorMessages = {};
    
    % Calculate total material requirements across all subsystems
    totalMaterialNeeds = struct();
    subsystems = fieldnames(assemblyDecisions);
    
    % First pass - calculate total material requirements
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        massToAssemble = assemblyDecisions.(subsystem);
        
        if massToAssemble > 0
            % Calculate how many units this mass represents
            [~, ~, requiredMaterials] = obj.checkBuildRequirements(subsystem);
            unitsToBuild = massToAssemble / requiredMaterials.total;
            
            % Sum up required materials by type
            materials = fieldnames(requiredMaterials);
            for j = 1:length(materials)
                materialType = materials{j};
                if ~strcmp(materialType, 'total')
                    amount = requiredMaterials.(materialType) * unitsToBuild;
                    
                    % Add to total requirements
                    if isfield(totalMaterialNeeds, materialType)
                        totalMaterialNeeds.(materialType) = totalMaterialNeeds.(materialType) + amount;
                    else
                        totalMaterialNeeds.(materialType) = amount;
                    end
                end
            end
        end
    end
    
    % Verify all material requirements can be met
    materialFields = fieldnames(totalMaterialNeeds);
    for i = 1:length(materialFields)
        materialType = materialFields{i};
        requiredAmount = totalMaterialNeeds.(materialType);
        
        % Check if we have enough of this material
        if isfield(obj.inventory, materialType)
            availableAmount = obj.inventory.(materialType);
            if availableAmount < requiredAmount
                valid = false;
                errorMsg = sprintf('Insufficient %s: %.2f kg needed, %.2f kg available', ...
                                  materialType, requiredAmount, availableAmount);
                errorMessages{end+1} = errorMsg;
            end
        else
            valid = false;
            errorMessages{end+1} = sprintf('Material %s not found in inventory', materialType);
        end
    end
    
    return;
end

function executeAssembly(obj, assemblyDecisions)
    % Execute assembly with strict physical constraints that prevent subsystem mass reduction
    % with additional debugging and fixes to ensure actual growth occurs
    
    % Store initial masses for all subsystems to enforce non-decreasing constraint
    initialMasses = struct();
    initialMasses.extraction = obj.extraction.mass;
    initialMasses.processingMRE = obj.processingMRE.mass;
    initialMasses.processingHCl = obj.processingHCl.mass;
    initialMasses.processingVP = obj.processingVP.mass;
    initialMasses.manufacturingLPBF = obj.manufacturingLPBF.mass;
    initialMasses.manufacturingEBPVD = obj.manufacturingEBPVD.mass;
    initialMasses.manufacturingSC = obj.manufacturingSC.mass;
    initialMasses.manufacturingPC = obj.manufacturingPC.mass;
    initialMasses.manufacturingSSLS = obj.manufacturingSSLS.mass;
    initialMasses.assembly = obj.assembly.mass;
    initialMasses.powerLandedSolar = obj.powerLandedSolar.mass;
    initialMasses.powerLunarSolar = obj.powerLunarSolar.mass;
    
    % Skip if no assembly decisions provided
    if isempty(fieldnames(assemblyDecisions))
        fprintf('No assembly decisions provided. Skipping assembly process.\n');
        return;
    end
    
    % Initialize tracking variables for resource consumption
    resourcesConsumed = struct();
    fields = fieldnames(obj.inventory);
    for i = 1:length(fields)
        resourcesConsumed.(fields{i}) = 0;
    end
    
    % DEBUG: Print assembly decisions
    fprintf('\n===== ASSEMBLY DECISIONS =====\n');
    totalPlannedAssembly = 0;
    subsystems = fieldnames(assemblyDecisions);
    for i = 1:length(subsystems)
        if assemblyDecisions.(subsystems{i}) > 0
            fprintf('Plan to build %.2f kg of %s\n', assemblyDecisions.(subsystems{i}), subsystems{i});
            totalPlannedAssembly = totalPlannedAssembly + assemblyDecisions.(subsystems{i});
        end
    end
    fprintf('Total planned assembly: %.2f kg\n', totalPlannedAssembly);
    
    % Track resource requirements for the planned assembly
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        massToAssemble = assemblyDecisions.(subsystem);
        
        if massToAssemble > 0
            % Get build requirements for this subsystem
            [canBuild, ~, requiredMaterials] = obj.checkBuildRequirements(subsystem);
            
            if ~canBuild
                fprintf('WARNING: %s was marked for assembly but canBuild=false\n', subsystem);
                continue;
            end
            
            unitsToBuild = massToAssemble / requiredMaterials.total;
            
            if unitsToBuild <= 0
                fprintf('WARNING: Invalid units to build for %s: %.4f\n', subsystem, unitsToBuild);
                continue;
            end
            
            % Track resources needed for this assembly
            materials = fieldnames(requiredMaterials);
            fprintf('Material requirements for %s (%.2f units):\n', subsystem, unitsToBuild);
            
            for j = 1:length(materials)
                materialType = materials{j};
                if ~strcmp(materialType, 'total')
                    amount = requiredMaterials.(materialType) * unitsToBuild;
                    fprintf('- Needs %.2f kg of %s\n', amount, materialType);
                    
                    if isfield(resourcesConsumed, materialType)
                        resourcesConsumed.(materialType) = resourcesConsumed.(materialType) + amount;
                    else
                        resourcesConsumed.(materialType) = amount;
                    end
                end
            end
        end
    end
    
    % Verify that all required resources are available
    canBuild = true;
    fprintf('\nResource verification:\n');
    for field = fieldnames(resourcesConsumed)'
        material = field{1};
        if isfield(obj.inventory, material) && resourcesConsumed.(material) > 0
            if obj.inventory.(material) < resourcesConsumed.(material)
                fprintf('INSUFFICIENT %s: %.2f kg needed, only %.2f kg available\n', ...
                    material, resourcesConsumed.(material), obj.inventory.(material));
                canBuild = false;
            else
                fprintf('SUFFICIENT %s: %.2f kg needed, %.2f kg available\n', ...
                    material, resourcesConsumed.(material), obj.inventory.(material));
            end
        end
    end
    
    if ~canBuild
        fprintf('Cannot execute assembly plan due to resource constraints.\n');
        
        % CRITICAL FIX: Try to build partial components if possible
        fprintf('Attempting to build partial components...\n');
        [partialAssembly, wasSuccessful] = buildPartialComponents(obj, assemblyDecisions, resourcesConsumed);
        
        if wasSuccessful
            fprintf('Successfully created partial assembly plan.\n');
            executeAssembly(obj, partialAssembly); % Recursively call with modified plan
        else
            fprintf('Failed to create viable partial assembly plan.\n');
        end
        
        return;
    end
    
    % CRITICAL FIX: Check if assembly capacity is available based on power allocation
    basicCapacity = obj.assembly.units * obj.assembly.assemblyCapacity * obj.simConfig.timeStepSize;
    hourlyPowerNeeded = obj.assembly.units * obj.assembly.powerPerUnit;
    totalEnergyRequired = hourlyPowerNeeded * obj.simConfig.timeStepSize;
    
    if isfield(obj.assembly, 'allocatedPower')
        availableEnergy = obj.assembly.allocatedPower * obj.simConfig.timeStepSize;
    else
        fprintf('WARNING: assembly.allocatedPower not set, assuming 50%% efficiency\n');
        availableEnergy = totalEnergyRequired * 0.5;
    end
    
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    maxCapacity = basicCapacity * energyEfficiencyFactor;
    
    if totalPlannedAssembly > maxCapacity * 1.05 % Allow 5% margin
        fprintf('WARNING: Planned assembly exceeds capacity (%.2f > %.2f)\n', totalPlannedAssembly, maxCapacity);
        fprintf('Scaling down assembly to fit within capacity.\n');
        
        % Scale down all subsystems proportionally
        scaleFactor = maxCapacity / totalPlannedAssembly;
        for i = 1:length(subsystems)
            assemblyDecisions.(subsystems{i}) = assemblyDecisions.(subsystems{i}) * scaleFactor;
        end
        
        % Recalculate resource requirements
        resourcesConsumed = struct();
        for i = 1:length(fields)
            resourcesConsumed.(fields{i}) = 0;
        end
        
        for i = 1:length(subsystems)
            subsystem = subsystems{i};
            massToAssemble = assemblyDecisions.(subsystem);
            
            if massToAssemble > 0
                [~, ~, requiredMaterials] = obj.checkBuildRequirements(subsystem);
                unitsToBuild = massToAssemble / requiredMaterials.total;
                
                materials = fieldnames(requiredMaterials);
                for j = 1:length(materials)
                    materialType = materials{j};
                    if ~strcmp(materialType, 'total')
                        amount = requiredMaterials.(materialType) * unitsToBuild;
                        if isfield(resourcesConsumed, materialType)
                            resourcesConsumed.(materialType) = resourcesConsumed.(materialType) + amount;
                        else
                            resourcesConsumed.(materialType) = amount;
                        end
                    end
                end
            end
        end
    end
    
    % Consume materials from inventory with validation
    fprintf('\nConsuming materials from inventory:\n');
    for field = fieldnames(resourcesConsumed)'
        material = field{1};
        if isfield(obj.inventory, material) && resourcesConsumed.(material) > 0
            initialAmount = obj.inventory.(material);
            obj.inventory.(material) = obj.inventory.(material) - resourcesConsumed.(material);
            
            fprintf('- %s: %.2f kg → %.2f kg (used %.2f kg)\n', ...
                material, initialAmount, obj.inventory.(material), resourcesConsumed.(material));
            
            % Sanity check - prevent negative inventory
            if obj.inventory.(material) < 0
                fprintf('ERROR: Negative inventory for %s corrected to 0\n', material);
                obj.inventory.(material) = 0;
            end
        end
    end
    
    % Execute assembly for each subsystem
    fprintf('\n===== EXECUTING ASSEMBLY =====\n');
    totalAssembled = 0;
    
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        massToAssemble = assemblyDecisions.(subsystem);
        
        if massToAssemble > 0
            % Calculate how many units this mass represents
            [~, ~, requiredMaterials] = obj.checkBuildRequirements(subsystem);
            unitsToBuild = massToAssemble / requiredMaterials.total;
            
            % CRITICAL FIX: Ensure we're building at least a minimal amount
            if unitsToBuild < 0.001
                fprintf('WARNING: Very small unit build quantity for %s: %.6f, rounding up\n', ...
                    subsystem, unitsToBuild);
                unitsToBuild = 0.001; % Minimum build quantity to ensure some progress
            end
            
            % Add new units to subsystem - ensuring mass never decreases
            switch subsystem
                case 'extraction'
                    obj.extraction.units = obj.extraction.units + unitsToBuild;
                    obj.extraction.mass = max(obj.extraction.mass + massToAssemble, initialMasses.extraction);
                case 'processingMRE'
                    obj.processingMRE.units = obj.processingMRE.units + unitsToBuild;
                    obj.processingMRE.mass = max(obj.processingMRE.mass + massToAssemble, initialMasses.processingMRE);
                    % Update total oxygen production based on per-unit value
                    obj.processingMRE.oxygenPerYear = obj.processingMRE.oxygenPerUnitPerYear * obj.processingMRE.units;
                case 'processingHCl'
                    obj.processingHCl.units = obj.processingHCl.units + unitsToBuild;
                    obj.processingHCl.mass = max(obj.processingHCl.mass + massToAssemble, initialMasses.processingHCl);
                case 'processingVP'
                    obj.processingVP.units = obj.processingVP.units + unitsToBuild;
                    obj.processingVP.mass = max(obj.processingVP.mass + massToAssemble, initialMasses.processingVP);
                case 'manufacturingLPBF'
                    obj.manufacturingLPBF.units = obj.manufacturingLPBF.units + unitsToBuild;
                    obj.manufacturingLPBF.mass = max(obj.manufacturingLPBF.mass + massToAssemble, initialMasses.manufacturingLPBF);
                case 'manufacturingEBPVD'
                    obj.manufacturingEBPVD.units = obj.manufacturingEBPVD.units + unitsToBuild;
                    obj.manufacturingEBPVD.mass = max(obj.manufacturingEBPVD.mass + massToAssemble, initialMasses.manufacturingEBPVD);
                case 'manufacturingSC'
                    obj.manufacturingSC.units = obj.manufacturingSC.units + unitsToBuild;
                    obj.manufacturingSC.mass = max(obj.manufacturingSC.mass + massToAssemble, initialMasses.manufacturingSC);
                case 'manufacturingPC'
                    obj.manufacturingPC.units = obj.manufacturingPC.units + unitsToBuild;
                    obj.manufacturingPC.mass = max(obj.manufacturingPC.mass + massToAssemble, initialMasses.manufacturingPC);
                case 'manufacturingSSLS'
                    obj.manufacturingSSLS.units = obj.manufacturingSSLS.units + unitsToBuild;
                    obj.manufacturingSSLS.mass = max(obj.manufacturingSSLS.mass + massToAssemble, initialMasses.manufacturingSSLS);
                case 'assembly'
                    obj.assembly.units = obj.assembly.units + unitsToBuild;
                    obj.assembly.mass = max(obj.assembly.mass + massToAssemble, initialMasses.assembly);
                case 'powerLunarSolar'
                    % CRITICAL FIX: Special handling for lunar solar power
                    additionalArea = massToAssemble / obj.subConfig.powerLunarSolar.massPerArea;
                    fprintf('Adding %.2f m² of lunar solar panels\n', additionalArea);
                    
                    % Update area and mass 
                    obj.powerLunarSolar.area = obj.powerLunarSolar.area + additionalArea;
                    obj.powerLunarSolar.mass = max(obj.powerLunarSolar.mass + massToAssemble, initialMasses.powerLunarSolar);
                    
                    % Recalculate power capacity
                    newCapacity = obj.powerLunarSolar.area * obj.envConfig.solarIllumination * obj.powerLunarSolar.efficiency;
                    capacityIncrease = newCapacity - obj.powerLunarSolar.capacity;
                    
                    obj.powerLunarSolar.capacity = newCapacity;
                    
                    % Additional debug output for power
                    fprintf('  - Added %.2f m² of solar panels providing %.2f W capacity (%.2f W increase)\n', additionalArea, newCapacity, capacityIncrease);
            end
            
            fprintf('Built %.2f kg of %s (%.4f units)\n', massToAssemble, subsystem, unitsToBuild);
            totalAssembled = totalAssembled + massToAssemble;
        end
    end
    
    % CRITICAL FIX: Recalculate total mass after assembly
    newTotalMass = obj.calculateTotalMass();
    massDifference = newTotalMass - obj.totalMass;
    
    fprintf('\nMass change: %.2f kg → %.2f kg (%.2f kg increase, %.2f%% growth)\n', ...
            obj.totalMass, newTotalMass, massDifference, (massDifference/obj.totalMass)*100);
    
    if abs(massDifference - totalAssembled) > 0.01
        fprintf('WARNING: Mass accounting discrepancy: %.2f kg assembled vs %.2f kg mass increase\n', ...
                totalAssembled, massDifference);
    end
    
    % CRITICAL FIX: Recalculate power capacity after assembly
    oldPowerCapacity = obj.powerCapacity;
    obj.calculatePowerCapacity();
    powerIncrease = obj.powerCapacity - oldPowerCapacity;
    
    fprintf('Power capacity change: %.2f W → %.2f W (%.2f W increase, %.2f%%)\n', ...
            oldPowerCapacity, obj.powerCapacity, powerIncrease, (powerIncrease/oldPowerCapacity)*100);
            
    fprintf('===================================\n\n');
end

function [partialAssembly, success] = buildPartialComponents(factory, originalAssembly, resourceNeeds)
    % Create a partial assembly plan based on available resources
    partialAssembly = struct();
    success = false;
    
    % Check what fraction of each resource is available
    availabilityRatios = [];
    for field = fieldnames(resourceNeeds)'
        material = field{1};
        if isfield(factory.inventory, material) && resourceNeeds.(material) > 0
            ratio = factory.inventory.(material) / resourceNeeds.(material);
            availabilityRatios(end+1) = ratio;
        end
    end
    
    if isempty(availabilityRatios)
        return;  % No valid ratios found
    end
    
    % Find smallest ratio (most constrained resource)
    scaleFactor = min(availabilityRatios) * 0.95;  % 5% safety margin
    
    if scaleFactor < 0.01
        fprintf('Resource constraint too severe (%.2f%% of required). Aborting.\n', scaleFactor*100);
        return;
    end
    
    fprintf('Creating partial assembly plan at %.1f%% of original\n', scaleFactor*100);
    
    % Scale down all assembly decisions
    subsystems = fieldnames(originalAssembly);
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        partialAssembly.(subsystem) = originalAssembly.(subsystem) * scaleFactor;
        
        % Ensure we're building something meaningful
        if partialAssembly.(subsystem) < 1.0
            fprintf('WARNING: Scaled assembly for %s too small (%.2f kg), removing\n', ...
                    subsystem, partialAssembly.(subsystem));
            partialAssembly = rmfield(partialAssembly, subsystem);
        else
            fprintf('Scaled assembly for %s: %.2f kg → %.2f kg\n',...
                    subsystem, originalAssembly.(subsystem), partialAssembly.(subsystem));
        end
    end
    
    if ~isempty(fieldnames(partialAssembly))
        success = true;
    end
end
function shouldAttempt = shouldAttemptPartialAssembly(errorMessages)
    % Simple fallback implementation that avoids any parsing
    % Always returns true to attempt partial assembly
    % This is a safe fallback that will at least allow the simulation to continue
    
    % Instead of trying to parse error messages, just check how many shortages we have
    numShortages = length(errorMessages);
    
    % If we have a lot of shortages, don't attempt partial assembly
    % Otherwise, try partial assembly
    if numShortages > 5
        shouldAttempt = false;
    else
        shouldAttempt = true;
    end
    
    % Print debug info
    fprintf('Fallback shouldAttemptPartialAssembly: %d shortages, returning %d\n', ...
            numShortages, shouldAttempt);
end

function scaledDecisions = scaleDownAssemblyDecisions(decisions, materialNeeds, inventory)
    % Scale down assembly decisions to fit available materials
    scaledDecisions = decisions;
    
    % Calculate overall scaling factor based on material shortages
    scalingFactors = [];
    materials = fieldnames(materialNeeds);
    
    for i = 1:length(materials)
        material = materials{i};
        if isfield(inventory, material) && inventory.(material) > 0
            needed = materialNeeds.(material);
            available = inventory.(material);
            
            if needed > available
                % Calculate what fraction of the needed material is available
                factor = available / needed;
                scalingFactors(end+1) = factor;
            end
        end
    end
    
    % Use the smallest scaling factor (most constrained resource)
    if ~isempty(scalingFactors)
        overallFactor = min(scalingFactors);
        
        % Apply a safety margin to prevent rounding issues
        overallFactor = overallFactor * 0.95;
        
        % Scale down all assembly decisions
        subsystems = fieldnames(decisions);
        for i = 1:length(subsystems)
            subsystem = subsystems{i};
            scaledDecisions.(subsystem) = decisions.(subsystem) * overallFactor;
        end
    end
    
    return;
end

function [isValid, updatedNeeds] = validateScaledDecisions(decisions, factory)
    % Validate that scaled decisions don't exceed available resources
    isValid = true;
    updatedNeeds = struct();
    
    % Calculate total resource requirements
    subsystems = fieldnames(decisions);
    
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        massToAssemble = decisions.(subsystem);
        
        if massToAssemble > 0
            % Calculate how many units this mass represents
            [~, ~, requiredMaterials] = factory.checkBuildRequirements(subsystem);
            unitsToBuild = massToAssemble / requiredMaterials.total;
            
            % Add up required materials
            materials = fieldnames(requiredMaterials);
            for j = 1:length(materials)
                materialType = materials{j};
                if ~strcmp(materialType, 'total')
                    amount = requiredMaterials.(materialType) * unitsToBuild;
                    
                    % Add to total requirements
                    if isfield(updatedNeeds, materialType)
                        updatedNeeds.(materialType) = updatedNeeds.(materialType) + amount;
                    else
                        updatedNeeds.(materialType) = amount;
                    end
                end
            end
        end
    end
    
    % Check if requirements can be met
    materials = fieldnames(updatedNeeds);
    for i = 1:length(materials)
        material = materials{i};
        needed = updatedNeeds.(material);
        
        if isfield(factory.inventory, material)
            available = factory.inventory.(material);
            if needed > available
                isValid = false;
                break;
            end
        else
            isValid = false;
            break;
        end
    end
    
    return;
end   

% Here are the complete implementations for the missing functions:
function recordMetrics(obj, step)
    % Record performance metrics for the given time step
    
    % Performance metrics
    obj.metrics.totalMass(step) = obj.totalMass;
    obj.metrics.powerCapacity(step) = obj.powerCapacity;
    obj.metrics.powerDemand(step) = obj.powerDemand;
    
    % Growth metrics
    if step > 1
        prevMass = obj.metrics.totalMass(step - 1);
        obj.metrics.monthlyGrowthRate(step) = (obj.totalMass / prevMass) - 1;
        obj.metrics.annualGrowthRate(step) = (1 + obj.metrics.monthlyGrowthRate(step))^(24*365/obj.simConfig.timeStepSize) - 1;
    else
        obj.metrics.monthlyGrowthRate(step) = 0;
        obj.metrics.annualGrowthRate(step) = 0;
    end
    
    obj.metrics.replicationFactor(step) = obj.totalMass / obj.simConfig.initialLandedMass;

    % Record subsystem masses at each time step
    if ~isfield(obj.metrics, 'subsystemMasses') || size(obj.metrics.subsystemMasses, 1) < obj.simConfig.numTimeSteps
        % Initialize or resize the subsystemMasses matrix if needed
        obj.metrics.subsystemMasses = zeros(obj.simConfig.numTimeSteps, 12); % Added space for Sand Casting
    end
    
    % Collect mass from each subsystem
    subsystemMasses = zeros(1, 12); 
    subsystemMasses(1) = obj.extraction.mass;
    subsystemMasses(2) = obj.processingMRE.mass;
    subsystemMasses(3) = obj.processingHCl.mass;
    subsystemMasses(4) = obj.processingVP.mass;
    subsystemMasses(5) = obj.manufacturingLPBF.mass;
    subsystemMasses(6) = obj.manufacturingEBPVD.mass;
    subsystemMasses(7) = obj.manufacturingSC.mass; % Added Sand Casting
    subsystemMasses(8) = obj.manufacturingPC.mass;
    subsystemMasses(9) = obj.manufacturingSSLS.mass;
    subsystemMasses(10) = obj.assembly.mass;
    subsystemMasses(11) = obj.powerLandedSolar.mass;
    subsystemMasses(12) = obj.powerLunarSolar.mass;
    
    obj.metrics.subsystemMasses(step, :) = subsystemMasses;
    
    % Record power allocation for each subsystem
    if ~isfield(obj.metrics, 'subsystemPower') || size(obj.metrics.subsystemPower, 1) < obj.simConfig.numTimeSteps
        % Initialize subsystemPower field if it doesn't exist
        powerDistFields = fieldnames(obj.powerDistribution);
        obj.metrics.subsystemPower = zeros(obj.simConfig.numTimeSteps, length(powerDistFields));
    end

    % Store allocated power for each subsystem
    powerDistFields = fieldnames(obj.powerDistribution);
    allocatedPower = zeros(1, length(powerDistFields));
    
    for i = 1:length(powerDistFields)
        field = powerDistFields{i};
        if isfield(obj, field) && isfield(obj.(field), 'allocatedPower')
            allocatedPower(i) = obj.(field).allocatedPower;
        else
            % If no allocatedPower is found, use powerDistribution as fallback
            allocatedPower(i) = obj.powerDistribution.(field) * obj.powerCapacity;
        end
    end
    
    obj.metrics.subsystemPower(step, :) = allocatedPower;
            
    % Material flow metrics
    obj.metrics.materialFlows.regolith(step) = obj.inventory.regolith;
    obj.metrics.materialFlows.oxygen(step) = obj.inventory.oxygen;
    obj.metrics.materialFlows.iron(step) = obj.inventory.iron;
    obj.metrics.materialFlows.silicon(step) = obj.inventory.silicon;
    obj.metrics.materialFlows.aluminum(step) = obj.inventory.aluminum;
    obj.metrics.materialFlows.slag(step) = obj.inventory.slag;
    obj.metrics.materialFlows.silica(step) = obj.inventory.silica;
    obj.metrics.materialFlows.alumina(step) = obj.inventory.alumina;
    
    % Manufactured material flow metrics
    if isfield(obj.inventory, 'castAluminum')
        obj.metrics.materialFlows.castAluminum(step) = obj.inventory.castAluminum;
    end
    if isfield(obj.inventory, 'castIron')
        obj.metrics.materialFlows.castIron(step) = obj.inventory.castIron;
    end
    if isfield(obj.inventory, 'castSlag')
        obj.metrics.materialFlows.castSlag(step) = obj.inventory.castSlag;
    end
    if isfield(obj.inventory, 'precisionAluminum')
        obj.metrics.materialFlows.precisionAluminum(step) = obj.inventory.precisionAluminum;
    end
    if isfield(obj.inventory, 'precisionIron')
        obj.metrics.materialFlows.precisionIron(step) = obj.inventory.precisionIron;
    end
    if isfield(obj.inventory, 'precisionAlumina')
        obj.metrics.materialFlows.precisionAlumina(step) = obj.inventory.precisionAlumina;
    end
    if isfield(obj.inventory, 'sinteredAlumina')
        obj.metrics.materialFlows.sinteredAlumina(step) = obj.inventory.sinteredAlumina;
    end
    if isfield(obj.inventory, 'silicaGlass')
        obj.metrics.materialFlows.silicaGlass(step) = obj.inventory.silicaGlass;
    end
    if isfield(obj.inventory, 'sinteredRegolith')
        obj.metrics.materialFlows.sinteredRegolith(step) = obj.inventory.sinteredRegolith;
    end
    if isfield(obj.inventory, 'solarThinFilm')
        obj.metrics.materialFlows.solarThinFilm(step) = obj.inventory.solarThinFilm;
    end
    if isfield(obj.inventory, 'nonReplicable')
        obj.metrics.materialFlows.nonReplicable(step) = obj.inventory.nonReplicable;
    end
end

% Implementation for calculateMREMass function:
function mreMass = calculateMREMass(obj)
    % Calculate mass for each MRE unit based on non-linear formula
    % Accounting for different mass scaling between Earth and lunar manufactured units
    mreMass = 0;
    
    % Get parameters needed for calculation
    N = obj.processingMRE.oxygenPerUnitPerYear;
    t = obj.processingMRE.dutyCycle;
    
    % Earth manufactured coefficient
    earthCoeff = 1.492;
    % Lunar manufactured coefficient
    lunarCoeff = 7.012;
    
    % Check if we have information about which units are Earth vs lunar manufactured
    if isfield(obj.processingMRE, 'earthManufacturedUnits')
        earthUnits = obj.processingMRE.earthManufacturedUnits;
        lunarUnits = obj.processingMRE.units - earthUnits;
        
        % Calculate mass for Earth manufactured units
        for i = 1:earthUnits
            unitMass = earthCoeff * (N/(2*t))^0.608;
            mreMass = mreMass + unitMass;
        end
        
        % Calculate mass for lunar manufactured units
        for i = 1:lunarUnits
            unitMass = lunarCoeff * (N/(2*t))^0.608;
            mreMass = mreMass + unitMass;
        end
    else
        % If we don't know which units are which, assume initial units are Earth manufactured
        % Default assumption: initial configuration units are Earth manufactured
        if isfield(obj.simConfig.initialConfig, 'processingMRE') && ...
           isfield(obj.simConfig.initialConfig.processingMRE, 'units')
            initialUnits = obj.simConfig.initialConfig.processingMRE.units;
        else
            initialUnits = 1; % Default if not specified
        end
        
        % Limit to actual number of units
        earthUnits = min(initialUnits, obj.processingMRE.units);
        lunarUnits = obj.processingMRE.units - earthUnits;
        
        % Calculate mass for Earth manufactured units
        for i = 1:earthUnits
            unitMass = earthCoeff * (N/(2*t))^0.608;
            mreMass = mreMass + unitMass;
        end
        
        % Calculate mass for lunar manufactured units
        for i = 1:lunarUnits
            unitMass = lunarCoeff * (N/(2*t))^0.608;
            mreMass = mreMass + unitMass;
        end
    end
end
% Implementation for executeMRE function:
function executeMRE(obj)
    % Execute Molten Regolith Electrolysis processing
    % This function models MRE processing with proper nonlinear scaling for each unit
    % and accounts for different mass scaling between Earth and lunar manufactured units
    
    % Calculate time step in hours
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Get per-unit oxygen production rate and duty cycle
    N = obj.processingMRE.oxygenPerUnitPerYear;
    t = obj.processingMRE.dutyCycle;
    
    % Different mass scaling formulas:
    % - Earth-manufactured: 1.492 * (N/(2*t))^0.608
    % - Lunar-manufactured: 7.012 * (N/(2*t))^0.608
    
    % Track total power requirement across all units
    totalPowerNeeded = 0;
    
    % For each MRE unit, calculate its power requirement based on the nonlinear formula
    for i = 1:obj.processingMRE.units
        % Calculate power for this unit using the nonlinear formula
        unitPower = 264 * (N/(2*t))^0.577;
        totalPowerNeeded = totalPowerNeeded + unitPower;
    end
    
    % Calculate theoretical total oxygen production for this time step
    yearlySeconds = 365 * 24 * 3600;
    timeStepSeconds = timeStepHours * 3600;
    timeStepFraction = timeStepSeconds / yearlySeconds;
    
    totalOxygenProduction = obj.processingMRE.oxygenPerYear * timeStepFraction;
    
    % Calculate required regolith for full capacity
    regolithRequired = totalOxygenProduction * (23720 / 10000); % Ratio from documentation
    
    % Calculate power efficiency factor
    totalEnergyRequired = totalPowerNeeded * timeStepHours;
    availableEnergy = obj.processingMRE.allocatedPower * timeStepHours;
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Adjust processing by power efficiency factor
    adjustedRegolith = regolithRequired * energyEfficiencyFactor;
    
    % Limit by available regolith
    regolithProcessed = min(adjustedRegolith, obj.inventory.regolith);
    
    % Process regolith and produce materials according to output ratios
    if regolithProcessed > 0
        % Remove processed regolith from inventory
        obj.inventory.regolith = obj.inventory.regolith - regolithProcessed;
        
        % Calculate output amounts based on processed regolith
        oxygenProduced = regolithProcessed * (10000 / 23720);
        ironProduced = oxygenProduced * obj.subConfig.processingMRE.outputRatios.iron;
        siliconProduced = oxygenProduced * obj.subConfig.processingMRE.outputRatios.silicon;
        aluminumProduced = oxygenProduced * obj.subConfig.processingMRE.outputRatios.aluminum;
        slagProduced = oxygenProduced * obj.subConfig.processingMRE.outputRatios.slag;
        
        % Add products to inventory
        obj.inventory.oxygen = obj.inventory.oxygen + oxygenProduced;
        obj.inventory.iron = obj.inventory.iron + ironProduced;
        obj.inventory.silicon = obj.inventory.silicon + siliconProduced;
        obj.inventory.aluminum = obj.inventory.aluminum + aluminumProduced;
        obj.inventory.slag = obj.inventory.slag + slagProduced;
        
        fprintf('MRE Processing: %.2f kg regolith processed\n', regolithProcessed);
        fprintf('  Power efficiency: %.1f%%, Capacity utilization: %.1f%%\n', energyEfficiencyFactor * 100, (regolithProcessed / regolithRequired) * 100);
        fprintf('  Produced: %.2f kg oxygen, %.2f kg iron, %.2f kg silicon, %.2f kg aluminum, %.2f kg slag\n', oxygenProduced, ironProduced, siliconProduced, aluminumProduced, slagProduced);
    else 
        fprintf('No MRE processing (insufficient power or regolith)\n');
    end
end
% Implementation for executeHCl function:
function executeHCl(obj)
    % Execute HCl Acid Treatment processing
    
    % Calculate processing capacity
    processingCapacity = obj.processingHCl.mass / obj.processingHCl.massScalingFactor;
    
    % Limit by available regolith
    regolithProcessed = min(processingCapacity * obj.simConfig.timeStepSize, obj.inventory.regolith);
    
    % Calculate power efficiency factor
    hourlyPowerNeeded = processingCapacity * obj.processingHCl.powerScalingFactor;
    totalEnergyRequired = hourlyPowerNeeded * obj.simConfig.timeStepSize;
    availableEnergy = obj.processingHCl.allocatedPower * obj.simConfig.timeStepSize;
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Adjust processing amount by power efficiency
    regolithProcessed = regolithProcessed * energyEfficiencyFactor;
    
    % Process regolith and produce materials according to output ratios
    if regolithProcessed > 0
        % Remove processed regolith from inventory
        obj.inventory.regolith = obj.inventory.regolith - regolithProcessed;
        
        % Calculate output amounts - updated to match documentation
        silicaProduced = regolithProcessed * obj.subConfig.processingHCl.outputRatios.silica;
        aluminaProduced = regolithProcessed * obj.subConfig.processingHCl.outputRatios.alumina;
        
        % Add products to inventory
        obj.inventory.silica = obj.inventory.silica + silicaProduced;
        obj.inventory.alumina = obj.inventory.alumina + aluminaProduced;
        
        % Consume HCl reagent (non-replicable)
        hclConsumed = regolithProcessed * obj.processingHCl.reagentConsumptionRate;
        obj.inventory.nonReplicable = obj.inventory.nonReplicable - hclConsumed;
        
        fprintf('HCl Processing: %.2f kg regolith processed\n', regolithProcessed);
        fprintf('  Produced: %.2f kg silica, %.2f kg alumina\n', silicaProduced, aluminaProduced);
        fprintf('  Consumed: %.2f kg non-replicable materials\n', hclConsumed);
    else 
        fprintf('No HCl processing (insufficient power or regolith)\n');
    end
end

function [canBuild, maxUnits, requiredMaterials] = checkBuildRequirements(obj, subsystem)
    % Check if the required materials are available to build a subsystem
    % Returns:
    %   canBuild: Boolean indicating if subsystem can be built
    %   maxUnits: Maximum number of units that can be built with available materials
    %   requiredMaterials: Structure with required materials per unit
    
    % Initialize return values
    canBuild = false;
    maxUnits = 0;
    requiredMaterials = struct();
    requiredMaterials.total = 0;
    
    % Check which subsystem to build
    if strcmp(subsystem, 'extraction')
        % Extraction rover - Lunar manufactured version
        requiredMaterials.castAluminum = 18; % kg
        requiredMaterials.precisionAluminum = 4; % kg
        requiredMaterials.precisionIron = 3; % kg
        requiredMaterials.precisionAlumina = 1; % kg
        requiredMaterials.nonReplicable = 9; % kg
        requiredMaterials.total = 36; % kg - total mass for lunar manufactured rover
        
    elseif strcmp(subsystem, 'processingMRE')
        % MRE processor - Lunar manufactured version - Updated to match document specifications
        requiredMaterials.castIron = 276.3; % kg - structure (45% of mass)
        requiredMaterials.sinteredAlumina = 89.0; % kg - refractory (14.5% of mass)
        requiredMaterials.silicaGlass = 227.1; % kg - insulation (37% of mass)
        requiredMaterials.nonReplicable = 21.6; % kg - anode (1%), cathode (0.5%), electronics (2%)
        requiredMaterials.total = 614.0; % kg - total mass based on components
        
    elseif strcmp(subsystem, 'processingHCl')
        % HCl Acid Treatment - Lunar manufactured version
        requiredMaterials.castIron = 450; % kg - structure and components
        requiredMaterials.precisionIron = 150; % kg - precision components
        requiredMaterials.precisionAluminum = 150; % kg - precision components
        requiredMaterials.precisionAlumina = 60; % kg - precision components
        requiredMaterials.silicaGlass = 100; % kg - reactor containers
        requiredMaterials.sinteredAlumina = 100; % kg - heat resistant components
        requiredMaterials.nonReplicable = 280; % kg - reagents, control systems
        requiredMaterials.total = 1290; % kg - total for lunar manufactured unit
        
    elseif strcmp(subsystem, 'processingVP')
        % Vacuum Pyrolysis - Lunar manufactured version
        requiredMaterials.castIron = 110; % kg - structure
        requiredMaterials.sinteredAlumina = 80; % kg - crucible
        requiredMaterials.silicaGlass = 12; % kg - fresnel lens glass
        requiredMaterials.precisionIron = 60; % kg - moving components
        requiredMaterials.precisionAluminum = 45; % kg - moving components
        requiredMaterials.precisionAlumina = 15; % kg - precision components
        requiredMaterials.nonReplicable = 30; % kg - control systems
        requiredMaterials.total = 352; % kg - total based on components
        
    elseif strcmp(subsystem, 'manufacturingLPBF')
        % LPBF - Lunar manufactured version
        requiredMaterials.castAluminum = 400; % kg - structures
        requiredMaterials.castIron = 600; % kg - build platform, powder storage, etc.
        requiredMaterials.precisionIron = 150; % kg - precision components
        requiredMaterials.precisionAluminum = 150; % kg - precision components
        requiredMaterials.precisionAlumina = 100; % kg - precision components
        requiredMaterials.nonReplicable = 550; % kg - laser system, control electronics
        requiredMaterials.total = 1950; % kg - based on documentation for lunar manufactured
        
    elseif strcmp(subsystem, 'manufacturingEBPVD')
        % Thermal Vacuum Deposition - Lunar manufactured version
        requiredMaterials.castAluminum = 50; % kg - structure
        requiredMaterials.precisionAluminum = 45; % kg - substrate holder
        requiredMaterials.precisionIron = 45; % kg - substrate holder
        requiredMaterials.precisionAlumina = 10; % kg - substrate holder
        requiredMaterials.nonReplicable = 51; % kg - heating element, evaporation boats, electronics
        requiredMaterials.total = 201; % kg - based on documentation
        
    elseif strcmp(subsystem, 'manufacturingSC')
        % Sand Casting - Lunar manufactured version
        requiredMaterials.castIron = 20; % kg - flask
        requiredMaterials.precisionAluminum = 25; % kg - pattern
        requiredMaterials.castAluminum = 15; % kg - sand management components
        requiredMaterials.precisionIron = 4; % kg - precision components
        requiredMaterials.precisionAlumina = 3; % kg - precision components
        requiredMaterials.regolith = 250; % kg - sand material
        requiredMaterials.nonReplicable = 10; % kg - control electronics
        requiredMaterials.total = 327; % kg - approximate total based on components
        
    elseif strcmp(subsystem, 'manufacturingPC')
        % Permanent Casting - Lunar manufactured version
        requiredMaterials.castIron = 20; % kg - clamps
        requiredMaterials.precisionIron = 8; % kg - alignment system
        requiredMaterials.precisionAluminum = 8; % kg - alignment system
        requiredMaterials.precisionAlumina = 4; % kg - alignment system
        requiredMaterials.sinteredAlumina = 10; % kg - furnace
        requiredMaterials.silicaGlass = 5; % kg - furnace
        requiredMaterials.sinteredRegolith = 60; % kg - mold material
        requiredMaterials.nonReplicable = 5; % kg - control electronics
        requiredMaterials.total = 120; % kg - approximate total
        
    elseif strcmp(subsystem, 'manufacturingSSLS')
        % Selective Solar Light Sinter - Lunar manufactured version
        requiredMaterials.silicaGlass = 4; % kg - solar concentrator
        requiredMaterials.precisionAluminum = 16; % kg - actuation mount
        requiredMaterials.precisionIron = 16; % kg - actuation mount
        requiredMaterials.precisionAlumina = 4; % kg - actuation mount
        requiredMaterials.castIron = 15; % kg - roller components
        requiredMaterials.castAluminum = 8; % kg - feedstock tank
        requiredMaterials.nonReplicable = 2; % kg - control electronics
        requiredMaterials.total = 65; % kg - approximate total
        
    elseif strcmp(subsystem, 'assembly')
        % Assembly Robot - Lunar manufactured version
        requiredMaterials.castAluminum = 380; % kg - structure
        requiredMaterials.precisionAluminum = 250; % kg - actuators and end effectors
        requiredMaterials.precisionIron = 250; % kg - actuators and end effectors
        requiredMaterials.precisionAlumina = 75; % kg - actuators and end effectors
        requiredMaterials.nonReplicable = 450; % kg - control systems, sensors, non-replicable end effector components
        requiredMaterials.total = 1405; % kg - based on documentation
        
    elseif strcmp(subsystem, 'powerLunarSolar')
        % Lunar Solar Array - Lunar manufactured version
        requiredMaterials.solarThinFilm = 0.12; % kg - thin film layer (0.115% of mass)
        requiredMaterials.sinteredRegolith = 50; % kg - superstrate (49.9% of mass) CHANGE BACK TO SILICAGLASS
        requiredMaterials.castAluminum = 45; % kg - structure (45% of mass)
        requiredMaterials.precisionAluminum = 2.5; % kg - solar array drive assembly 
        requiredMaterials.precisionIron = 2.5; % kg - solar array drive assembly
        requiredMaterials.precisionAlumina = 0.5; % kg - solar array drive assembly
        requiredMaterials.total = 100.62; % kg - total for a solar array unit (approximately 100 kg)
    end
    
    % Check if required materials are available
    if isempty(fieldnames(requiredMaterials)) || requiredMaterials.total == 0
        % No requirements specified
        return;
    end
    
    % Calculate maximum units buildable based on required materials
    materialFields = fieldnames(requiredMaterials);
    maxRatios = [];
    
    for i = 1:length(materialFields)
        materialType = materialFields{i};
        if ~strcmp(materialType, 'total')
            amountRequired = requiredMaterials.(materialType);
            
            if amountRequired > 0
                % Check if material is available in inventory
                if isfield(obj.inventory, materialType)
                    amountAvailable = obj.inventory.(materialType);
                    maxRatios(end+1) = amountAvailable / amountRequired;
                else
                    % Material not found in inventory
                    maxRatios(end+1) = 0;
                end
            end
        end
    end
    
    % We can build as many units as limited by the most constrained material
    if ~isempty(maxRatios)
        maxUnits = floor(min(maxRatios));
        canBuild = (maxUnits > 0);
    end
end

% Implementation for executeVP (Vacuum Pyrolysis) function:
function executeVP(obj)
    % Calculate processing capacity
    totalVPMass = obj.processingVP.mass;
    massScalingFactor = obj.processingVP.massScalingFactor;
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Theoretical throughput calculation
    processingCapacity = totalVPMass / massScalingFactor;
    
    % Power efficiency calculation
    hourlyPowerNeeded = processingCapacity * obj.processingVP.powerScalingFactor;
    totalEnergyRequired = hourlyPowerNeeded * timeStepHours;
    
    % Check if allocatedPower field exists, if not initialize it
    if ~isfield(obj.processingVP, 'allocatedPower')
        obj.processingVP.allocatedPower = 0;
    end
    
    availableEnergy = obj.processingVP.allocatedPower * timeStepHours;
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Adjust processing capacity by power efficiency
    regolithProcessable = processingCapacity * timeStepHours * energyEfficiencyFactor;
    
    % Debug information
    fprintf('VP Debug: Capacity = %.2f kg for time step (%.2f%% efficiency)\n', ...
            regolithProcessable, energyEfficiencyFactor * 100);
    
    % Limit by available regolith
    regolithProcessed = min(regolithProcessable, obj.inventory.regolith);
    
    % Process regolith if possible
    if regolithProcessed > 0
        % Remove processed regolith
        obj.inventory.regolith = obj.inventory.regolith - regolithProcessed;
        
        % Use the output ratios from the configuration
        oxygenProduced = regolithProcessed * obj.subConfig.processingVP.outputRatios.oxygen;
        siliconProduced = regolithProcessed * obj.subConfig.processingVP.outputRatios.silicon;
        aluminumProduced = regolithProcessed * obj.subConfig.processingVP.outputRatios.aluminum;
        ironProduced = regolithProcessed * obj.subConfig.processingVP.outputRatios.iron;
        slagProduced = regolithProcessed * obj.subConfig.processingVP.outputRatios.slag;
        
        % Add to inventory
        obj.inventory.oxygen = obj.inventory.oxygen + oxygenProduced;
        obj.inventory.silicon = obj.inventory.silicon + siliconProduced;
        obj.inventory.aluminum = obj.inventory.aluminum + aluminumProduced;
        obj.inventory.iron = obj.inventory.iron + ironProduced;
        obj.inventory.slag = obj.inventory.slag + slagProduced;
        
        fprintf('VP Processing: %.2f kg regolith processed\n', regolithProcessed);
        fprintf('  Produced: %.2f kg oxygen, %.2f kg silicon, %.2f kg aluminum, %.2f kg iron, %.2f kg slag\n', ...
                oxygenProduced, siliconProduced, aluminumProduced, ironProduced, slagProduced);
    else 
        fprintf('No VP processing (insufficient power or regolith)\n');
    end
end

function executeEBPVD(obj, percentage)
    % Execute Thermal Vacuum Deposition to produce solar thin films
    % This updated version uses the correct parameters from the specifications
    
    % Default to 100% if not provided
    if nargin < 2
        percentage = 1.0;
    end
    
    % Get configuration parameters for thin film components
    alThicknessFraction = obj.subConfig.manufacturingEBPVD.aluminumThicknessFraction;
    siThicknessFraction = obj.subConfig.manufacturingEBPVD.siliconThicknessFraction;
    silicaThicknessFraction = obj.subConfig.manufacturingEBPVD.silicaThicknessFraction;
    
    % Calculate equipment throughput capacity
    % Using mass scaling factor - determines how much solar thin film can be produced
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Use the appropriate mass scaling factor (Earth or Lunar manufactured)
    if obj.currentTimeStep <= 1
        massScalingFactor = obj.subConfig.manufacturingEBPVD.massScalingFactorEarth;
    else
        massScalingFactor = obj.subConfig.manufacturingEBPVD.massScalingFactorLunar;
    end
    
    % Calculate production capacity (kg/hr) based on equipment mass
    % THIS IS THE FIXED LINE - enforce strict equipment capacity limit
    productionCapacity = obj.manufacturingEBPVD.mass / massScalingFactor;
    
    % Print capacity for debugging
    fprintf('EBPVD Debug: Equipment mass = %.2f kg, scaling factor = %.2f kg/(kg/hr)\n', obj.manufacturingEBPVD.mass, massScalingFactor);
    fprintf('EBPVD Debug: Maximum production capacity = %.4f kg/hr (%.2f kg per time step)\n', productionCapacity, productionCapacity * timeStepHours);
    
    % Calculate power requirements based on power scaling factor
    powerRequired = productionCapacity * obj.subConfig.manufacturingEBPVD.powerScalingFactor;
    totalEnergyRequired = powerRequired * timeStepHours;
    
    if isfield(obj.manufacturingEBPVD, 'allocatedPower')
        availableEnergy = obj.manufacturingEBPVD.allocatedPower * timeStepHours;
    else
        % Default to 50% of required energy if no allocation is specified
        availableEnergy = totalEnergyRequired * 0.5;
    end
    
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Apply power efficiency to production capacity
    effectiveCapacity = productionCapacity * energyEfficiencyFactor;
    maxProduction = effectiveCapacity * timeStepHours;
    
    fprintf('EBPVD Debug: Energy efficiency = %.2f%%, effective capacity = %.4f kg/hr\n', energyEfficiencyFactor * 100, effectiveCapacity);
    fprintf('EBPVD Debug: Maximum production for this time step = %.2f kg\n', maxProduction);
    
    % Available resources
    alAvailable = obj.inventory.aluminum;
    siAvailable = obj.inventory.silicon;
    silicaAvailable = obj.inventory.silica;
    
    % Calculate maximum thin film possible based on material limitations
    maxThinFilmByAl = alAvailable / alThicknessFraction;
    maxThinFilmBySi = siAvailable / siThicknessFraction;
    maxThinFilmBySilica = silicaAvailable / silicaThicknessFraction;
    maxThinFilmByMaterial = min([maxThinFilmByAl, maxThinFilmBySi, maxThinFilmBySilica]);
    
    % Limit by production capacity and material availability
    % THIS IS THE CRITICAL FIX - ensure we explicitly limit by equipment capacity
    maxThinFilm = min(maxProduction, maxThinFilmByMaterial);
    
    % Apply 97% efficiency as specified in section 4.9
    maxThinFilm = maxThinFilm * 0.97;
    
    % Apply user-specified percentage
    thinFilmToMake = maxThinFilm * percentage;
    
    % Use standard conditional text without the helper function
    if maxProduction < maxThinFilmByMaterial
        limitingFactor = 'EQUIPMENT CAPACITY';
    else
        limitingFactor = 'MATERIAL AVAILABILITY';
    end
    
    fprintf('EBPVD Debug: Final production limited by %s = %.2f kg\n', limitingFactor, thinFilmToMake);
    
    % Calculate required materials
    alNeeded = thinFilmToMake * alThicknessFraction;
    siNeeded = thinFilmToMake * siThicknessFraction;
    silicaNeeded = thinFilmToMake * silicaThicknessFraction;
    
    % Check that we're not trying to use more materials than available (safety check)
    alNeeded = min(alNeeded, alAvailable);
    siNeeded = min(siNeeded, siAvailable);
    silicaNeeded = min(silicaNeeded, silicaAvailable);
    
    % Re-calculate actual production based on available materials
    if thinFilmToMake > 0
        limitingRatio = min([alAvailable/alNeeded, siAvailable/siNeeded, silicaAvailable/silicaNeeded]);
        if limitingRatio < 1
            thinFilmToMake = thinFilmToMake * limitingRatio;
            alNeeded = alNeeded * limitingRatio;
            siNeeded = siNeeded * limitingRatio;
            silicaNeeded = silicaNeeded * limitingRatio;
        end
    end
    
    % Update inventory
    obj.inventory.aluminum = obj.inventory.aluminum - alNeeded;
    obj.inventory.silicon = obj.inventory.silicon - siNeeded;
    obj.inventory.silica = obj.inventory.silica - silicaNeeded;
    
    % Add to solarThinFilm inventory
    if ~isfield(obj.inventory, 'solarThinFilm')
        obj.inventory.solarThinFilm = 0;
    end
    obj.inventory.solarThinFilm = obj.inventory.solarThinFilm + thinFilmToMake;
    
    % Display results
    fprintf('\nThermal Vacuum Deposition results:\n');
    fprintf('  - Aluminum: %.2f kg used (%.2f kg remaining)\n', alNeeded, obj.inventory.aluminum);
    fprintf('  - Silicon: %.2f kg used (%.2f kg remaining)\n', siNeeded, obj.inventory.silicon);
    fprintf('  - Silica: %.2f kg used (%.2f kg remaining)\n', silicaNeeded, obj.inventory.silica);
    fprintf('  - Produced: %.2f kg solar thin film\n', thinFilmToMake);
    
    % Calculate potential solar array metrics
    if isfield(obj.subConfig.powerLunarSolar.components, 'thinFilm') && thinFilmToMake > 0
        thinFilmMassFraction = obj.subConfig.powerLunarSolar.components.thinFilm.massFraction;
        potentialArrayMass = thinFilmToMake / thinFilmMassFraction;
        potentialArea = potentialArrayMass / obj.subConfig.powerLunarSolar.massPerArea;
        potentialPower = potentialArea * obj.envConfig.solarIllumination * obj.powerLunarSolar.efficiency;
        
        fprintf('  - This could produce %.2f m² of solar panels\n', potentialArea);
        fprintf('  - Potential power generation: %.2f W\n', potentialPower);
    end
end

% Implementation for executeExtraction function:
function executeExtraction(obj)
    % Execute extraction operations
    
    % Calculate extraction capacity
    extractionCapacity = obj.extraction.units * obj.extraction.excavationRate * obj.simConfig.timeStepSize;
    
    % Calculate energy requirements (watt-hours) instead of just power (watts)
    % This is the key change - accounting for energy over time rather than instantaneous power
    totalEnergyRequired = obj.extraction.excavationRate * obj.extraction.energyPerKg * obj.simConfig.timeStepSize; % Total Wh needed for full extraction
    availableEnergy = obj.extraction.allocatedPower * obj.simConfig.timeStepSize; % Available Wh
    
    % Calculate energy efficiency factor
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Calculate actual extraction amount (limited by available raw regolith)
    maxExtraction = min(extractionCapacity * energyEfficiencyFactor, obj.inventory.rawRegolith);
    
    % Process raw regolith to regolith with 1:1 ratio
    if maxExtraction > 0
        obj.inventory.rawRegolith = obj.inventory.rawRegolith - maxExtraction;
        obj.inventory.regolith = obj.inventory.regolith + maxExtraction;
        
        % Display more detailed extraction information
        fprintf('Extraction: %.2f kg of regolith extracted (%.2f%% of theoretical capacity)\n', ...
                maxExtraction, (maxExtraction/extractionCapacity)*100);
        fprintf('  - Theoretical max: %.2f kg (with full power allocation)\n', extractionCapacity);
        fprintf('  - Energy efficiency: %.2f%%\n', energyEfficiencyFactor*100);
        fprintf('  - Energy requirements: %.2f Wh available vs %.2f Wh needed for full extraction\n', ...
                availableEnergy, totalEnergyRequired);
        fprintf('  - Average power: %.2f W allocated for %.0f hours\n', ...
                obj.extraction.allocatedPower, obj.simConfig.timeStepSize);
    else
        fprintf('No regolith extracted (insufficient power or raw material)\n');
    end
    
    % Record metrics
    obj.metrics.extractionRate(obj.currentTimeStep) = maxExtraction / obj.simConfig.timeStepSize;
end

% Implementation for executeProcessing function:
function executeProcessing(obj)
    % Execute processing operations (MRE, HCl, VP)
    
    % Molten Regolith Electrolysis (MRE)
    obj.executeMRE();
    
    % HCl Acid Treatment
    obj.executeHCl();
    
    % Vacuum Pyrolysis - ensure it executes when it has mass and power
    if obj.processingVP.mass > 0
        % Check if allocatedPower exists, if not, set a default value
        if ~isfield(obj.processingVP, 'allocatedPower')
            obj.processingVP.allocatedPower = 0; % Default to zero power allocation
        end
        
        % Only execute if there is power allocated
        if obj.processingVP.allocatedPower > 0
            obj.executeVP();
        else
            fprintf('VP subsystem inactive (mass=%.2f kg, power=%.2f W)\n', ...
                    obj.processingVP.mass, obj.processingVP.allocatedPower);
        end
    else
        fprintf('VP subsystem inactive (mass=%.2f kg)\n', obj.processingVP.mass);
    end
end

function executeEconomicOperations(obj)
    % Execute economic operations (sales, costs, etc.)
    
    % Ensure economics arrays are properly initialized
    if ~isfield(obj, 'economics')
        obj.economics = struct();
    end
    
    % Initialize or extend economic metrics if needed
    if ~isfield(obj.economics, 'revenue') || length(obj.economics.revenue) < obj.currentTimeStep
        if isfield(obj.economics, 'revenue')
            % Extend existing array
            currentLength = length(obj.economics.revenue);
            extension = zeros(1, obj.currentTimeStep - currentLength);
            obj.economics.revenue = [obj.economics.revenue, extension];
        else
            % Create new array
            obj.economics.revenue = zeros(1, max(obj.currentTimeStep, obj.simConfig.numTimeSteps));
        end
    end
    
    if ~isfield(obj.economics, 'costs') || length(obj.economics.costs) < obj.currentTimeStep
        if isfield(obj.economics, 'costs')
            % Extend existing array
            currentLength = length(obj.economics.costs);
            extension = zeros(1, obj.currentTimeStep - currentLength);
            obj.economics.costs = [obj.economics.costs, extension];
        else
            % Create new array
            obj.economics.costs = zeros(1, max(obj.currentTimeStep, obj.simConfig.numTimeSteps));
        end
    end
    
    if ~isfield(obj.economics, 'profit') || length(obj.economics.profit) < obj.currentTimeStep
        if isfield(obj.economics, 'profit')
            % Extend existing array
            currentLength = length(obj.economics.profit);
            extension = zeros(1, obj.currentTimeStep - currentLength);
            obj.economics.profit = [obj.economics.profit, extension];
        else
            % Create new array
            obj.economics.profit = zeros(1, max(obj.currentTimeStep, obj.simConfig.numTimeSteps));
        end
    end
    
    if ~isfield(obj.economics, 'cumulativeProfit') || length(obj.economics.cumulativeProfit) < obj.currentTimeStep
        if isfield(obj.economics, 'cumulativeProfit')
            % Extend existing array
            currentLength = length(obj.economics.cumulativeProfit);
            extension = zeros(1, obj.currentTimeStep - currentLength);
            obj.economics.cumulativeProfit = [obj.economics.cumulativeProfit, extension];
        else
            % Create new array
            obj.economics.cumulativeProfit = zeros(1, max(obj.currentTimeStep, obj.simConfig.numTimeSteps));
        end
    end
    
    if ~isfield(obj.economics, 'ROI') || length(obj.economics.ROI) < obj.currentTimeStep
        if isfield(obj.economics, 'ROI')
            % Extend existing array
            currentLength = length(obj.economics.ROI);
            extension = zeros(1, obj.currentTimeStep - currentLength);
            obj.economics.ROI = [obj.economics.ROI, extension];
        else
            % Create new array
            obj.economics.ROI = zeros(1, max(obj.currentTimeStep, obj.simConfig.numTimeSteps));
        end
    end
    
    % Calculate product sales
    [revenue, soldMaterials] = obj.calculateSales();
    
    % Calculate costs
    costs = obj.calculateCosts();
    
    % Update economic metrics
    obj.economics.revenue(obj.currentTimeStep) = revenue;
    obj.economics.costs(obj.currentTimeStep) = costs;
    obj.economics.profit(obj.currentTimeStep) = revenue - costs;
    
    if obj.currentTimeStep > 1 && obj.currentTimeStep <= length(obj.economics.cumulativeProfit)
        obj.economics.cumulativeProfit(obj.currentTimeStep) = obj.economics.cumulativeProfit(obj.currentTimeStep - 1) + obj.economics.profit(obj.currentTimeStep);
    else
        obj.economics.cumulativeProfit(obj.currentTimeStep) = obj.economics.profit(obj.currentTimeStep);
    end
    
    % Calculate ROI
    obj.economics.ROI(obj.currentTimeStep) = obj.economics.cumulativeProfit(obj.currentTimeStep) / obj.econConfig.initialInvestment;
    
    % Remove sold materials from inventory
    fields = fieldnames(soldMaterials);
    for i = 1:length(fields)
        field = fields{i};
        obj.inventory.(field) = obj.inventory.(field) - soldMaterials.(field);
    end
    
    fprintf('\nEconomic Operations:\n');
    fprintf('  Revenue: $%.2f\n', revenue);
    fprintf('  Costs: $%.2f\n', costs);
    fprintf('  Profit: $%.2f\n', revenue - costs);
end

% Implementation for calculateSales function:
function [revenue, soldMaterials] = calculateSales(obj)
    % Calculate sales with detailed reporting
    revenue = 0;
    soldMaterials = struct();
    
    % Initialize sold materials
    soldMaterials.oxygen = 0;
    soldMaterials.castSlag = 0;
    
    fprintf('\nSALES REPORT:\n');
    
    % Oxygen sales
    oxygenToSell = obj.inventory.oxygen * obj.productionAllocation.oxygen;
    oxygenRevenue = oxygenToSell * obj.econConfig.productPrices.oxygen;
    revenue = revenue + oxygenRevenue;
    soldMaterials.oxygen = oxygenToSell;
    fprintf('  - Oxygen: %.2f kg sold at $%.2f/kg for $%.2f\n', ...
           oxygenToSell, obj.econConfig.productPrices.oxygen, oxygenRevenue);
    
    % Slag sales
    slagToSell = obj.inventory.castSlag * obj.productionAllocation.castSlag;
    slagRevenue = slagToSell * obj.econConfig.productPrices.slag;
    revenue = revenue + slagRevenue;
    soldMaterials.castSlag = slagToSell;
    fprintf('  - Cast Slag: %.2f kg sold at $%.2f/kg for $%.2f\n', ...
           slagToSell, obj.econConfig.productPrices.slag, slagRevenue);
    
    % Nighttime electrical power sales (if extra capacity)
    powerSurplus = max(0, obj.powerCapacity - obj.powerDemand);
    if powerSurplus > 0
        % Calculate value of surplus power during nighttime
        nighttimeSurplus = powerSurplus * (1 - obj.envConfig.sunlightFraction);
        nighttimeKWh = nighttimeSurplus * obj.simConfig.timeStepSize / 1000;
        nighttimeRate = obj.econConfig.productPrices.daytimePower * obj.econConfig.productPrices.nighttimeMultiplier;
        
        % Revenue from nighttime power
        powerRevenue = nighttimeKWh * nighttimeRate;
        revenue = revenue + powerRevenue;
        
        fprintf('  - Nighttime Electricity: %.2f kWh sold at $%.4f/kWh for $%.2f\n', ...
               nighttimeKWh, nighttimeRate, powerRevenue);
    end
    
    % ISRU-manufactured components sales
    componentInventory = 0;
    if isfield(obj.inventory, 'castAluminum')
        componentInventory = componentInventory + obj.inventory.castAluminum;
    end
    if isfield(obj.inventory, 'castIron')
        componentInventory = componentInventory + obj.inventory.castIron;
    end
    if isfield(obj.inventory, 'silicaGlass')
        componentInventory = componentInventory + obj.inventory.silicaGlass;
    end
    if isfield(obj.inventory, 'sinteredAlumina')
        componentInventory = componentInventory + obj.inventory.sinteredAlumina;
    end
    
    if componentInventory > 100
        componentsToSell = componentInventory * obj.productionAllocation.sales * 0.1;
        componentRevenue = componentsToSell * obj.econConfig.productPrices.isruComponents;
        revenue = revenue + componentRevenue;
        
        fprintf('  - ISRU Components: %.2f kg sold at $%.2f/kg for $%.2f\n', ...
               componentsToSell, obj.econConfig.productPrices.isruComponents, componentRevenue);
        
        % Track sold materials
        if isfield(obj.inventory, 'castAluminum')
            soldMaterials.castAluminum = obj.inventory.castAluminum * (componentsToSell / componentInventory);
        end
        if isfield(obj.inventory, 'castIron')
            soldMaterials.castIron = obj.inventory.castIron * (componentsToSell / componentInventory);
        end
    end
    
    fprintf('TOTAL REVENUE: $%.2f\n', revenue);
end

% Implementation for calculateCosts function:
function costs = calculateCosts(obj)
    % Calculate costs for the current time step
    
    % Base costs (annual operating costs divided by time steps per year)
    timeStepsPerYear = 24 * 365 / obj.simConfig.timeStepSize;
    baseCosts = obj.econConfig.operatingCostsPerYear / timeStepsPerYear;
    
    % Transport costs for non-replicable materials
    transportCosts = 0;  % Will be calculated during resupply
    
    % Total costs
    costs = baseCosts + transportCosts;
end

% Implementation for processResupply function:
function processResupply(obj)
    % Fixed resupply processing
    
    % Calculate resupply amount for this time step
    timeStepsPerYear = 24 * 365 / obj.simConfig.timeStepSize;
    resupplyPerStep = obj.simConfig.resupplyRate / timeStepsPerYear;
    
    % Add resupplied materials with inventory check
    currentNonReplicable = max(0, obj.inventory.nonReplicable); % Ensure non-negative
    obj.inventory.nonReplicable = currentNonReplicable + resupplyPerStep;
    
    % Calculate transport costs
    transportCosts = resupplyPerStep * obj.econConfig.transportCostPerKg;
    
    % Add to economic metrics
    obj.economics.costs(obj.currentTimeStep) = obj.economics.costs(obj.currentTimeStep) + transportCosts;
    
    fprintf('Resupply: %.2f kg of non-replicable materials received (total: %.2f kg)\n', ...
           resupplyPerStep, obj.inventory.nonReplicable);
    fprintf('  Transport cost: $%.2f\n', transportCosts);
end

% Implementation for updateFactoryState function:
function updateFactoryState(obj)
    % Update factory state after time step execution
    
    % Recalculate total mass
    obj.totalMass = obj.calculateTotalMass();
    
    % Update metrics for power capacity and demand
    obj.calculatePowerCapacity();
    obj.calculatePowerDemand();
end

% Implementation for executeLPBF function: 
function executeLPBF(obj, allocation)
    % Calculate time step in hours
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Calculate power efficiency factor
    hourlyPowerNeeded = obj.manufacturingLPBF.units * obj.manufacturingLPBF.powerPerUnit;
    totalEnergyRequired = hourlyPowerNeeded * timeStepHours;
    availableEnergy = obj.manufacturingLPBF.allocatedPower * timeStepHours;
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);

    % Process aluminum based on allocation
    if isfield(allocation, 'aluminum') && allocation.aluminum > 0
        % Calculate maximum aluminum processing capacity using material-specific rate
        maxAluminumCapacity = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.aluminum * timeStepHours;
        
        % Apply power efficiency factor and allocation percentage
        aluminumCapacity = maxAluminumCapacity * energyEfficiencyFactor * allocation.aluminum;
        
        % Limit by available inventory
        aluminumProcessed = min(aluminumCapacity, obj.inventory.aluminum);
        
        if aluminumProcessed > 0
            % Remove input material
            obj.inventory.aluminum = obj.inventory.aluminum - aluminumProcessed;
            
            % Calculate output with 98% efficiency
            precisionAluminumProduced = aluminumProcessed * 0.98;
            
            % Add to inventory
            obj.inventory.precisionAluminum = obj.inventory.precisionAluminum + precisionAluminumProduced;
            
            fprintf('LPBF Processing: %.2f kg aluminum processed\n', aluminumProcessed);
            fprintf('  Produced: %.2f kg precision aluminum\n', precisionAluminumProduced);
        else
            fprintf('No aluminum processed in LPBF (insufficient material)\n');
        end
    end
    
    % Process iron based on allocation
    if isfield(allocation, 'iron') && allocation.iron > 0
        % Calculate maximum iron processing capacity using material-specific rate
        maxIronCapacity = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.iron * timeStepHours;
        
        % Apply power efficiency factor and allocation percentage
        ironCapacity = maxIronCapacity * energyEfficiencyFactor * allocation.iron;
        
        % Limit by available inventory
        ironProcessed = min(ironCapacity, obj.inventory.iron);
        
        if ironProcessed > 0
            % Remove input material
            obj.inventory.iron = obj.inventory.iron - ironProcessed;
            
            % Calculate output with 98% efficiency
            precisionIronProduced = ironProcessed * 0.98;
            
            % Add to inventory
            obj.inventory.precisionIron = obj.inventory.precisionIron + precisionIronProduced;
            
            fprintf('LPBF Processing: %.2f kg iron processed\n', ironProcessed);
            fprintf('  Produced: %.2f kg precision iron\n', precisionIronProduced);
        else
            fprintf('No iron processed in LPBF (insufficient material)\n');
        end
    end
    
    % Process alumina based on allocation
    if isfield(allocation, 'alumina') && allocation.alumina > 0
        % Calculate maximum alumina processing capacity using material-specific rate
        maxAluminaCapacity = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.alumina * timeStepHours;
        
        % Apply power efficiency factor and allocation percentage
        aluminaCapacity = maxAluminaCapacity * energyEfficiencyFactor * allocation.alumina;
        
        % Limit by available inventory
        aluminaProcessed = min(aluminaCapacity, obj.inventory.alumina);
        
        if aluminaProcessed > 0
            % Remove input material
            obj.inventory.alumina = obj.inventory.alumina - aluminaProcessed;
            
            % Calculate output with 98% efficiency
            precisionAluminaProduced = aluminaProcessed * 0.98;
            
            % Add to inventory
            obj.inventory.precisionAlumina = obj.inventory.precisionAlumina + precisionAluminaProduced;
            
            fprintf('LPBF Processing: %.2f kg alumina processed\n', aluminaProcessed);
            fprintf('  Produced: %.2f kg precision alumina\n', precisionAluminaProduced);
        else
            fprintf('No alumina processed in LPBF (insufficient material)\n');
        end
    end
    
    % Output total processing statistics - helps for debugging
    totalProcessed = 0;
    if isfield(allocation, 'aluminum') && allocation.aluminum > 0
        maxAluminumCapacity = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.aluminum * timeStepHours;
        totalProcessed = totalProcessed + min(maxAluminumCapacity * energyEfficiencyFactor * allocation.aluminum, obj.inventory.aluminum);
    end
    if isfield(allocation, 'iron') && allocation.iron > 0
        maxIronCapacity = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.iron * timeStepHours;
        totalProcessed = totalProcessed + min(maxIronCapacity * energyEfficiencyFactor * allocation.iron, obj.inventory.iron);
    end
    if isfield(allocation, 'alumina') && allocation.alumina > 0
        maxAluminaCapacity = obj.manufacturingLPBF.units * obj.subConfig.manufacturingLPBF.inputRates.alumina * timeStepHours;
        totalProcessed = totalProcessed + min(maxAluminaCapacity * energyEfficiencyFactor * allocation.alumina, obj.inventory.alumina);
    end
    
    if totalProcessed > 0
        fprintf('LPBF Total Processing: %.2f kg material processed with %.1f%% power efficiency\n', totalProcessed, energyEfficiencyFactor * 100);
    else
        fprintf('LPBF: No materials processed\n');
    end
end

function executePC(obj, allocation)
    % Execute Permanent Casting manufacturing process
    % This function processes aluminum and slag into cast components
    % NOTE: Iron processing has been removed - now only available in Sand Casting
    
    % Calculate time step in hours
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Calculate processing capacity
    hourlyCapacity = obj.manufacturingPC.mass / obj.manufacturingPC.massScalingFactor;
    
    % Calculate power efficiency factor
    hourlyPowerNeeded = hourlyCapacity * obj.manufacturingPC.powerScalingFactor;
    totalEnergyRequired = hourlyPowerNeeded * timeStepHours;
    
    if isfield(obj.manufacturingPC, 'allocatedPower')
        availableEnergy = obj.manufacturingPC.allocatedPower * timeStepHours;
    else
        % Default to 50% of required energy if no allocation is specified
        availableEnergy = totalEnergyRequired * 0.5;
    end
    
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Adjust capacity based on available energy
    hourlyCapacity = hourlyCapacity * energyEfficiencyFactor;
    totalCapacity = hourlyCapacity * timeStepHours;
    
    % Process aluminum based on allocation
    if isfield(allocation, 'aluminum') && allocation.aluminum > 0
        aluminumCapacity = totalCapacity * allocation.aluminum;
        aluminumProcessed = min(aluminumCapacity, obj.inventory.aluminum);
        
        if aluminumProcessed > 0
            % Remove processed aluminum from inventory
            obj.inventory.aluminum = obj.inventory.aluminum - aluminumProcessed;
            
            % Calculate output with 95% efficiency (5% loss) as specified in section 4.1
            castAluminumProduced = aluminumProcessed * 0.95;
            
            % Add to inventory
            if ~isfield(obj.inventory, 'castAluminum')
                obj.inventory.castAluminum = 0;
            end
            obj.inventory.castAluminum = obj.inventory.castAluminum + castAluminumProduced;
            
            fprintf('Permanent Casting: %.2f kg aluminum processed\n', aluminumProcessed);
            fprintf('  Produced: %.2f kg cast aluminum\n', castAluminumProduced);
        else
            fprintf('No aluminum processed in Permanent Casting (insufficient material)\n');
        end
    end
    
    % IRON PROCESSING REMOVED - Iron can now only be cast via Sand Casting
    
    % Process slag based on allocation
    if isfield(allocation, 'slag') && allocation.slag > 0
        slagCapacity = totalCapacity * allocation.slag;
        slagProcessed = min(slagCapacity, obj.inventory.slag);
        
        if slagProcessed > 0
            % Remove processed slag from inventory
            obj.inventory.slag = obj.inventory.slag - slagProcessed;
            
            % Calculate output with 95% efficiency (5% loss)
            castSlagProduced = slagProcessed * 0.95;
            
            % Add to inventory
            if ~isfield(obj.inventory, 'castSlag')
                obj.inventory.castSlag = 0;
            end
            obj.inventory.castSlag = obj.inventory.castSlag + castSlagProduced;
            
            fprintf('Permanent Casting: %.2f kg slag processed\n', slagProcessed);
            fprintf('  Produced: %.2f kg cast slag\n', castSlagProduced);
        else
            fprintf('No slag processed in Permanent Casting (insufficient material)\n');
        end
    end
    
    % Output total processing statistics
    totalProcessed = 0;
    if isfield(allocation, 'aluminum') && allocation.aluminum > 0
        aluminumCapacity = totalCapacity * allocation.aluminum;
        totalProcessed = totalProcessed + min(aluminumCapacity, obj.inventory.aluminum);
    end
    if isfield(allocation, 'slag') && allocation.slag > 0
        slagCapacity = totalCapacity * allocation.slag;
        totalProcessed = totalProcessed + min(slagCapacity, obj.inventory.slag);
    end
    
    if totalProcessed > 0
        fprintf('Permanent Casting Total Processing: %.2f kg material processed with %.1f%% power efficiency\n', totalProcessed, energyEfficiencyFactor * 100);
    else
        fprintf('Permanent Casting: No materials processed\n');
    end
end
% This artifact contains the updated code for the executeSC method in LunarFactory.m
% to safely handle potentially missing scaling factor properties

function executeSC(obj, allocation)
    % Execute Sand Casting manufacturing process
    % This function processes aluminum, iron, and slag into cast components
    
    % Calculate time step in hours
    timeStepHours = obj.simConfig.timeStepSize;
    
    % Get massScalingFactor with fallback to default
    if isfield(obj.manufacturingSC, 'massScalingFactor')
        massScalingFactor = obj.manufacturingSC.massScalingFactor;
    else
        disp('Warning: Missing massScalingFactor for Sand Casting. Using default value.');
        massScalingFactor = 33.3; % Default from documentation
    end
    
    % Calculate processing capacity
    hourlyCapacity = obj.manufacturingSC.mass / massScalingFactor;
    
    % Calculate power efficiency factor
    % Get powerScalingFactor with fallback to default
    if isfield(obj.manufacturingSC, 'powerScalingFactor')
        powerScalingFactor = obj.manufacturingSC.powerScalingFactor;
    else
        disp('Warning: Missing powerScalingFactor for Sand Casting. Using default value.');
        powerScalingFactor = 43.1; % Default from documentation
    end
    
    hourlyPowerNeeded = hourlyCapacity * powerScalingFactor;
    totalEnergyRequired = hourlyPowerNeeded * timeStepHours;
    
    if isfield(obj.manufacturingSC, 'allocatedPower')
        availableEnergy = obj.manufacturingSC.allocatedPower * timeStepHours;
    else
        % Default to 50% of required energy if no allocation is specified
        availableEnergy = totalEnergyRequired * 0.5;
    end
    
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Adjust capacity based on available energy
    hourlyCapacity = hourlyCapacity * energyEfficiencyFactor;
    totalCapacity = hourlyCapacity * timeStepHours;
    
    % Process aluminum based on allocation
    if isfield(allocation, 'aluminum') && allocation.aluminum > 0
        aluminumCapacity = totalCapacity * allocation.aluminum;
        aluminumProcessed = min(aluminumCapacity, obj.inventory.aluminum);
        
        if aluminumProcessed > 0
            % Remove processed aluminum from inventory
            obj.inventory.aluminum = obj.inventory.aluminum - aluminumProcessed;
            
            % Calculate output with 95% efficiency (5% loss)
            castAluminumProduced = aluminumProcessed * 0.95;
            
            % Add to inventory
            if ~isfield(obj.inventory, 'castAluminum')
                obj.inventory.castAluminum = 0;
            end
            obj.inventory.castAluminum = obj.inventory.castAluminum + castAluminumProduced;
            
            fprintf('Sand Casting: %.2f kg aluminum processed\n', aluminumProcessed);
            fprintf('  Produced: %.2f kg cast aluminum\n', castAluminumProduced);
        else
            fprintf('No aluminum processed in Sand Casting (insufficient material)\n');
        end
    end
    
    % Process iron based on allocation
    if isfield(allocation, 'iron') && allocation.iron > 0
        ironCapacity = totalCapacity * allocation.iron;
        ironProcessed = min(ironCapacity, obj.inventory.iron);
        
        if ironProcessed > 0
            % Remove processed iron from inventory
            obj.inventory.iron = obj.inventory.iron - ironProcessed;
            
            % Calculate output with 95% efficiency (5% loss)
            castIronProduced = ironProcessed * 0.95;
            
            % Add to inventory
            if ~isfield(obj.inventory, 'castIron')
                obj.inventory.castIron = 0;
            end
            obj.inventory.castIron = obj.inventory.castIron + castIronProduced;
            
            fprintf('Sand Casting: %.2f kg iron processed\n', ironProcessed);
            fprintf('  Produced: %.2f kg cast iron\n', castIronProduced);
        else
            fprintf('No iron processed in Sand Casting (insufficient material)\n');
        end
    end
    
    % Process slag based on allocation
    if isfield(allocation, 'slag') && allocation.slag > 0
        slagCapacity = totalCapacity * allocation.slag;
        slagProcessed = min(slagCapacity, obj.inventory.slag);
        
        if slagProcessed > 0
            % Remove processed slag from inventory
            obj.inventory.slag = obj.inventory.slag - slagProcessed;
            
            % Calculate output with 95% efficiency (5% loss)
            castSlagProduced = slagProcessed * 0.95;
            
            % Add to inventory
            if ~isfield(obj.inventory, 'castSlag')
                obj.inventory.castSlag = 0;
            end
            obj.inventory.castSlag = obj.inventory.castSlag + castSlagProduced;
            
            fprintf('Sand Casting: %.2f kg slag processed\n', slagProcessed);
            fprintf('  Produced: %.2f kg cast slag\n', castSlagProduced);
        else
            fprintf('No slag processed in Sand Casting (insufficient material)\n');
        end
    end
    
    % Output total processing statistics
    totalProcessed = 0;
    if isfield(allocation, 'aluminum') && allocation.aluminum > 0
        aluminumCapacity = totalCapacity * allocation.aluminum;
        totalProcessed = totalProcessed + min(aluminumCapacity, obj.inventory.aluminum);
    end
    if isfield(allocation, 'iron') && allocation.iron > 0
        ironCapacity = totalCapacity * allocation.iron;
        totalProcessed = totalProcessed + min(ironCapacity, obj.inventory.iron);
    end
    if isfield(allocation, 'slag') && allocation.slag > 0
        slagCapacity = totalCapacity * allocation.slag;
        totalProcessed = totalProcessed + min(slagCapacity, obj.inventory.slag);
    end
    
    if totalProcessed > 0
        fprintf('Sand Casting Total Processing: %.2f kg material processed with %.1f%% power efficiency\n', totalProcessed, energyEfficiencyFactor * 100);
    else
        fprintf('Sand Casting: No materials processed\n');
    end
end
function displayTimeStepSummary(obj)
    % Display a summary of the current time step
    
    fprintf('\n=========== TIME STEP %d SUMMARY ===========\n', obj.currentTimeStep);
    
    % Display factory size
    fprintf('Factory Mass: %.2f kg\n', obj.totalMass);
    
    % Display power information
    fprintf('Power Capacity: %.2f W\n', obj.powerCapacity);
    fprintf('Power Demand: %.2f W\n', obj.powerDemand);
    fprintf('Power Utilization: %.1f%%\n', (obj.powerDemand / obj.powerCapacity) * 100);
    
    % Display growth metrics
    if obj.currentTimeStep > 1
        fprintf('Monthly Growth Rate: %.2f%%\n', obj.metrics.monthlyGrowthRate(obj.currentTimeStep) * 100);
        fprintf('Annualized Growth Rate: %.2f%%\n', obj.metrics.annualGrowthRate(obj.currentTimeStep) * 100);
    end
    fprintf('Replication Factor: %.2f\n', obj.metrics.replicationFactor(obj.currentTimeStep));
    
    % Display economic metrics
    fprintf('Revenue this period: $%.2f\n', obj.economics.revenue(obj.currentTimeStep));
    fprintf('Costs this period: $%.2f\n', obj.economics.costs(obj.currentTimeStep));
    fprintf('Profit this period: $%.2f\n', obj.economics.profit(obj.currentTimeStep));
    fprintf('Cumulative profit: $%.2f\n', obj.economics.cumulativeProfit(obj.currentTimeStep));
    fprintf('Return on Investment: %.2f%%\n', obj.economics.ROI(obj.currentTimeStep) * 100);
    
    % Display inventory summary
    fprintf('\nKey Material Inventory:\n');
    keyMaterials = {'regolith', 'aluminum', 'iron', 'silicon', 'silica', 'alumina', ...
                    'castAluminum', 'castIron', 'precisionAluminum', 'precisionIron', ...
                    'precisionAlumina', 'solarThinFilm', 'nonReplicable'};
                
    for i = 1:length(keyMaterials)
        material = keyMaterials{i};
        if isfield(obj.inventory, material) && obj.inventory.(material) > 0
            fprintf('  %s: %.2f kg\n', material, obj.inventory.(material));
        end
    end
    
    fprintf('===========================================\n\n');
end

% Implementation for executeSSLS function:
function executeSSLS(obj, allocation)
    % Calculate processing capacity correctly
    % Using existing field names instead of incorrectly referenced ones
    massProdRate = obj.subConfig.manufacturingSSLS.massProdRateSSLS;
    massScalingFactor = obj.manufacturingSSLS.massScalingFactor; 
    powerScalingFactor = obj.manufacturingSSLS.powerScalingFactor;
    
    % Fix: Calculate hourly capacity based on production rate and system mass
    hourlyCapacity = obj.manufacturingSSLS.mass / massScalingFactor;
    
    % Calculate power requirements
    hourlyPowerNeeded = hourlyCapacity * powerScalingFactor;
    totalEnergyRequired = hourlyPowerNeeded * obj.simConfig.timeStepSize;
    availableEnergy = obj.manufacturingSSLS.allocatedPower * obj.simConfig.timeStepSize;
    energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
    
    % Adjust capacity based on available energy
    hourlyCapacity = hourlyCapacity * energyEfficiencyFactor;
    totalCapacity = hourlyCapacity * obj.simConfig.timeStepSize;
    
    % Debug information
    fprintf('SSLS Debug: Capacity = %.2f kg/hr (%.2f kg total for time step)\n', ...
            hourlyCapacity, totalCapacity);
    
    % Process silica based on allocation
    if isfield(allocation, 'silica') && allocation.silica > 0
        silicaCapacity = totalCapacity * allocation.silica;
        silicaProcessed = min(silicaCapacity, obj.inventory.silica);
        
        if silicaProcessed > 0
            obj.inventory.silica = obj.inventory.silica - silicaProcessed;
            obj.inventory.silicaGlass = obj.inventory.silicaGlass + silicaProcessed * 0.95;
            
            fprintf('SSLS Processing: %.2f kg silica sintered\n', silicaProcessed);
            fprintf('  Produced: %.2f kg silica glass\n', silicaProcessed * 0.95);
        else
            fprintf('No silica processed (insufficient material)\n');
        end
    end
    
    % Process alumina based on allocation
    if isfield(allocation, 'alumina') && allocation.alumina > 0
        aluminaCapacity = totalCapacity * allocation.alumina;
        aluminaProcessed = min(aluminaCapacity, obj.inventory.alumina);
        
        if aluminaProcessed > 0
            obj.inventory.alumina = obj.inventory.alumina - aluminaProcessed;
            obj.inventory.sinteredAlumina = obj.inventory.sinteredAlumina + aluminaProcessed * 0.95;
            
            fprintf('SSLS Processing: %.2f kg alumina sintered\n', aluminaProcessed);
            fprintf('  Produced: %.2f kg sintered alumina\n', aluminaProcessed * 0.95);
        else
            fprintf('No alumina processed (insufficient material)\n');
        end
    end
    
    % Process regolith based on allocation
    if isfield(allocation, 'regolith') && allocation.regolith > 0
        regolithCapacity = totalCapacity * allocation.regolith;
        regolithProcessed = min(regolithCapacity, obj.inventory.regolith);
        
        if regolithProcessed > 0
            obj.inventory.regolith = obj.inventory.regolith - regolithProcessed;
            obj.inventory.sinteredRegolith = obj.inventory.sinteredRegolith + regolithProcessed * 0.95;
            
            fprintf('SSLS Processing: %.2f kg regolith sintered\n', regolithProcessed);
            fprintf('  Produced: %.2f kg sintered regolith\n', regolithProcessed * 0.95);
        else
            fprintf('No regolith processed (insufficient material)\n');
        end
    end
end
    end
end