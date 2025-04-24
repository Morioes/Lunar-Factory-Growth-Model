function factory = runAutomatedSimulation(envConfig, subConfig, econConfig, simConfig, weights, lookAheadSteps, initialGuess)
% RUNAUTOMATEDSIMULATION Runs the lunar factory simulation in automated mode
%   This function runs the lunar factory simulation using algorithmic optimization
%   instead of user input. It uses the optimizeFactoryGrowth function to make
%   decisions at each time step.
%
%   Inputs:
%       envConfig - Environmental configuration
%       subConfig - Subsystem configuration
%       econConfig - Economic configuration
%       simConfig - Simulation configuration
%       weights - Structure with weights for cost function components (optional)
%           .expansion - Weight for factory expansion (0-1)
%           .selfReliance - Weight for factory self-reliance (0-1)
%           .revenue - Weight for revenue generation (0-1)
%           .cost - Weight for cost minimization (0-1)
%       lookAheadSteps - Number of time steps to look ahead (optional, default: 3)
%       initialGuess - Initial resource allocation strategy (optional)
%
%   Outputs:
%       factory - LunarFactory object containing final state and results

% Handle optional inputs
if nargin < 5 || isempty(weights)
    % Default weights
    weights = struct();
    weights.expansion = 0.5;
    weights.selfReliance = 0.2;
    weights.revenue = 0.2;
    weights.cost = 0.1;
    fprintf('Using default weights for optimization cost function.\n');
end

if nargin < 6 || isempty(lookAheadSteps)
    lookAheadSteps = 3;
end

if nargin < 7
    initialGuess = [];
end

% Create factory object
fprintf('Creating lunar factory object for automated simulation...\n');
factory = LunarFactory(envConfig, subConfig, econConfig, simConfig);

% Create history tracking for optimization decisions
factory.optimizationHistory = struct();
factory.optimizationHistory.strategies = cell(simConfig.numTimeSteps, 1);
factory.optimizationHistory.metrics = cell(simConfig.numTimeSteps, 1);
factory.optimizationHistory.scores = zeros(simConfig.numTimeSteps, 1);

% Open optimization results file
optimizationFilename = sprintf('optimization_results_%s.txt', datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
fid = fopen(optimizationFilename, 'w');
if fid == -1
    warning('Could not open optimization results file for writing. Results will not be saved.');
else
    % Write header information
    fprintf(fid, '====================================================\n');
    fprintf(fid, '        LUNAR FACTORY OPTIMIZATION RESULTS          \n');
    fprintf(fid, '====================================================\n\n');
    fprintf(fid, 'Simulation Date: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, 'Number of Time Steps: %d\n', simConfig.numTimeSteps);
    fprintf(fid, 'Time Step Size: %d hours\n', simConfig.timeStepSize);
    fprintf(fid, 'Look Ahead Steps: %d\n', lookAheadSteps);
    fprintf(fid, '\nOptimization Weights:\n');
    fprintf(fid, '  Expansion: %.2f\n', weights.expansion);
    fprintf(fid, '  Self-Reliance: %.2f\n', weights.selfReliance);
    fprintf(fid, '  Revenue: %.2f\n', weights.revenue);
    fprintf(fid, '  Cost: %.2f\n', weights.cost);

    fprintf(fid, '====================================================\n\n');
end

% Run the automated simulation
fprintf('Running automated simulation with optimization...\n');

% Loop through time steps
for step = 1:simConfig.numTimeSteps
    factory.currentTimeStep = step;
    
    fprintf('\n==== Time Step %d of %d ====\n', step, simConfig.numTimeSteps);
    
    % Write time step header to file
    if fid ~= -1
        fprintf(fid, '\n####################################################\n');
        fprintf(fid, '                TIME STEP %d of %d                  \n', step, simConfig.numTimeSteps);
        fprintf(fid, '####################################################\n\n');
    end
    
    % Run optimization to determine best strategy
    fprintf('Optimizing factory growth strategy...\n');
    [optimizedStrategy, predictedMetrics] = optimizeFactoryGrowth(factory, weights, lookAheadSteps, initialGuess);
    
    % Store optimization results in history
    factory.optimizationHistory.strategies{step} = optimizedStrategy;
    factory.optimizationHistory.metrics{step} = predictedMetrics;
    
    % Write allocation decisions to file
    if fid ~= -1
        writeAllocationDecisions(fid, optimizedStrategy, factory);
    end
    
    % Apply the optimized strategy
    fprintf('Applying optimized strategy...\n');
    
    % 1. Set power distribution
    distributeFactoryPower(factory, optimizedStrategy.powerDistribution);
    
    % 2. Execute extraction, processing, and manufacturing
    fprintf('Executing extraction...\n');
    factory.executeExtraction();
    
    fprintf('Executing processing...\n');
    factory.executeProcessing();
    
    fprintf('Executing manufacturing...\n');
    factory.executeProduction(optimizedStrategy.productionAllocation);
    
    % 3. Execute assembly
    fprintf('Calculating and executing assembly decisions...\n');
    assemblyDecisions = calculateOptimalAssembly(factory, optimizedStrategy);
    factory.executeAssembly(assemblyDecisions);
    
    % 4. Execute economic operations and process resupply
    fprintf('Executing economic operations...\n');
    factory.executeEconomicOperations();
    
    fprintf('Processing resupply...\n');
    factory.processResupply();
    
    % 5. Update factory state and record metrics
    fprintf('Updating factory state...\n');
    factory.updateFactoryState();
    factory.recordMetrics(step);
    
    % 6. Display summary for this time step
    displayTimeStepSummary(factory, step);
    
    % 7. Write factory state to file
    if fid ~= -1
        writeFactoryState(fid, factory, step);
    end
    
    % 8. Update initial guess for next iteration based on current strategy
    initialGuess = optimizedStrategy;
end

% Close the file
if fid ~= -1 && fid ~= 1
    fprintf(fid, '\n====================================================\n');
    fprintf(fid, '           SIMULATION COMPLETE                    \n');
    fprintf(fid, '====================================================\n');
    fclose(fid);
    fprintf('\nOptimization results saved to: %s\n', optimizationFilename);
end

% Make factory available in base workspace
assignin('base', 'automatedFactory', factory);

fprintf('\nAutomated simulation complete.\n');
fprintf('Results are available in the returned factory object and in the "automatedFactory" variable in the workspace.\n');

end

function writeAllocationDecisions(fid, strategy, factory)
% Write allocation decisions to file
fprintf(fid, 'ALLOCATION DECISIONS:\n');
fprintf(fid, '--------------------\n\n');

% Write power distribution
fprintf(fid, 'Power Distribution:\n');
powerFields = fieldnames(strategy.powerDistribution);
totalPower = 0;
for i = 1:length(powerFields)
    powerValue = strategy.powerDistribution.(powerFields{i}) * 100;
    fprintf(fid, '  %s: %.1f%%\n', powerFields{i}, powerValue);
    totalPower = totalPower + powerValue;
end
fprintf(fid, '  Total: %.1f%%\n\n', totalPower);

% Write production allocation
fprintf(fid, 'Production Allocation:\n');
if isfield(strategy.productionAllocation, 'replication')
    fprintf(fid, '  Replication: %.1f%%\n', strategy.productionAllocation.replication * 100);
    fprintf(fid, '  Sales: %.1f%%\n', strategy.productionAllocation.sales * 100);
end
if isfield(strategy.productionAllocation, 'oxygen')
    fprintf(fid, '  Oxygen Sales: %.1f%%\n', strategy.productionAllocation.oxygen * 100);
end
if isfield(strategy.productionAllocation, 'castSlag')
    fprintf(fid, '  Cast Slag Sales: %.1f%%\n', strategy.productionAllocation.castSlag * 100);
end
if isfield(strategy.productionAllocation, 'solarThinFilm')
    fprintf(fid, '  Solar Thin Film Usage: %.1f%%\n', strategy.productionAllocation.solarThinFilm * 100);
end
fprintf(fid, '\n');

% Write manufacturing subsystem allocation
fprintf(fid, 'Manufacturing Subsystem Allocation:\n');

% LPBF allocation
if isfield(strategy.productionAllocation, 'lpbf')
    fprintf(fid, '  LPBF:\n');
    if isfield(strategy.productionAllocation.lpbf, 'aluminum')
        fprintf(fid, '    Aluminum: %.1f%%\n', strategy.productionAllocation.lpbf.aluminum * 100);
    end
    if isfield(strategy.productionAllocation.lpbf, 'iron')
        fprintf(fid, '    Iron: %.1f%%\n', strategy.productionAllocation.lpbf.iron * 100);
    end
    if isfield(strategy.productionAllocation.lpbf, 'alumina')
        fprintf(fid, '    Alumina: %.1f%%\n', strategy.productionAllocation.lpbf.alumina * 100);
    end
end

% Sand Casting allocation
if isfield(strategy.productionAllocation, 'sc')
    fprintf(fid, '  Sand Casting:\n');
    if isfield(strategy.productionAllocation.sc, 'aluminum')
        fprintf(fid, '    Aluminum: %.1f%%\n', strategy.productionAllocation.sc.aluminum * 100);
    end
    if isfield(strategy.productionAllocation.sc, 'iron')
        fprintf(fid, '    Iron: %.1f%%\n', strategy.productionAllocation.sc.iron * 100);
    end
    if isfield(strategy.productionAllocation.sc, 'slag')
        fprintf(fid, '    Slag: %.1f%%\n', strategy.productionAllocation.sc.slag * 100);
    end
end

% Permanent Casting allocation
if isfield(strategy.productionAllocation, 'pc')
    fprintf(fid, '  Permanent Casting:\n');
    if isfield(strategy.productionAllocation.pc, 'aluminum')
        fprintf(fid, '    Aluminum: %.1f%%\n', strategy.productionAllocation.pc.aluminum * 100);
    end
    if isfield(strategy.productionAllocation.pc, 'iron')
        fprintf(fid, '    Iron: %.1f%%\n', strategy.productionAllocation.pc.iron * 100);
    end
    if isfield(strategy.productionAllocation.pc, 'slag')
        fprintf(fid, '    Slag: %.1f%%\n', strategy.productionAllocation.pc.slag * 100);
    end
end

% SSLS allocation
if isfield(strategy.productionAllocation, 'ssls')
    fprintf(fid, '  SSLS:\n');
    if isfield(strategy.productionAllocation.ssls, 'silica')
        fprintf(fid, '    Silica: %.1f%%\n', strategy.productionAllocation.ssls.silica * 100);
    end
    if isfield(strategy.productionAllocation.ssls, 'alumina')
        fprintf(fid, '    Alumina: %.1f%%\n', strategy.productionAllocation.ssls.alumina * 100);
    end
    if isfield(strategy.productionAllocation.ssls, 'regolith')
        fprintf(fid, '    Regolith: %.1f%%\n', strategy.productionAllocation.ssls.regolith * 100);
    end
end

% EBPVD allocation
if isfield(strategy.productionAllocation, 'EBPVD')
    fprintf(fid, '  EBPVD:\n');
    fprintf(fid, '    Active: %s\n', mat2str(strategy.productionAllocation.EBPVD.active));
    if isfield(strategy.productionAllocation.EBPVD, 'percentage')
        fprintf(fid, '    Percentage: %.1f%%\n', strategy.productionAllocation.EBPVD.percentage * 100);
    end
end

fprintf(fid, '\n');
end

function writeFactoryState(fid, factory, step)
% Write factory state summary to file
fprintf(fid, 'FACTORY STATE SUMMARY:\n');
fprintf(fid, '---------------------\n\n');

% General metrics
fprintf(fid, 'General Metrics:\n');
fprintf(fid, '  Total Mass: %.2f kg\n', factory.totalMass);
fprintf(fid, '  Power Capacity: %.2f W\n', factory.powerCapacity);
fprintf(fid, '  Power Demand: %.2f W (%.1f%% utilization)\n', factory.powerDemand, (factory.powerDemand/factory.powerCapacity)*100);

% Growth metrics
if step > 1
    fprintf(fid, '  Monthly Growth Rate: %.2f%%\n', factory.metrics.monthlyGrowthRate(step) * 100);
    fprintf(fid, '  Annual Growth Rate: %.2f%%\n', factory.metrics.annualGrowthRate(step) * 100);
end
fprintf(fid, '  Replication Factor: %.2f\n\n', factory.metrics.replicationFactor(step));

% Subsystem masses
fprintf(fid, 'Subsystem Masses:\n');
fprintf(fid, '  Extraction: %.2f kg\n', factory.extraction.mass);
fprintf(fid, '  Processing MRE: %.2f kg\n', factory.processingMRE.mass);
fprintf(fid, '  Processing HCl: %.2f kg\n', factory.processingHCl.mass);
fprintf(fid, '  Processing VP: %.2f kg\n', factory.processingVP.mass);
fprintf(fid, '  Manufacturing LPBF: %.2f kg\n', factory.manufacturingLPBF.mass);
fprintf(fid, '  Manufacturing EBPVD: %.2f kg\n', factory.manufacturingEBPVD.mass);
fprintf(fid, '  Manufacturing SC: %.2f kg\n', factory.manufacturingSC.mass);
fprintf(fid, '  Manufacturing PC: %.2f kg\n', factory.manufacturingPC.mass);
fprintf(fid, '  Manufacturing SSLS: %.2f kg\n', factory.manufacturingSSLS.mass);
fprintf(fid, '  Assembly: %.2f kg\n', factory.assembly.mass);
fprintf(fid, '  Power (Landed Solar): %.2f kg\n', factory.powerLandedSolar.mass);
fprintf(fid, '  Power (Lunar Solar): %.2f kg\n\n', factory.powerLunarSolar.mass);

% Inventory summary
fprintf(fid, 'Key Material Inventory:\n');
if factory.inventory.regolith > 0
    fprintf(fid, '  Regolith: %.2f kg\n', factory.inventory.regolith);
end
if factory.inventory.oxygen > 0
    fprintf(fid, '  Oxygen: %.2f kg\n', factory.inventory.oxygen);
end
if factory.inventory.aluminum > 0
    fprintf(fid, '  Aluminum: %.2f kg\n', factory.inventory.aluminum);
end
if factory.inventory.iron > 0
    fprintf(fid, '  Iron: %.2f kg\n', factory.inventory.iron);
end
if factory.inventory.silicon > 0
    fprintf(fid, '  Silicon: %.2f kg\n', factory.inventory.silicon);
end
if factory.inventory.silica > 0
    fprintf(fid, '  Silica: %.2f kg\n', factory.inventory.silica);
end
if factory.inventory.alumina > 0
    fprintf(fid, '  Alumina: %.2f kg\n', factory.inventory.alumina);
end
if factory.inventory.castAluminum > 0
    fprintf(fid, '  Cast Aluminum: %.2f kg\n', factory.inventory.castAluminum);
end
if factory.inventory.castIron > 0
    fprintf(fid, '  Cast Iron: %.2f kg\n', factory.inventory.castIron);
end
if factory.inventory.precisionAluminum > 0
    fprintf(fid, '  Precision Aluminum: %.2f kg\n', factory.inventory.precisionAluminum);
end
if factory.inventory.precisionIron > 0
    fprintf(fid, '  Precision Iron: %.2f kg\n', factory.inventory.precisionIron);
end
if factory.inventory.precisionAlumina > 0
    fprintf(fid, '  Precision Alumina: %.2f kg\n', factory.inventory.precisionAlumina);
end
if factory.inventory.solarThinFilm > 0
    fprintf(fid, '  Solar Thin Film: %.2f kg\n', factory.inventory.solarThinFilm);
end
fprintf(fid, '  Non-Replicable Materials: %.2f kg\n\n', factory.inventory.nonReplicable);

% Economic results
fprintf(fid, 'Economic Results:\n');
fprintf(fid, '  Revenue: $%.2f\n', factory.economics.revenue(step));
fprintf(fid, '  Costs: $%.2f\n', factory.economics.costs(step));
fprintf(fid, '  Profit: $%.2f\n', factory.economics.profit(step));
fprintf(fid, '  Cumulative Profit: $%.2f\n', factory.economics.cumulativeProfit(step));
fprintf(fid, '  ROI: %.2f%%\n\n', factory.economics.ROI(step) * 100);
end

function distributeFactoryPower(factory, powerDistribution)
    % Distribute power to factory subsystems based on the powerDistribution strategy
    % This function mimics what happens in the LunarFactory.distributeUserPower method

    % Calculate total available power
    factory.calculatePowerCapacity();
    availablePower = factory.powerCapacity;

    % Initialize allocatedPower fields for all subsystems if they don't exist
    % This ensures all subsystems have the field before attempting to use it
    if ~isfield(factory.extraction, 'allocatedPower')
        factory.extraction.allocatedPower = 0;
    end
    if ~isfield(factory.processingMRE, 'allocatedPower')
        factory.processingMRE.allocatedPower = 0;
    end
    if ~isfield(factory.processingHCl, 'allocatedPower')
        factory.processingHCl.allocatedPower = 0;
    end
    if ~isfield(factory.processingVP, 'allocatedPower')
        factory.processingVP.allocatedPower = 0;
    end
    if ~isfield(factory.manufacturingLPBF, 'allocatedPower')
        factory.manufacturingLPBF.allocatedPower = 0;
    end
    if ~isfield(factory.manufacturingEBPVD, 'allocatedPower')
        factory.manufacturingEBPVD.allocatedPower = 0;
    end
    if ~isfield(factory.manufacturingSC, 'allocatedPower')
        factory.manufacturingSC.allocatedPower = 0;
    end
    if ~isfield(factory.manufacturingPC, 'allocatedPower')
        factory.manufacturingPC.allocatedPower = 0;
    end
    if ~isfield(factory.manufacturingSSLS, 'allocatedPower')
        factory.manufacturingSSLS.allocatedPower = 0;
    end
    if ~isfield(factory.assembly, 'allocatedPower')
        factory.assembly.allocatedPower = 0;
    end

    % Allocate power to each subsystem
    subsystems = fieldnames(powerDistribution);
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        allocatedPower = availablePower * powerDistribution.(subsystem);
        
        % Set allocated power for the subsystem
        switch subsystem
            case 'extraction'
                factory.extraction.allocatedPower = allocatedPower;
            case 'processingMRE'
                factory.processingMRE.allocatedPower = allocatedPower;
            case 'processingHCl'
                factory.processingHCl.allocatedPower = allocatedPower;
            case 'processingVP'
                factory.processingVP.allocatedPower = allocatedPower;
            case 'manufacturingLPBF'
                factory.manufacturingLPBF.allocatedPower = allocatedPower;
            case 'manufacturingEBPVD'
                factory.manufacturingEBPVD.allocatedPower = allocatedPower;
            case 'manufacturingSC'
                factory.manufacturingSC.allocatedPower = allocatedPower;
            case 'manufacturingPC'
                factory.manufacturingPC.allocatedPower = allocatedPower;
            case 'manufacturingSSLS'
                factory.manufacturingSSLS.allocatedPower = allocatedPower;
            case 'assembly'
                factory.assembly.allocatedPower = allocatedPower;
        end
    end

    % Update total power demand
    totalAllocated = 0;
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        switch subsystem
            case 'extraction'
                totalAllocated = totalAllocated + factory.extraction.allocatedPower;
            case 'processingMRE'
                totalAllocated = totalAllocated + factory.processingMRE.allocatedPower;
            case 'processingHCl'
                totalAllocated = totalAllocated + factory.processingHCl.allocatedPower;
            case 'processingVP'
                totalAllocated = totalAllocated + factory.processingVP.allocatedPower;
            case 'manufacturingLPBF'
                totalAllocated = totalAllocated + factory.manufacturingLPBF.allocatedPower;
            case 'manufacturingEBPVD'
                totalAllocated = totalAllocated + factory.manufacturingEBPVD.allocatedPower;
            case 'manufacturingSC'
                totalAllocated = totalAllocated + factory.manufacturingSC.allocatedPower;
            case 'manufacturingPC'
                totalAllocated = totalAllocated + factory.manufacturingPC.allocatedPower;
            case 'manufacturingSSLS'
                totalAllocated = totalAllocated + factory.manufacturingSSLS.allocatedPower;
            case 'assembly'
                totalAllocated = totalAllocated + factory.assembly.allocatedPower;
        end
    end

    factory.powerDemand = totalAllocated;
end


function assemblyDecisions = calculateOptimalAssembly(factory, strategy)
% Calculate optimal assembly decisions based on available resources and strategy
% This function mimics the decision-making process that would be done manually

% Initialize assembly decisions
assemblyDecisions = struct();

% Get buildable subsystems based on available materials
buildableSubsystems = findBuildableSubsystems(factory);
if isempty(buildableSubsystems)
    return; % Nothing can be built
end

% Calculate assembly capacity
basicCapacity = factory.assembly.units * factory.assembly.assemblyCapacity * factory.simConfig.timeStepSize;
hourlyPowerNeeded = factory.assembly.units * factory.assembly.powerPerUnit;
totalEnergyRequired = hourlyPowerNeeded * factory.simConfig.timeStepSize;
availableEnergy = factory.assembly.allocatedPower * factory.simConfig.timeStepSize;
energyEfficiencyFactor = min(1, availableEnergy / totalEnergyRequired);
maxCapacity = basicCapacity * energyEfficiencyFactor;

% Calculate bottleneck factors to prioritize growth where needed
[bottlenecks, bottleneckScores] = identifyBottlenecks(factory);

% Initialize allocation matrix
subsystemPriorities = zeros(length(buildableSubsystems), 1);
for i = 1:length(buildableSubsystems)
    subsystem = buildableSubsystems{i};
    
    % Check if this subsystem is a bottleneck
    if ismember(subsystem, bottlenecks)
        % Find its score
        idx = find(strcmp(bottlenecks, subsystem));
        subsystemPriorities(i) = bottleneckScores(idx);
    else
        subsystemPriorities(i) = 0.1; % Base priority
    end
    
    % Adjust priorities based on strategic considerations
    switch subsystem
        case 'powerLunarSolar'
            % Higher priority for power if running low
            powerUtilization = factory.powerDemand / factory.powerCapacity;
            if powerUtilization > 0.8
                subsystemPriorities(i) = subsystemPriorities(i) * 1.5;
            end
        case 'extraction'
            % Higher priority if regolith is low
            if factory.inventory.regolith < 1000
                subsystemPriorities(i) = subsystemPriorities(i) * 1.2;
            end
    end
end

% Normalize priorities
totalPriority = sum(subsystemPriorities);
if totalPriority > 0
    subsystemPriorities = subsystemPriorities / totalPriority;
else
    % If all priorities are 0, distribute evenly
    subsystemPriorities = ones(length(buildableSubsystems), 1) / length(buildableSubsystems);
end

% Allocate assembly capacity based on priorities
remainingCapacity = maxCapacity;
for i = 1:length(buildableSubsystems)
    subsystem = buildableSubsystems{i};
    
    % Get maximum buildable mass for this subsystem
    [canBuild, maxUnits, requiredMaterials] = factory.checkBuildRequirements(subsystem);
    
    if canBuild
        allocatedCapacity = remainingCapacity * subsystemPriorities(i);
        massToAssemble = min(allocatedCapacity, maxUnits * requiredMaterials.total);
        
        % Store in assembly decisions
        assemblyDecisions.(subsystem) = massToAssemble;
        
        % Update remaining capacity
        remainingCapacity = remainingCapacity - massToAssemble;
    else
        assemblyDecisions.(subsystem) = 0;
    end
end

return;
end

function buildableSubsystems = findBuildableSubsystems(factory)
% Find subsystems that can be built based on available materials
buildableSubsystems = {};

% Check each potential subsystem
potentialSubsystems = {'extraction', 'processingMRE', 'processingHCl', 'processingVP', ...
                      'manufacturingLPBF', 'manufacturingEBPVD', 'manufacturingSC', ...
                      'manufacturingPC', 'manufacturingSSLS', 'assembly', 'powerLunarSolar'};

for i = 1:length(potentialSubsystems)
    subsystem = potentialSubsystems{i};
    [canBuild, ~, ~] = factory.checkBuildRequirements(subsystem);
    
    if canBuild
        buildableSubsystems{end+1} = subsystem;
    end
end

return;
end

function [bottlenecks, scores] = identifyBottlenecks(factory)
% Identify bottlenecks in the production chain to prioritize growth
bottlenecks = {};
scores = [];

% Calculate current capacities
extractionCapacity = calculateExtractionCapacity(factory);
processingCapacity = calculateProcessingCapacity(factory);
manufacturingCapacity = calculateManufacturingCapacity(factory);
assemblyCapacity = calculateAssemblyCapacity(factory);
powerCapacity = factory.powerCapacity;
powerDemand = factory.powerDemand;

% Check power bottleneck
if powerDemand > 0.8 * powerCapacity
    bottlenecks{end+1} = 'powerLunarSolar';
    scores(end+1) = min(1, powerDemand / powerCapacity);
end

% Check extraction bottleneck (based on processing capacity comparison)
if extractionCapacity < 0.8 * processingCapacity
    bottlenecks{end+1} = 'extraction';
    scores(end+1) = min(1, 1 - (extractionCapacity / processingCapacity));
end

% Check processing bottleneck (based on manufacturing capacity comparison)
if processingCapacity < 0.8 * manufacturingCapacity
    % Identify which processing subsystem has lowest capacity
    mreCapacity = 0;
    if factory.processingMRE.mass > 0
        mreCapacity = factory.processingMRE.mass * factory.processingMRE.oxygenPerUnitPerYear / factory.processingMRE.units;
    end
    
    hclCapacity = 0;
    if factory.processingHCl.mass > 0
        hclCapacity = factory.processingHCl.mass / factory.processingHCl.massScalingFactor;
    end
    
    vpCapacity = 0;
    if factory.processingVP.mass > 0
        vpCapacity = factory.processingVP.mass / factory.processingVP.massScalingFactor;
    end
    
    % Add the lowest capacity processing subsystem as bottleneck
    if mreCapacity <= hclCapacity && mreCapacity <= vpCapacity && factory.processingMRE.mass > 0
        bottlenecks{end+1} = 'processingMRE';
        scores(end+1) = min(1, 1 - (mreCapacity / max([hclCapacity, vpCapacity])));
    elseif hclCapacity <= mreCapacity && hclCapacity <= vpCapacity && factory.processingHCl.mass > 0
        bottlenecks{end+1} = 'processingHCl';
        scores(end+1) = min(1, 1 - (hclCapacity / max([mreCapacity, vpCapacity])));
    elseif vpCapacity <= mreCapacity && vpCapacity <= hclCapacity && factory.processingVP.mass > 0
        bottlenecks{end+1} = 'processingVP';
        scores(end+1) = min(1, 1 - (vpCapacity / max([mreCapacity, hclCapacity])));
    end
end

% Check manufacturing bottleneck (based on processing and assembly capacity)
if manufacturingCapacity < 0.8 * min(processingCapacity, assemblyCapacity)
    % Identify which manufacturing subsystem has lowest capacity
    lpbfCapacity = 0;
    if factory.manufacturingLPBF.mass > 0
        lpbfCapacity = factory.manufacturingLPBF.mass / factory.manufacturingLPBF.massPerUnit;
    end
    
    EBPVDCapacity = 0;
    if factory.manufacturingEBPVD.mass > 0
        EBPVDCapacity = factory.manufacturingEBPVD.mass / factory.manufacturingEBPVD.massScalingFactor;
    end
    
    scCapacity = 0;
    if isfield(factory.manufacturingSC, 'mass') && factory.manufacturingSC.mass > 0
        scCapacity = factory.manufacturingSC.mass / factory.manufacturingSC.massScalingFactor;
    end
    
    pcCapacity = 0;
    if factory.manufacturingPC.mass > 0
        pcCapacity = factory.manufacturingPC.mass / factory.manufacturingPC.massScalingFactor;
    end
    
    sslsCapacity = 0;
    if factory.manufacturingSSLS.mass > 0
        sslsCapacity = factory.manufacturingSSLS.mass / factory.manufacturingSSLS.massScalingFactor;
    end
    
    manufacturingCapacities = [lpbfCapacity, EBPVDCapacity, scCapacity, pcCapacity, sslsCapacity];
    manufacturingSubsystems = {'manufacturingLPBF', 'manufacturingEBPVD', 'manufacturingSC', 'manufacturingPC', 'manufacturingSSLS'};
    
    % Find minimum capacity that's greater than zero
    nonZeroCapacities = manufacturingCapacities(manufacturingCapacities > 0);
    if ~isempty(nonZeroCapacities)
        minCapacity = min(nonZeroCapacities);
        minIndex = find(manufacturingCapacities == minCapacity, 1);
        
        bottlenecks{end+1} = manufacturingSubsystems{minIndex};
        scores(end+1) = min(1, 1 - (minCapacity / max(manufacturingCapacities)));
    end
end

% Check assembly bottleneck (based on manufacturing capacity)
if assemblyCapacity < 0.8 * manufacturingCapacity
    bottlenecks{end+1} = 'assembly';
    scores(end+1) = min(1, 1 - (assemblyCapacity / manufacturingCapacity));
end

return;
end

function capacity = calculateExtractionCapacity(factory)
% Calculate extraction capacity in kg/hr
capacity = factory.extraction.units * factory.extraction.excavationRate;
end

function capacity = calculateProcessingCapacity(factory)
% Calculate processing capacity in kg/hr (simplified)
% Sum capacities of different processing subsystems
capacity = 0;

% MRE capacity
if factory.processingMRE.mass > 0
    % Convert annual oxygen production to hourly regolith processing
    oxygenPerYear = factory.processingMRE.oxygenPerYear;
    regolithPerYear = oxygenPerYear * (23720 / 10000); % Based on ratio in documentation
    capacity = capacity + regolithPerYear / (24 * 365); % Convert to hourly
end

% HCl capacity
if factory.processingHCl.mass > 0
    capacity = capacity + factory.processingHCl.mass / factory.processingHCl.massScalingFactor;
end

% VP capacity
if factory.processingVP.mass > 0
    capacity = capacity + factory.processingVP.mass / factory.processingVP.massScalingFactor;
end

return;
end

function capacity = calculateManufacturingCapacity(factory)
% Calculate manufacturing capacity in kg/hr (simplified)
% Sum capacities of different manufacturing subsystems
capacity = 0;

% LPBF capacity
if factory.manufacturingLPBF.mass > 0
    % Sum of input rates for different materials
    totalInputRate = 0;
    if isfield(factory.subConfig.manufacturingLPBF, 'inputRates')
        inputRates = factory.subConfig.manufacturingLPBF.inputRates;
        totalInputRate = inputRates.aluminum + inputRates.iron + inputRates.alumina;
    else
        % Default rates from documentation
        totalInputRate = 0.23 + 0.68 + 0.34;
    end
    
    capacity = capacity + factory.manufacturingLPBF.units * totalInputRate;
end

% EBPVD capacity
if factory.manufacturingEBPVD.mass > 0
    capacity = capacity + factory.manufacturingEBPVD.mass / factory.manufacturingEBPVD.massScalingFactor;
end

% Sand Casting capacity
if isfield(factory, 'manufacturingSC') && factory.manufacturingSC.mass > 0
    if isfield(factory.manufacturingSC, 'massScalingFactor')
        capacity = capacity + factory.manufacturingSC.mass / factory.manufacturingSC.massScalingFactor;
    else
        capacity = capacity + factory.manufacturingSC.mass / 33.3; % Default from documentation
    end
end

% Permanent Casting capacity
if factory.manufacturingPC.mass > 0
    capacity = capacity + factory.manufacturingPC.mass / factory.manufacturingPC.massScalingFactor;
end

% SSLS capacity
if factory.manufacturingSSLS.mass > 0
    capacity = capacity + factory.manufacturingSSLS.mass / factory.manufacturingSSLS.massScalingFactor;
end

return;
end

function capacity = calculateAssemblyCapacity(factory)
% Calculate assembly capacity in kg/hr
capacity = factory.assembly.units * factory.assembly.assemblyCapacity;
end

function displayTimeStepSummary(factory, step)
% Display a summary of the time step for automated simulation
fprintf('\n----- Time Step %d Summary -----\n', step);
fprintf('Total mass: %.2f kg\n', factory.totalMass);
fprintf('Power capacity: %.2f W\n', factory.powerCapacity);
fprintf('Power demand: %.2f W (%.1f%%)\n', factory.powerDemand, (factory.powerDemand / factory.powerCapacity) * 100);

% Display subsystem masses
fprintf('\nSubsystem Masses:\n');
fprintf('  Extraction: %.2f kg\n', factory.extraction.mass);
fprintf('  Processing MRE: %.2f kg\n', factory.processingMRE.mass);
fprintf('  Processing HCl: %.2f kg\n', factory.processingHCl.mass);
fprintf('  Processing VP: %.2f kg\n', factory.processingVP.mass);
fprintf('  Manufacturing LPBF: %.2f kg\n', factory.manufacturingLPBF.mass);
fprintf('  Manufacturing EBPVD: %.2f kg\n', factory.manufacturingEBPVD.mass);
fprintf('  Manufacturing SC: %.2f kg\n', factory.manufacturingSC.mass);
fprintf('  Manufacturing PC: %.2f kg\n', factory.manufacturingPC.mass);
fprintf('  Manufacturing SSLS: %.2f kg\n', factory.manufacturingSSLS.mass);
fprintf('  Assembly: %.2f kg\n', factory.assembly.mass);
fprintf('  Power (Landed Solar): %.2f kg\n', factory.powerLandedSolar.mass);
fprintf('  Power (Lunar Solar): %.2f kg\n', factory.powerLunarSolar.mass);

% Display key resources
fprintf('\nKey Resources:\n');
fprintf('  Regolith: %.2f kg\n', factory.inventory.regolith);
if isfield(factory.inventory, 'aluminum')
    fprintf('  Aluminum: %.2f kg\n', factory.inventory.aluminum);
end
if isfield(factory.inventory, 'iron')
    fprintf('  Iron: %.2f kg\n', factory.inventory.iron);
end
if isfield(factory.inventory, 'castAluminum')
    fprintf('  Cast Aluminum: %.2f kg\n', factory.inventory.castAluminum);
end
if isfield(factory.inventory, 'castIron')
    fprintf('  Cast Iron: %.2f kg\n', factory.inventory.castIron);
end
if isfield(factory.inventory, 'solarThinFilm')
    fprintf('  Solar Thin Film: %.2f kg\n', factory.inventory.solarThinFilm);
end
fprintf('  Non-Replicable Materials: %.2f kg\n', factory.inventory.nonReplicable);

% Display economic results
fprintf('\nEconomic Results:\n');
fprintf('  Revenue: $%.2f\n', factory.economics.revenue(step));
fprintf('  Costs: $%.2f\n', factory.economics.costs(step));
fprintf('  Profit: $%.2f\n', factory.economics.profit(step));
fprintf('  Cumulative Profit: $%.2f\n', factory.economics.cumulativeProfit(step));

fprintf('------------------------------\n');
end