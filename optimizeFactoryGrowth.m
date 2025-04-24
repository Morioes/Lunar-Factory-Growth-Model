function [optimizedStrategy, predictedMetrics] = optimizeFactoryGrowth(factory, weights, lookAheadSteps, initialGuess)
% OPTIMIZEFACTORYGROWTH Optimizes factory growth strategy using a genetic algorithm
%   This function uses a genetic algorithm to optimize resource allocation 
%   strategies for the lunar factory, projecting growth over multiple time steps.
%   Enhanced version that enforces balanced growth between processing and manufacturing.
%
%   Inputs:
%       factory - LunarFactory object containing current state
%       weights - Structure with weights for fitness function components
%           .expansion - Weight for factory expansion (0-1)
%           .powerExpansion - Weight for power generation expansion (0-1)
%           .selfReliance - Weight for factory self-reliance (0-1)
%           .revenue - Weight for revenue generation (0-1)
%           .cost - Weight for cost minimization (0-1)
%           .timePreference - Weight for time preference (0-1)
%       lookAheadSteps - Number of time steps to look ahead for evaluation
%       initialGuess - Initial resource allocation strategy (optional)
%
%   Outputs:
%       optimizedStrategy - Optimized resource allocation strategy
%       predictedMetrics - Predicted performance metrics using the optimized strategy

% Handle optional inputs and default weights
if nargin < 3 || isempty(lookAheadSteps)
    lookAheadSteps = 3;
end

if nargin < 2 || isempty(weights)
    % Default weights if not provided
    weights = struct();
    weights.expansion = 0.3;        % Reduced from 0.4
    weights.powerExpansion = 0.2;   % New weight for power growth
    weights.selfReliance = 0.15;    % Reduced from 0.2
    weights.revenue = 0.2;          % Reduced from 0.3
    weights.cost = 0.05;            % Reduced from 0.1
end

% ENHANCEMENT: Adjust weights based on factory balance state
weights = adjustOptimizationWeights(factory, weights);

% Ensure powerExpansion field exists (backward compatibility)
if ~isfield(weights, 'powerExpansion')
    % Add powerExpansion field with default value
    weights.powerExpansion = 0.2;
    
    % Adjust other weights to maintain proportions but sum to 1.0
    totalWeight = weights.expansion + weights.selfReliance + weights.revenue + weights.cost;
    if totalWeight > 0.8  % If sum is greater than 0.8, we need to reduce to make room for powerExpansion
        scaleFactor = 0.8 / totalWeight;
        weights.expansion = weights.expansion * scaleFactor;
        weights.selfReliance = weights.selfReliance * scaleFactor;
        weights.revenue = weights.revenue * scaleFactor;
        weights.cost = weights.cost * scaleFactor;
    end
end

% ENHANCEMENT: Display the current processing-to-manufacturing ratio
processingCapacity = calculateProcessingCapacity(factory);
manufacturingCapacity = calculateManufacturingCapacity(factory);
if manufacturingCapacity > 0
    ratio = processingCapacity / manufacturingCapacity;
    fprintf('Current processing-to-manufacturing ratio: %.4f\n', ratio);
    
    % Warn about bottlenecks
    if ratio < 0.1
        fprintf('CRITICAL BOTTLENECK: Processing capacity is only %.1f%% of manufacturing capacity!\n', ratio * 100);
    elseif ratio < 0.3
        fprintf('SEVERE BOTTLENECK: Processing capacity is only %.1f%% of manufacturing capacity!\n', ratio * 100);
    elseif ratio < 0.5
        fprintf('MODERATE BOTTLENECK: Processing capacity is only %.1f%% of manufacturing capacity!\n', ratio * 100);
    elseif ratio < 0.8
        fprintf('MILD BOTTLENECK: Processing capacity is only %.1f%% of manufacturing capacity!\n', ratio * 100);
    else
        fprintf('Factory is well-balanced (processing capacity: %.1f%% of manufacturing)\n', ratio * 100);
    end
end

% Genetic Algorithm Parameters
popSize = 30;               % Population size
maxGenerations = 20;        % Maximum number of generations
tournamentSize = 3;         % Tournament size for selection
crossoverRate = 0.8;        % Probability of crossover
mutationRate = 0.2;         % Probability of mutation
elitismCount = 2;           % Number of best individuals to preserve unchanged

% ENHANCEMENT: Adjust GA parameters based on bottleneck severity
if ratio < 0.3
    popSize = 40;           % Larger population for more exploration
    maxGenerations = 30;    % More generations to find better solutions
    mutationRate = 0.3;     % Higher mutation rate to explore more strategies
    fprintf('Adjusted GA parameters due to severe bottleneck: population=%d, generations=%d, mutation=%.2f\n', ...
            popSize, maxGenerations, mutationRate);
end

% Display optimization progress
fprintf('Starting genetic algorithm optimization...\n');
fprintf('Population size: %d, Generations: %d\n', popSize, maxGenerations);
fprintf('Look-ahead steps: %d\n', lookAheadSteps);
fprintf('Weights: Expansion=%.2f, PowerExpansion=%.2f, SelfReliance=%.2f, Revenue=%.2f, Cost=%.2f\n', ...
        weights.expansion, weights.powerExpansion, weights.selfReliance, weights.revenue, weights.cost);

% ENHANCEMENT: If processing bottleneck is severe, provide a special initial guess
if nargin < 4 || isempty(initialGuess)
    if manufacturingCapacity > 0 && processingCapacity / manufacturingCapacity < 0.3
        fprintf('Using specialized initial guess to prioritize processing growth\n');
        initialGuess = createProcessingPriorityStrategy(factory);
    end
end

% Initialize population
population = initializePopulation(popSize, factory, initialGuess);

% Evaluate initial population
fitnessScores = zeros(popSize, 1);
for i = 1:popSize
    fitnessScores(i) = evaluateFitness(population{i}, factory, weights, lookAheadSteps);
end

% Main genetic algorithm loop
bestFitness = -Inf;
bestStrategy = [];
converged = false;
generation = 1;

% Progress tracking
fitnessHistory = zeros(maxGenerations, 3); % [min, mean, max]
bestPowerCapacity = factory.powerCapacity; % Track best power capacity achieved

while generation <= maxGenerations && ~converged
    fprintf('Generation %d of %d: ', generation, maxGenerations);
    
    % Sort population by fitness
    [fitnessScores, sortIdx] = sort(fitnessScores, 'descend');
    population = population(sortIdx);
    
    % Get metrics of best individual
    factoryCopy = copyFactoryForSimulation(factory);
    [~, bestMetrics] = simulateStrategy(population{1}, factoryCopy, lookAheadSteps);
    
    % ENHANCEMENT: Check for processing growth in the best individual
    processingGrowth = false;
    if isfield(bestMetrics, 'processingMREGrowth') && bestMetrics.processingMREGrowth > 0
        processingGrowth = true;
    elseif isfield(bestMetrics, 'processingHClGrowth') && bestMetrics.processingHClGrowth > 0
        processingGrowth = true;
    elseif isfield(bestMetrics, 'processingVPGrowth') && bestMetrics.processingVPGrowth > 0
        processingGrowth = true;
    end
    
    if processingGrowth
        fprintf('Best strategy includes processing system growth! ');
    end
    
    % Record best strategy if improved
    if fitnessScores(1) > bestFitness
        bestFitness = fitnessScores(1);
        bestStrategy = population{1};
        bestPowerCapacity = bestMetrics.finalPowerCapacity;
    end
    
    % Record fitness statistics
    fitnessHistory(generation, 1) = min(fitnessScores);
    fitnessHistory(generation, 2) = mean(fitnessScores);
    fitnessHistory(generation, 3) = max(fitnessScores);
    
    % Report progress
    fprintf('Best Fitness = %.4f, Mean Fitness = %.4f, Power Capacity = %.2f W\n', ...
           fitnessScores(1), mean(fitnessScores), bestMetrics.finalPowerCapacity);
    
    % Check for convergence
    if generation > 5 && (fitnessHistory(generation, 3) - fitnessHistory(generation-5, 3)) < 0.001
        fprintf('Optimization converged after %d generations\n', generation);
        converged = true;
    end
    
    % Create new population through selection, crossover, and mutation
    newPopulation = cell(popSize, 1);
    
    % Elitism: Keep best individuals unchanged
    newPopulation(1:elitismCount) = population(1:elitismCount);
    
    % Fill rest of population
    for i = elitismCount+1:popSize
        % Selection
        parent1Idx = tournamentSelection(fitnessScores, tournamentSize);
        parent2Idx = tournamentSelection(fitnessScores, tournamentSize);
        
        % Crossover
        if rand() < crossoverRate
            newPopulation{i} = crossover(population{parent1Idx}, population{parent2Idx});
        else
            newPopulation{i} = population{parent1Idx}; % Clone parent1
        end
        
        % Mutation
        if rand() < mutationRate
            newPopulation{i} = mutate(newPopulation{i}, factory);
        end
        
        % ENHANCEMENT: Ensure strategy maintains factory balance
        if isManufacturingUnbalanced(factory)
            newPopulation{i} = enforceProcessingPriority(newPopulation{i}, factory);
        end
    end
    
    % Update population
    population = newPopulation;
    
    % Evaluate new population
    for i = elitismCount+1:popSize % Skip evaluation for elite individuals
        fitnessScores(i) = evaluateFitness(population{i}, factory, weights, lookAheadSteps);
    end
    
    generation = generation + 1;
end

% Ensure we have the true best strategy
[~, bestIndex] = max(fitnessScores);
if fitnessScores(bestIndex) > bestFitness
    bestStrategy = population{bestIndex};
end

% If no good solution found, create a balanced default strategy
if isempty(bestStrategy)
    bestStrategy = createProcessingPriorityStrategy(factory);
    fprintf('Warning: No good strategy found. Using default balanced strategy.\n');
end

% ENHANCEMENT: If processing bottleneck exists but best strategy doesn't grow processing,
% force processing growth by modifying the best strategy
factoryCopy = copyFactoryForSimulation(factory);
[~, predictedMetrics] = simulateStrategy(bestStrategy, factoryCopy, lookAheadSteps);

processingGrowth = false;
if isfield(predictedMetrics, 'processingMREGrowth') && predictedMetrics.processingMREGrowth > 0
    processingGrowth = true;
elseif isfield(predictedMetrics, 'processingHClGrowth') && predictedMetrics.processingHClGrowth > 0
    processingGrowth = true;
elseif isfield(predictedMetrics, 'processingVPGrowth') && predictedMetrics.processingVPGrowth > 0
    processingGrowth = true;
end

if isManufacturingUnbalanced(factory) && ~processingGrowth
    fprintf('WARNING: Best strategy does not grow processing despite bottleneck. Enforcing processing growth.\n');
    bestStrategy = enforceProcessingPriority(bestStrategy, factory);
    
    % Re-evaluate the modified strategy
    factoryCopy = copyFactoryForSimulation(factory);
    [~, predictedMetrics] = simulateStrategy(bestStrategy, factoryCopy, lookAheadSteps);
end

% Return the optimized strategy
optimizedStrategy = bestStrategy;
fprintf('Final optimization complete. Best fitness score: %.4f\n', bestFitness);
end

% ENHANCEMENT: Create a strategy focused on processing growth
function strategy = createProcessingPriorityStrategy(factory)
% Creates a strategy that prioritizes processing systems

% Initialize strategy structure
strategy = struct();

% Generate power distribution with emphasis on processing
powerDist = struct();
powerDistTotal = 0;

% Set high power allocation for processing systems
powerDist.processingMRE = 0.35; % 30% of power to MRE
powerDistTotal = powerDistTotal + 0.35;

powerDist.processingHCl = 0.30; % 25% of power to HCl
powerDistTotal = powerDistTotal + 0.30;

powerDist.processingVP = 0.05; % 5% of power to VP (if present)
powerDistTotal = powerDistTotal + 0.05;

% Essential systems get moderate allocation
powerDist.extraction = 0.05; % 10% to extraction
powerDistTotal = powerDistTotal + 0.05;

powerDist.assembly = 0.10; % 15% to assembly
powerDistTotal = powerDistTotal + 0.10;

% Manufacturing systems get reduced allocation
powerDist.manufacturingLPBF = 0.04;
powerDistTotal = powerDistTotal + 0.04;

powerDist.manufacturingEBPVD = 0.04;
powerDistTotal = powerDistTotal + 0.04;

powerDist.manufacturingSC = 0.03;
powerDistTotal = powerDistTotal + 0.03;

powerDist.manufacturingPC = 0.02;
powerDistTotal = powerDistTotal + 0.02;

powerDist.manufacturingSSLS = 0.02;
powerDistTotal = powerDistTotal + 0.02;

% Normalize to ensure sum is 1.0
fields = fieldnames(powerDist);
for i = 1:length(fields)
    powerDist.(fields{i}) = powerDist.(fields{i}) / powerDistTotal;
end

strategy.powerDistribution = powerDist;

% Set production allocation with emphasis on self-replication
strategy.productionAllocation = struct();
strategy.productionAllocation.replication = 0.95; % 80% for replication
strategy.productionAllocation.sales = 0.05; % 20% for sales

strategy.productionAllocation.oxygen = 0.75; % 25% of oxygen for sales
strategy.productionAllocation.castSlag = 0.35; % 35% of cast slag for sales

% Solar thin film should be used primarily for power
strategy.productionAllocation.solarThinFilm = 0.95; % 90% for power generation

% LPBF allocation
strategy.productionAllocation.lpbf = struct();
strategy.productionAllocation.lpbf.aluminum = 0.40;
strategy.productionAllocation.lpbf.iron = 0.35;
strategy.productionAllocation.lpbf.alumina = 0.25;

% Sand Casting allocation
strategy.productionAllocation.sc = struct();
strategy.productionAllocation.sc.aluminum = 0.30;
strategy.productionAllocation.sc.iron = 0.40;
strategy.productionAllocation.sc.slag = 0.30;

% Permanent Casting allocation
strategy.productionAllocation.pc = struct();
strategy.productionAllocation.pc.aluminum = 0.60;
strategy.productionAllocation.pc.slag = 0.40;

% SSLS allocation
strategy.productionAllocation.ssls = struct();
strategy.productionAllocation.ssls.silica = 0.30;
strategy.productionAllocation.ssls.alumina = 0.25;
strategy.productionAllocation.ssls.regolith = 0.45;

% EBPVD allocation
strategy.productionAllocation.EBPVD = struct();
strategy.productionAllocation.EBPVD.active = true;
strategy.productionAllocation.EBPVD.percentage = 0.90;

return;
end

% ENHANCEMENT: Enforce balanced growth by modifying a strategy
function strategy = enforceProcessingPriority(strategy, factory)
% Modify a strategy to prioritize processing systems

% Boost power allocation to processing systems
if isfield(strategy, 'powerDistribution')
    processingFields = {'processingMRE', 'processingHCl', 'processingVP'};
    manufacturingFields = {'manufacturingLPBF', 'manufacturingEBPVD', 'manufacturingSC', 'manufacturingPC', 'manufacturingSSLS'};
    
    % Calculate current allocation to processing vs manufacturing
    processingAllocation = 0;
    for i = 1:length(processingFields)
        if isfield(strategy.powerDistribution, processingFields{i})
            processingAllocation = processingAllocation + strategy.powerDistribution.(processingFields{i});
        end
    end
    
    manufacturingAllocation = 0;
    for i = 1:length(manufacturingFields)
        if isfield(strategy.powerDistribution, manufacturingFields{i})
            manufacturingAllocation = manufacturingAllocation + strategy.powerDistribution.(manufacturingFields{i});
        end
    end
    
    % If manufacturing gets more power than processing, redistribute
    if manufacturingAllocation > processingAllocation * 1.2
        fprintf('Redistributing power from manufacturing (%.2f) to processing (%.2f)\n', ...
                manufacturingAllocation, processingAllocation);
        
        % Calculate how much to redistribute
        redistributionAmount = (manufacturingAllocation - processingAllocation * 0.8) * 0.5;
        
        % Reduce manufacturing allocations proportionally
        for i = 1:length(manufacturingFields)
            if isfield(strategy.powerDistribution, manufacturingFields{i})
                reductionFactor = strategy.powerDistribution.(manufacturingFields{i}) / manufacturingAllocation;
                strategy.powerDistribution.(manufacturingFields{i}) = strategy.powerDistribution.(manufacturingFields{i}) - (redistributionAmount * reductionFactor);
            end
        end
        
        % Increase processing allocations proportionally
        for i = 1:length(processingFields)
            if isfield(strategy.powerDistribution, processingFields{i})
                if processingAllocation > 0
                    increaseFactor = strategy.powerDistribution.(processingFields{i}) / processingAllocation;
                    strategy.powerDistribution.(processingFields{i}) = strategy.powerDistribution.(processingFields{i}) + (redistributionAmount * increaseFactor);
                else
                    % If no current processing allocation, distribute evenly
                    strategy.powerDistribution.(processingFields{i}) = strategy.powerDistribution.(processingFields{i}) + (redistributionAmount / length(processingFields));
                end
            else
                % If field doesn't exist, create it
                strategy.powerDistribution.(processingFields{i}) = redistributionAmount / length(processingFields);
            end
        end
        
        % Ensure MRE and HCl get at least minimum allocations
        if isfield(strategy.powerDistribution, 'processingMRE')
            strategy.powerDistribution.processingMRE = max(strategy.powerDistribution.processingMRE, 0.15);
        else
            strategy.powerDistribution.processingMRE = 0.15;
        end
        
        if isfield(strategy.powerDistribution, 'processingHCl')
            strategy.powerDistribution.processingHCl = max(strategy.powerDistribution.processingHCl, 0.15);
        else
            strategy.powerDistribution.processingHCl = 0.15;
        end
        
        % If VP doesn't exist in factory, less important to give it power
        if factory.processingVP.mass == 0
                strategy.powerDistribution.processingVP = 0.05;

        end
        
        % Normalize to ensure sum is 1.0
        fields = fieldnames(strategy.powerDistribution);
        totalAllocation = 0;
        for i = 1:length(fields)
            totalAllocation = totalAllocation + strategy.powerDistribution.(fields{i});
        end
        
        for i = 1:length(fields)
            strategy.powerDistribution.(fields{i}) = strategy.powerDistribution.(fields{i}) / totalAllocation;
        end
    end
end

% Increase replication vs sales to enable more processing growth
if isfield(strategy, 'productionAllocation')
    if isfield(strategy.productionAllocation, 'replication')
        strategy.productionAllocation.replication = max(strategy.productionAllocation.replication, 0.75);
        strategy.productionAllocation.sales = 1 - strategy.productionAllocation.replication;
    end
end

return;
end

%% Population Initialization and Management Functions

function population = initializePopulation(popSize, factory, initialGuess)
% Initialize a population of allocation strategies

population = cell(popSize, 1);

% Generate initial population
for i = 1:popSize
    if i == 1 && ~isempty(initialGuess)
        % Use initialGuess as first individual if provided
        population{i} = initialGuess;
    else
        % Create random strategies for the rest
        if i == 2 && isempty(initialGuess)
            % Add a balanced strategy as second individual if no initial guess
            population{i} = createDefaultStrategy(factory);
        else
            % Create completely random strategies
            population{i} = createRandomStrategy(factory, 0.2); % Add noise parameter
        end
    end
end
end

function strategy = createRandomStrategy(factory, noise)
% Creates a random allocation strategy with optional noise around defaults

if nargin < 2
    noise = 0.5; % Default noise level
end

% Initialize strategy structure
strategy = struct();

% Generate power distribution with values summing to 1
strategy.powerDistribution = generateRandomPowerDistribution(factory, noise);

% Generate production allocation
strategy.productionAllocation = generateRandomProductionAllocation(factory, noise);

% Make adjustments based on factory state
strategy = adjustStrategyToFactoryState(strategy, factory);

end

function powerDist = generateRandomPowerDistribution(factory, noise)
% Generates a random power distribution based on current factory state

% Get default values as starting point
defaultPowerDist = factory.powerDistribution;
fields = fieldnames(defaultPowerDist);
powerDist = struct();

% Generate random values
rawValues = zeros(length(fields), 1);
for i = 1:length(fields)
    % Get base value, ensuring all subsystems get some power
    baseValue = max(0.05, defaultPowerDist.(fields{i}));
    
    % Apply random noise within constraints
    rawValues(i) = baseValue * (1 + noise * (2*rand() - 1));
    
    % Ensure non-zero subsystems get at least a minimum allocation
    if factory.(fields{i}).mass > 0
        rawValues(i) = max(0.01, rawValues(i));
    end
end

% Normalize to sum to 1
rawValues = rawValues / sum(rawValues);

% Assign to structure
for i = 1:length(fields)
    powerDist.(fields{i}) = rawValues(i);
end
end

function prodAlloc = generateRandomProductionAllocation(factory, noise)
% Generates a random production allocation

if nargin < 2
    noise = 0.5; % Default noise level
end

prodAlloc = struct();

% Base allocation between replication and sales
baseReplication = 0.7; % 70% to replication by default
prodAlloc.replication = min(0.95, max(0.5, baseReplication * (1 + noise * (2*rand() - 1))));
prodAlloc.sales = 1 - prodAlloc.replication;

% Oxygen and cast slag sales allocation
baseOxygenAlloc = 0.3;
prodAlloc.oxygen = min(0.8, max(0.1, baseOxygenAlloc * (1 + noise * (2*rand() - 1))));

baseSlagAlloc = 0.4;
prodAlloc.castSlag = min(0.8, max(0.1, baseSlagAlloc * (1 + noise * (2*rand() - 1))));

% Solar thin film allocation for power generation
baseSTFAlloc = 0.7;
prodAlloc.solarThinFilm = min(0.95, max(0.3, baseSTFAlloc * (1 + noise * (2*rand() - 1))));

% LPBF allocation (if available)
if factory.manufacturingLPBF.mass > 0
    prodAlloc.lpbf = struct();
    prodAlloc.lpbf.aluminum = 0.4;
    prodAlloc.lpbf.iron = 0.3;
    prodAlloc.lpbf.alumina = 0.3;
    
    % Randomize proportions
    total = prodAlloc.lpbf.aluminum + prodAlloc.lpbf.iron + prodAlloc.lpbf.alumina;
    prodAlloc.lpbf.aluminum = min(0.8, max(0.1, prodAlloc.lpbf.aluminum * (1 + noise * (2*rand() - 1))));
    prodAlloc.lpbf.iron = min(0.8, max(0.1, prodAlloc.lpbf.iron * (1 + noise * (2*rand() - 1))));
    prodAlloc.lpbf.alumina = min(0.8, max(0.1, prodAlloc.lpbf.alumina * (1 + noise * (2*rand() - 1))));
    
    % Re-normalize to ensure they sum to at most 1
    newTotal = prodAlloc.lpbf.aluminum + prodAlloc.lpbf.iron + prodAlloc.lpbf.alumina;
    if newTotal > 1
        prodAlloc.lpbf.aluminum = prodAlloc.lpbf.aluminum / newTotal;
        prodAlloc.lpbf.iron = prodAlloc.lpbf.iron / newTotal;
        prodAlloc.lpbf.alumina = prodAlloc.lpbf.alumina / newTotal;
    end
end

% Sand Casting allocation (if available)
if isfield(factory, 'manufacturingSC') && factory.manufacturingSC.mass > 0
    prodAlloc.sc = struct();
    prodAlloc.sc.aluminum = 0.2;
    prodAlloc.sc.iron = 0.4;
    prodAlloc.sc.slag = 0.4;
    
    % Randomize proportions
    prodAlloc.sc.aluminum = min(0.8, max(0.1, prodAlloc.sc.aluminum * (1 + noise * (2*rand() - 1))));
    prodAlloc.sc.iron = min(0.8, max(0.1, prodAlloc.sc.iron * (1 + noise * (2*rand() - 1))));
    prodAlloc.sc.slag = min(0.8, max(0.1, prodAlloc.sc.slag * (1 + noise * (2*rand() - 1))));
    
    % Re-normalize to ensure they sum to at most 1
    total = prodAlloc.sc.aluminum + prodAlloc.sc.iron + prodAlloc.sc.slag;
    if total > 1
        prodAlloc.sc.aluminum = prodAlloc.sc.aluminum / total;
        prodAlloc.sc.iron = prodAlloc.sc.iron / total;
        prodAlloc.sc.slag = prodAlloc.sc.slag / total;
    end
end

% Permanent Casting allocation (if available)
if factory.manufacturingPC.mass > 0
    prodAlloc.pc = struct();
    prodAlloc.pc.aluminum = 0.6;
    prodAlloc.pc.slag = 0.4;
    
    % Modified: Randomize with independent values, allowing sum < 1
    prodAlloc.pc.aluminum = min(0.8, max(0.1, prodAlloc.pc.aluminum * (1 + noise * (2*rand() - 1))));
    prodAlloc.pc.slag = min(0.8, max(0.1, prodAlloc.pc.slag * (1 + noise * (2*rand() - 1))));
    
    % Only normalize if sum > 1
    total = prodAlloc.pc.aluminum + prodAlloc.pc.slag;
    if total > 1
        prodAlloc.pc.aluminum = prodAlloc.pc.aluminum / total;
        prodAlloc.pc.slag = prodAlloc.pc.slag / total;
    end
end

% SSLS allocation (if available)
if factory.manufacturingSSLS.mass > 0
    prodAlloc.ssls = struct();
    prodAlloc.ssls.silica = 0.3;
    prodAlloc.ssls.alumina = 0.25;
    prodAlloc.ssls.regolith = 0.45;
    
    % Randomize proportions
    prodAlloc.ssls.silica = min(0.8, max(0.1, prodAlloc.ssls.silica * (1 + noise * (2*rand() - 1))));
    prodAlloc.ssls.alumina = min(0.8, max(0.1, prodAlloc.ssls.alumina * (1 + noise * (2*rand() - 1))));
    prodAlloc.ssls.regolith = min(0.8, max(0.1, prodAlloc.ssls.regolith * (1 + noise * (2*rand() - 1))));
    
    % Re-normalize to ensure they sum to at most 1
    total = prodAlloc.ssls.silica + prodAlloc.ssls.alumina + prodAlloc.ssls.regolith;
    if total > 1
        prodAlloc.ssls.silica = prodAlloc.ssls.silica / total;
        prodAlloc.ssls.alumina = prodAlloc.ssls.alumina / total;
        prodAlloc.ssls.regolith = prodAlloc.ssls.regolith / total;
    end
end

% EBPVD allocation (if available)
if factory.manufacturingEBPVD.mass > 0
    prodAlloc.EBPVD = struct();
    prodAlloc.EBPVD.active = true;
    prodAlloc.EBPVD.percentage = min(1.0, max(0.3, 0.8 * (1 + noise * (2*rand() - 1))));
end
end

function strategy = createDefaultStrategy(factory)
% Creates a balanced default strategy for the factory based on actual subsystem capacities

strategy = struct();

% Analyze current factory configuration
factory.calculatePowerCapacity();
factory.calculatePowerDemand();
powerUtilization = factory.powerDemand / factory.powerCapacity;

% Initialize power distribution with zeros
strategy.powerDistribution = struct();
subsystems = {'extraction', 'processingMRE', 'processingHCl', 'processingVP', ...
              'manufacturingLPBF', 'manufacturingEBPVD', 'manufacturingSC', ...
              'manufacturingPC', 'manufacturingSSLS', 'assembly'};
              
for i = 1:length(subsystems)
    strategy.powerDistribution.(subsystems{i}) = 0;
end

% Calculate theoretical power needs for all active subsystems
subsystemNeeds = zeros(length(subsystems), 1);
for i = 1:length(subsystems)
    subsystem = subsystems{i};
    subsystemNeeds(i) = calculateSubsystemPowerNeed(factory, subsystem);
end

% Allocate power based on needs
totalNeeds = sum(subsystemNeeds);
if totalNeeds > 0
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        % Calculate base allocation proportional to theoretical needs
        if subsystemNeeds(i) > 0
            strategy.powerDistribution.(subsystem) = subsystemNeeds(i) / totalNeeds;
        else
            strategy.powerDistribution.(subsystem) = 0;
        end
    end
else
    % Fallback if no needs detected - evenly distribute to active subsystems
    activeSubsystems = 0;
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        if hasSubsystemMass(factory, subsystem)
            activeSubsystems = activeSubsystems + 1;
        end
    end
    
    if activeSubsystems > 0
        for i = 1:length(subsystems)
            subsystem = subsystems{i};
            if hasSubsystemMass(factory, subsystem)
                strategy.powerDistribution.(subsystem) = 1 / activeSubsystems;
            else
                strategy.powerDistribution.(subsystem) = 0;
            end
        end
    else
        % Extreme fallback - shouldn't happen
        for i = 1:length(subsystems)
            strategy.powerDistribution.(subsystems{i}) = 1 / length(subsystems);
        end
    end
end

% Make strategic adjustments based on factory state
% Adjust for bottlenecks or critical needs
if powerUtilization > 0.9
    % Critical power shortage - prioritize power generation chain
    if hasSubsystemMass(factory, 'manufacturingEBPVD')
        strategy.powerDistribution.manufacturingEBPVD = strategy.powerDistribution.manufacturingEBPVD * 1.5;
    end
    if hasSubsystemMass(factory, 'assembly')
        strategy.powerDistribution.assembly = strategy.powerDistribution.assembly * 1.2;
    end
end

% Material shortages - prioritize extraction if regolith is low
if factory.inventory.regolith < 500 && hasSubsystemMass(factory, 'extraction')
    strategy.powerDistribution.extraction = strategy.powerDistribution.extraction * 1.5;
end

% Re-normalize power distribution
totalAllocation = 0;
for i = 1:length(subsystems)
    totalAllocation = totalAllocation + strategy.powerDistribution.(subsystems{i});
end
if totalAllocation > 0
    for i = 1:length(subsystems)
        subsystem = subsystems{i};
        strategy.powerDistribution.(subsystem) = strategy.powerDistribution.(subsystem) / totalAllocation;
    end
end

% Set default production allocation
strategy.productionAllocation = struct();
strategy.productionAllocation.replication = 0.7;
strategy.productionAllocation.sales = 0.3;
strategy.productionAllocation.oxygen = 0.3;
strategy.productionAllocation.castSlag = 0.4;
strategy.productionAllocation.solarThinFilm = 0.7;

% LPBF allocation
if factory.manufacturingLPBF.mass > 0
    strategy.productionAllocation.lpbf = struct();
    strategy.productionAllocation.lpbf.aluminum = 0.4;
    strategy.productionAllocation.lpbf.iron = 0.3;
    strategy.productionAllocation.lpbf.alumina = 0.3;
end

% Sand Casting allocation
if isfield(factory, 'manufacturingSC') && factory.manufacturingSC.mass > 0
    strategy.productionAllocation.sc = struct();
    strategy.productionAllocation.sc.aluminum = 0.2;
    strategy.productionAllocation.sc.iron = 0.4;
    strategy.productionAllocation.sc.slag = 0.4;
end

% Permanent Casting allocation - Modified to allow less than 100% total
if factory.manufacturingPC.mass > 0
    strategy.productionAllocation.pc = struct();
    strategy.productionAllocation.pc.aluminum = 0.5; % Default value reduced to allow for reserves
    strategy.productionAllocation.pc.slag = 0.3;     % Default value reduced to allow for reserves
end

% SSLS allocation
if factory.manufacturingSSLS.mass > 0
    strategy.productionAllocation.ssls = struct();
    strategy.productionAllocation.ssls.silica = 0.3;
    strategy.productionAllocation.ssls.alumina = 0.25;
    strategy.productionAllocation.ssls.regolith = 0.45;
end

% EBPVD allocation
if factory.manufacturingEBPVD.mass > 0
    strategy.productionAllocation.EBPVD = struct();
    strategy.productionAllocation.EBPVD.active = true;
    strategy.productionAllocation.EBPVD.percentage = 0.8;
end

% Add any context-sensitive adjustments
strategy = adjustStrategyToFactoryState(strategy, factory);

return;
end

function hasMass = hasSubsystemMass(factory, subsystem)
% Checks if a subsystem has mass/units in the factory

hasMass = false;

switch subsystem
    case 'extraction'
        hasMass = factory.extraction.mass > 0 && factory.extraction.units > 0;
        
    case 'processingMRE'
        hasMass = factory.processingMRE.mass > 0 && factory.processingMRE.units > 0;
        
    case 'processingHCl'
        hasMass = factory.processingHCl.mass > 0;
        
    case 'processingVP'
        hasMass = factory.processingVP.mass > 0;
        
    case 'manufacturingLPBF'
        hasMass = factory.manufacturingLPBF.mass > 0 && factory.manufacturingLPBF.units > 0;
        
    case 'manufacturingEBPVD'
        hasMass = factory.manufacturingEBPVD.mass > 0;
        
    case 'manufacturingSC'
        hasMass = isfield(factory, 'manufacturingSC') && factory.manufacturingSC.mass > 0;
        
    case 'manufacturingPC'
        hasMass = factory.manufacturingPC.mass > 0;
        
    case 'manufacturingSSLS'
        hasMass = factory.manufacturingSSLS.mass > 0;
        
    case 'assembly'
        hasMass = factory.assembly.mass > 0 && factory.assembly.units > 0;
end

return;
end

function powerNeed = calculateSubsystemPowerNeed(factory, subsystem)
% Calculates theoretical power needs for a subsystem based on its capacity

powerNeed = 0;

% Check if subsystem has mass/units
if ~hasSubsystemMass(factory, subsystem)
    return;
end

% Calculate power need based on subsystem type
switch subsystem
    case 'extraction'
        % Power need based on excavation capacity
        powerNeed = factory.extraction.units * factory.extraction.excavationRate * factory.extraction.energyPerKg;
        
    case 'processingMRE'
        % Power for MRE based on oxygen production capacity
        N = factory.processingMRE.oxygenPerYear;
        t = factory.processingMRE.dutyCycle;
        powerNeed = 264 * (N/(2*t))^0.577;
        
    case 'processingHCl'
        % Power for HCl based on mass and scaling factors
        if factory.processingHCl.mass > 0
            powerNeed = factory.processingHCl.mass * factory.processingHCl.powerScalingFactor / factory.processingHCl.massScalingFactor;
        end
        
    case 'processingVP'
        % Power for VP based on mass and scaling factors
        if factory.processingVP.mass > 0
            powerNeed = factory.processingVP.mass * factory.processingVP.powerScalingFactor / factory.processingVP.massScalingFactor;
        end
        
    case 'manufacturingLPBF'
        % Power for LPBF based on units
        powerNeed = factory.manufacturingLPBF.units * factory.manufacturingLPBF.powerPerUnit;
        
    case 'manufacturingEBPVD'
        % Power for EBPVD based on production capacity
        if factory.manufacturingEBPVD.mass > 0
            productionCapacity = factory.manufacturingEBPVD.mass / factory.manufacturingEBPVD.massScalingFactor;
            powerNeed = productionCapacity * factory.manufacturingEBPVD.powerScalingFactor;
        end
        
    case 'manufacturingSC'
        % Power for Sand Casting
        if factory.manufacturingSC.mass > 0
            % Safe access to scaling factors
            if isfield(factory.manufacturingSC, 'powerScalingFactor') && isfield(factory.manufacturingSC, 'massScalingFactor')
                powerNeed = factory.manufacturingSC.powerScalingFactor * factory.manufacturingSC.mass / factory.manufacturingSC.massScalingFactor;
            else
                % Default values if not available
                powerNeed = 43.1 * factory.manufacturingSC.mass / 33.3;
            end
        end
        
    case 'manufacturingPC'
        % Power for Permanent Casting
        if factory.manufacturingPC.mass > 0
            powerNeed = factory.manufacturingPC.powerScalingFactor * factory.manufacturingPC.mass / factory.manufacturingPC.massScalingFactor;
        end
        
    case 'manufacturingSSLS'
        % Power for SSLS
        if factory.manufacturingSSLS.mass > 0
            powerNeed = factory.manufacturingSSLS.powerScalingFactor * factory.manufacturingSSLS.mass / factory.manufacturingSSLS.massScalingFactor;
        end
        
    case 'assembly'
        % Power for Assembly
        powerNeed = factory.assembly.units * factory.assembly.powerPerUnit;
end

return;
end

%% Strategy Adjustment Functions

function strategy = adjustStrategyToFactoryState(strategy, factory)
% Makes adjustments to strategy based on the current factory state

% Check for critical material shortages
if factory.inventory.regolith < 500 && factory.extraction.mass > 0
    % Prioritize extraction if regolith is low
    strategy.powerDistribution.extraction = max(0.3, strategy.powerDistribution.extraction);
    
    % Normalize power distribution
    powerFields = fieldnames(strategy.powerDistribution);
    totalPower = sum(struct2array(strategy.powerDistribution));
    for i = 1:length(powerFields)
        strategy.powerDistribution.(powerFields{i}) = strategy.powerDistribution.(powerFields{i}) / totalPower;
    end
end

% Prioritize power generation through EBPVD when power demand is high
powerUtilization = factory.powerDemand / factory.powerCapacity;
if powerUtilization > 0.85 && factory.manufacturingEBPVD.mass > 0
    % If power utilization is high (>85%), prioritize power
    if isfield(strategy.productionAllocation, 'EBPVD')
        strategy.productionAllocation.EBPVD.active = true;
        strategy.productionAllocation.EBPVD.percentage = max(0.9, strategy.productionAllocation.EBPVD.percentage);
    end
    
    if isfield(strategy.productionAllocation, 'solarThinFilm')
        strategy.productionAllocation.solarThinFilm = max(0.9, strategy.productionAllocation.solarThinFilm);
    end
    
    % Prioritize assembly of solar panels
    % Adjust powerDistribution to ensure enough power for assembly
    if isfield(strategy.powerDistribution, 'assembly')
        strategy.powerDistribution.assembly = max(0.15, strategy.powerDistribution.assembly);
        
        % Normalize power distribution again
        powerFields = fieldnames(strategy.powerDistribution);
        totalPower = sum(struct2array(strategy.powerDistribution));
        for i = 1:length(powerFields)
            strategy.powerDistribution.(powerFields{i}) = strategy.powerDistribution.(powerFields{i}) / totalPower;
        end
    end
end

% Check for iron for cast iron if we're low
if isfield(factory.inventory, 'castIron') && factory.inventory.castIron < 100 && isfield(strategy.productionAllocation, 'sc')
    if isfield(factory.inventory, 'iron') && factory.inventory.iron > 0
        strategy.productionAllocation.sc.iron = max(0.6, strategy.productionAllocation.sc.iron);
        
        % Re-normalize SC allocations
        total = strategy.productionAllocation.sc.aluminum + strategy.productionAllocation.sc.iron + strategy.productionAllocation.sc.slag;
        strategy.productionAllocation.sc.aluminum = strategy.productionAllocation.sc.aluminum / total;
        strategy.productionAllocation.sc.iron = strategy.productionAllocation.sc.iron / total;
        strategy.productionAllocation.sc.slag = strategy.productionAllocation.sc.slag / total;
    end
end

% If factory is just starting, prioritize processing and manufacturing
if factory.currentTimeStep <= 2
    % Increase processing allocations
    if isfield(strategy.powerDistribution, 'processingMRE') && factory.processingMRE.mass > 0
        strategy.powerDistribution.processingMRE = max(0.2, strategy.powerDistribution.processingMRE);
    end
    
    if isfield(strategy.powerDistribution, 'processingHCl') && factory.processingHCl.mass > 0
        strategy.powerDistribution.processingHCl = max(0.15, strategy.powerDistribution.processingHCl);
    end
    
    % Re-normalize power distribution
    powerFields = fieldnames(strategy.powerDistribution);
    totalPower = sum(struct2array(strategy.powerDistribution));
    for i = 1:length(powerFields)
        strategy.powerDistribution.(powerFields{i}) = strategy.powerDistribution.(powerFields{i}) / totalPower;
    end
end

return;
end

%% Genetic Algorithm Operations

function selectedIdx = tournamentSelection(fitnessScores, tournamentSize)
% Performs tournament selection to choose a parent

populationSize = length(fitnessScores);
tournament = randperm(populationSize, tournamentSize);
[~, bestInTournament] = max(fitnessScores(tournament));
selectedIdx = tournament(bestInTournament);
end

function child = crossover(parent1, parent2)
% Performs crossover between two parent strategies

child = struct();

% Crossover for power distribution
child.powerDistribution = struct();
powerFields = intersect(fieldnames(parent1.powerDistribution), fieldnames(parent2.powerDistribution));

% Use arithmetic crossover for power distribution
alpha = rand(); % Random weight between parents
rawValues = zeros(length(powerFields), 1);

for i = 1:length(powerFields)
    field = powerFields{i};
    rawValues(i) = alpha * parent1.powerDistribution.(field) + (1-alpha) * parent2.powerDistribution.(field);
end

% Normalize to ensure sum is 1
rawValues = rawValues / sum(rawValues);

% Assign to child
for i = 1:length(powerFields)
    field = powerFields{i};
    child.powerDistribution.(field) = rawValues(i);
end

% Crossover for production allocation
child.productionAllocation = struct();

% Basic allocation parameters (replication, sales, etc.)
basicFields = {'replication', 'sales', 'oxygen', 'castSlag', 'solarThinFilm'};
for i = 1:length(basicFields)
    field = basicFields{i};
    if isfield(parent1.productionAllocation, field) && isfield(parent2.productionAllocation, field)
        child.productionAllocation.(field) = alpha * parent1.productionAllocation.(field) + (1-alpha) * parent2.productionAllocation.(field);
    elseif isfield(parent1.productionAllocation, field)
        child.productionAllocation.(field) = parent1.productionAllocation.(field);
    elseif isfield(parent2.productionAllocation, field)
        child.productionAllocation.(field) = parent2.productionAllocation.(field);
    end
end

% Handle replication vs sales constraint
if isfield(child.productionAllocation, 'replication') && isfield(child.productionAllocation, 'sales')
    child.productionAllocation.sales = 1 - child.productionAllocation.replication;
end

% Manufacturing allocations (LPBF, SC, PC, SSLS, EBPVD)
manufacturingFields = {'lpbf', 'sc', 'pc', 'ssls', 'EBPVD'};
for i = 1:length(manufacturingFields)
    field = manufacturingFields{i};
    
    if isfield(parent1.productionAllocation, field) && isfield(parent2.productionAllocation, field)
        % Handle complex sub-structures with their own constraints
        child.productionAllocation.(field) = crossoverManufacturingAllocation(parent1.productionAllocation.(field), parent2.productionAllocation.(field), field, alpha);
    elseif isfield(parent1.productionAllocation, field)
        child.productionAllocation.(field) = parent1.productionAllocation.(field);
    elseif isfield(parent2.productionAllocation, field)
        child.productionAllocation.(field) = parent2.productionAllocation.(field);
    end
end

return;
end

function childAlloc = crossoverManufacturingAllocation(parent1Alloc, parent2Alloc, allocType, alpha)
% Specialized crossover for manufacturing allocations

childAlloc = struct();
fields = union(fieldnames(parent1Alloc), fieldnames(parent2Alloc));

% For each field in the allocation
for i = 1:length(fields)
    field = fields{i};
    
    % If both parents have the field
    if isfield(parent1Alloc, field) && isfield(parent2Alloc, field)
        % If the field is a struct, recurse
        if isstruct(parent1Alloc.(field)) && isstruct(parent2Alloc.(field))
            childAlloc.(field) = crossoverManufacturingAllocation(parent1Alloc.(field), parent2Alloc.(field), [allocType '.' field], alpha);
        else
            % For boolean fields like EBPVD.active
            if islogical(parent1Alloc.(field)) || (isscalar(parent1Alloc.(field)) && (parent1Alloc.(field) == 0 || parent1Alloc.(field) == 1))
                % For boolean fields, choose randomly from parents
                if rand() < 0.5
                    childAlloc.(field) = parent1Alloc.(field);
                else
                    childAlloc.(field) = parent2Alloc.(field);
                end
            else
                % For numeric fields, use arithmetic crossover
                childAlloc.(field) = alpha * parent1Alloc.(field) + (1-alpha) * parent2Alloc.(field);
            end
        end
    % If only one parent has the field
    elseif isfield(parent1Alloc, field)
        childAlloc.(field) = parent1Alloc.(field);
    else
        childAlloc.(field) = parent2Alloc.(field);
    end
end

% Handle special constraints for specific allocation types
if strcmp(allocType, 'pc')
    % Modified Permanent Casting - allow less than 100% total
    materialFields = {'aluminum', 'slag'};
    if all(ismember(materialFields, fields))
        % Calculate sum
        total = sum([childAlloc.aluminum, childAlloc.slag]);
        % Normalize ONLY if total exceeds 1.0, allowing less than 100%
        if total > 1.0
            childAlloc.aluminum = childAlloc.aluminum / total;
            childAlloc.slag = childAlloc.slag / total;
        end
    end
end

return;
end

function strategy = mutate(strategy, factory)
% Performs mutation on a strategy

% Mutation for power distribution
strategy.powerDistribution = mutatePowerDistribution(strategy.powerDistribution);

% Mutation for production allocation
strategy.productionAllocation = mutateProductionAllocation(strategy.productionAllocation, factory);

% Ensure strategy is still valid
strategy = adjustStrategyToFactoryState(strategy, factory);

return;
end

function powerDist = mutatePowerDistribution(powerDist)
% Mutates power distribution values while maintaining sum = 1

fields = fieldnames(powerDist);
numFields = length(fields);

% Choose random fields to mutate
numToMutate = min(3, ceil(rand() * numFields)); % Mutate 1-3 fields
fieldsToMutate = randperm(numFields, numToMutate);

% Get current values
values = zeros(numFields, 1);
for i = 1:numFields
    values(i) = powerDist.(fields{i});
end

% Apply mutations to selected fields
for i = 1:numToMutate
    fieldIdx = fieldsToMutate(i);
    
    % Generate random perturbation
    perturbation = 0.1 * (2*rand() - 1); % +/- 10% change
    
    % Ensure value stays positive
    newValue = max(0.01, values(fieldIdx) * (1 + perturbation));
    
    % Apply mutation
    values(fieldIdx) = newValue;
end

% Normalize to ensure sum is still 1
values = values / sum(values);

% Update power distribution
for i = 1:numFields
    powerDist.(fields{i}) = values(i);
end

return;
end

function prodAlloc = mutateProductionAllocation(prodAlloc, factory)
% Mutates production allocation values

% Mutation for basic allocation values
if isfield(prodAlloc, 'replication')
    % Mutate replication allocation
    perturbation = 0.1 * (2*rand() - 1); % +/- 10% change
    prodAlloc.replication = min(0.95, max(0.5, prodAlloc.replication * (1 + perturbation)));
    prodAlloc.sales = 1 - prodAlloc.replication;
end

if isfield(prodAlloc, 'oxygen')
    % Mutate oxygen allocation
    perturbation = 0.2 * (2*rand() - 1); % +/- 20% change
    prodAlloc.oxygen = min(0.8, max(0.1, prodAlloc.oxygen * (1 + perturbation)));
end

if isfield(prodAlloc, 'castSlag')
    % Mutate castSlag allocation
    perturbation = 0.2 * (2*rand() - 1); % +/- 20% change
    prodAlloc.castSlag = min(0.8, max(0.1, prodAlloc.castSlag * (1 + perturbation)));
end

if isfield(prodAlloc, 'solarThinFilm')
    % Mutate solarThinFilm allocation
    perturbation = 0.2 * (2*rand() - 1); % +/- 20% change
    prodAlloc.solarThinFilm = min(0.95, max(0.3, prodAlloc.solarThinFilm * (1 + perturbation)));
end

% Mutation for manufacturing allocations
manufacturingFields = {'lpbf', 'sc', 'pc', 'ssls', 'EBPVD'};
for i = 1:length(manufacturingFields)
    field = manufacturingFields{i};
    
    if isfield(prodAlloc, field)
        % Call specialized mutation function for each manufacturing type
        prodAlloc.(field) = mutateManufacturingAllocation(prodAlloc.(field), field, factory);
    end
end

return;
end

function allocStruct = mutateManufacturingAllocation(allocStruct, allocType, factory)
% Specialized mutation for different manufacturing allocations

% Handle different allocation types
switch allocType
    case 'lpbf'
        % LPBF deals with aluminum, iron, and alumina
        if isfield(allocStruct, 'aluminum') && isfield(allocStruct, 'iron') && isfield(allocStruct, 'alumina')
            % Randomly perturb allocations
            perturbation = 0.2 * (2*rand() - 1); % +/- 20% change
            allocStruct.aluminum = min(0.8, max(0.1, allocStruct.aluminum * (1 + perturbation)));
            
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.iron = min(0.8, max(0.1, allocStruct.iron * (1 + perturbation)));
            
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.alumina = min(0.8, max(0.1, allocStruct.alumina * (1 + perturbation)));
            
            % Normalize to ensure they don't exceed 1
            total = allocStruct.aluminum + allocStruct.iron + allocStruct.alumina;
            if total > 1
                allocStruct.aluminum = allocStruct.aluminum / total;
                allocStruct.iron = allocStruct.iron / total;
                allocStruct.alumina = allocStruct.alumina / total;
            end
        end
        
    case 'sc'
        % Sand Casting deals with aluminum, iron, and slag
        if isfield(allocStruct, 'aluminum') && isfield(allocStruct, 'iron') && isfield(allocStruct, 'slag')
            % Randomly perturb allocations
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.aluminum = min(0.8, max(0.1, allocStruct.aluminum * (1 + perturbation)));
            
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.iron = min(0.8, max(0.1, allocStruct.iron * (1 + perturbation)));
            
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.slag = min(0.8, max(0.1, allocStruct.slag * (1 + perturbation)));
            
            % Normalize to ensure they don't exceed 1
            total = allocStruct.aluminum + allocStruct.iron + allocStruct.slag;
            if total > 1
                allocStruct.aluminum = allocStruct.aluminum / total;
                allocStruct.iron = allocStruct.iron / total;
                allocStruct.slag = allocStruct.slag / total;
            end
        end
        
    case 'pc'
        % Modified Permanent Casting to allow totals less than 100%
        if isfield(allocStruct, 'aluminum') && isfield(allocStruct, 'slag')
            % Randomly perturb allocations - independent mutations
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.aluminum = min(0.8, max(0.1, allocStruct.aluminum * (1 + perturbation)));
            
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.slag = min(0.8, max(0.1, allocStruct.slag * (1 + perturbation)));
            
            % Normalize only if they exceed 1 (100%), allowing for less than 100% total
            total = allocStruct.aluminum + allocStruct.slag;
            if total > 1
                allocStruct.aluminum = allocStruct.aluminum / total;
                allocStruct.slag = allocStruct.slag / total;
            end
        end
        
    case 'ssls'
        % SSLS deals with silica, alumina, and regolith
        if isfield(allocStruct, 'silica') && isfield(allocStruct, 'alumina') && isfield(allocStruct, 'regolith')
            % Randomly perturb allocations
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.silica = min(0.8, max(0.1, allocStruct.silica * (1 + perturbation)));
            
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.alumina = min(0.8, max(0.1, allocStruct.alumina * (1 + perturbation)));
            
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.regolith = min(0.8, max(0.1, allocStruct.regolith * (1 + perturbation)));
            
            % Normalize to ensure they don't exceed 1
            total = allocStruct.silica + allocStruct.alumina + allocStruct.regolith;
            if total > 1
                allocStruct.silica = allocStruct.silica / total;
                allocStruct.alumina = allocStruct.alumina / total;
                allocStruct.regolith = allocStruct.regolith / total;
            end
        end
        
    case 'EBPVD'
        % EBPVD is just active and percentage
        if isfield(allocStruct, 'active') && isfield(allocStruct, 'percentage')
            % 10% chance to flip active state
            if rand() < 0.1
                allocStruct.active = ~allocStruct.active;
            end
            
            % Mutate percentage
            perturbation = 0.2 * (2*rand() - 1);
            allocStruct.percentage = min(1.0, max(0.3, allocStruct.percentage * (1 + perturbation)));
            
            % Additional logic based on factory state
            if factory.inventory.solarThinFilm < 0.1 && factory.inventory.aluminum > 10 && factory.inventory.silicon > 10
                % If we have raw materials but no thin film, make sure EBPVD is active
                allocStruct.active = true;
            end
        end
end

return;
end

%% Factory Simulation Functions

function fitness = evaluateFitness(strategy, factory, weights, lookAheadSteps)
% Evaluates the fitness of a strategy by simulating its effect

% Create a copy of the factory for simulation
factoryCopy = copyFactoryForSimulation(factory);

% Simulate the strategy for the look-ahead steps
[success, metrics] = simulateStrategy(strategy, factoryCopy, lookAheadSteps);

% Return a very low fitness if simulation failed
if ~success
    fitness = -1000;
    return;
end

% Calculate fitness based on final state and metrics
fitness = calculateFitnessScore(metrics, weights, lookAheadSteps);

return;
end

function [success, metrics] = simulateStrategy(strategy, factory, numSteps)
% Simulates the effect of applying a strategy for a number of steps
% Enhanced version that tracks processing system growth specifically

metrics = struct();
success = true;

try
    % Store initial values for comparison
    initialMass = factory.totalMass;
    initialPowerCapacity = factory.powerCapacity;
    initialNonReplicable = factory.inventory.nonReplicable;
    
    % Store initial subsystem masses for tracking growth
    initialProcessingMRE = factory.processingMRE.mass;
    initialProcessingHCl = factory.processingHCl.mass;
    initialProcessingVP = 0;
    if isfield(factory, 'processingVP')
        initialProcessingVP = factory.processingVP.mass;
    end
    
    initialManufacturingLPBF = factory.manufacturingLPBF.mass;
    initialManufacturingEBPVD = factory.manufacturingEBPVD.mass;
    initialManufacturingSC = 0;
    if isfield(factory, 'manufacturingSC')
        initialManufacturingSC = factory.manufacturingSC.mass;
    end
    initialManufacturingPC = 0;
    if isfield(factory, 'manufacturingPC')
        initialManufacturingPC = factory.manufacturingPC.mass;
    end
    initialManufacturingSSLS = 0;
    if isfield(factory, 'manufacturingSSLS')
        initialManufacturingSSLS = factory.manufacturingSSLS.mass;
    end
    
    % Initialize metrics storage
    metrics.massGrowth = zeros(numSteps, 1);
    metrics.powerGrowth = zeros(numSteps, 1);
    metrics.powerGrowthRate = zeros(numSteps, 1);
    metrics.profit = zeros(numSteps, 1);
    metrics.revenue = zeros(numSteps, 1);
    metrics.nonReplicable = zeros(numSteps, 1);
    metrics.nonReplicableConsumed = zeros(numSteps, 1); % Track consumption
    metrics.lunarBuiltMass = zeros(numSteps, 1); % Track lunar-built mass
    metrics.monthlyGrowthRate = zeros(numSteps, 1);
    metrics.solarThinFilmProduced = zeros(numSteps, 1);
    metrics.lunarSolarMass = zeros(numSteps, 1);
    
    % Track processing-to-manufacturing ratio evolution
    metrics.processingCapacity = zeros(numSteps, 1);
    metrics.manufacturingCapacity = zeros(numSteps, 1);
    metrics.processingRatio = zeros(numSteps, 1);
    
    % Track individual subsystem growth
    metrics.processingMREMass = zeros(numSteps, 1);
    metrics.processingHClMass = zeros(numSteps, 1);
    metrics.processingVPMass = zeros(numSteps, 1);
    metrics.manufacturingLPBFMass = zeros(numSteps, 1);
    metrics.manufacturingEBPVDMass = zeros(numSteps, 1);
    metrics.manufacturingSCMass = zeros(numSteps, 1);
    metrics.manufacturingPCMass = zeros(numSteps, 1);
    metrics.manufacturingSSLSMass = zeros(numSteps, 1);
    
    % Track lunar-built vs Earth-landed mass
    lunarBuiltMassTotal = 0;
    cumulativeNonReplicableConsumed = 0;
    
    % Run simulation steps
    for step = 1:numSteps
        % Capture starting values for this step
        stepStartPowerCapacity = factory.powerCapacity;
        stepStartSolarThinFilm = 0;
        if isfield(factory.inventory, 'solarThinFilm')
            stepStartSolarThinFilm = factory.inventory.solarThinFilm;
        end
        stepStartLunarSolarMass = factory.powerLunarSolar.mass;
        stepStartNonReplicable = factory.inventory.nonReplicable;
        stepStartTotalMass = factory.totalMass;
        
        % Record subsystem masses at the start of the step
        stepStartProcessingMRE = factory.processingMRE.mass;
        stepStartProcessingHCl = factory.processingHCl.mass;
        stepStartProcessingVP = 0;
        if isfield(factory, 'processingVP')
            stepStartProcessingVP = factory.processingVP.mass;
        end
        
        stepStartManufacturingLPBF = factory.manufacturingLPBF.mass;
        stepStartManufacturingEBPVD = factory.manufacturingEBPVD.mass;
        stepStartManufacturingSC = 0;
        if isfield(factory, 'manufacturingSC')
            stepStartManufacturingSC = factory.manufacturingSC.mass;
        end
        stepStartManufacturingPC = 0;
        if isfield(factory, 'manufacturingPC')
            stepStartManufacturingPC = factory.manufacturingPC.mass;
        end
        stepStartManufacturingSSLS = 0;
        if isfield(factory, 'manufacturingSSLS')
            stepStartManufacturingSSLS = factory.manufacturingSSLS.mass;
        end
        
        % Calculate processing and manufacturing capacities before execution
        stepStartProcessingCapacity = calculateProcessingCapacity(factory);
        stepStartManufacturingCapacity = calculateManufacturingCapacity(factory);
        
        % Set power distribution
        distributeFactoryPower(factory, strategy.powerDistribution);
        
        % Execute extraction, processing, and manufacturing
        factory.executeExtraction();
        factory.executeProcessing();
        factory.executeProduction(strategy.productionAllocation);
        
        % Execute assembly
        assemblyDecisions = calculateOptimalAssembly(factory, strategy);
        
        % Calculate mass of lunar-built components from this assembly step
        stepLunarBuiltMass = calculateLunarBuiltMass(assemblyDecisions);
        lunarBuiltMassTotal = lunarBuiltMassTotal + stepLunarBuiltMass;
        
        % Execute assembly after tracking
        factory.executeAssembly(assemblyDecisions);
        
        % Execute economic operations and process resupply
        factory.executeEconomicOperations();
        factory.processResupply();
        
        % Update factory state
        factory.updateFactoryState();
        factory.recordMetrics(factory.currentTimeStep + step);
        
        % Calculate non-replicable components consumed in this step
        % (decrease in inventory plus any resupply)
        nonReplicableChange = stepStartNonReplicable - factory.inventory.nonReplicable;
        if nonReplicableChange > 0
            cumulativeNonReplicableConsumed = cumulativeNonReplicableConsumed + nonReplicableChange;
        end
        
        % Record general metrics for this step
        metrics.massGrowth(step) = factory.totalMass - initialMass;
        metrics.powerGrowth(step) = factory.powerCapacity - initialPowerCapacity;
        metrics.lunarBuiltMass(step) = lunarBuiltMassTotal;
        metrics.nonReplicableConsumed(step) = cumulativeNonReplicableConsumed;
        
        % Calculate power growth rate for this step
        stepPowerGrowth = factory.powerCapacity - stepStartPowerCapacity;
        if stepStartPowerCapacity > 0
            metrics.powerGrowthRate(step) = stepPowerGrowth / stepStartPowerCapacity;
        else
            metrics.powerGrowthRate(step) = 0;
        end
        
        % Track solar thin film production
        if isfield(factory.inventory, 'solarThinFilm')
            metrics.solarThinFilmProduced(step) = factory.inventory.solarThinFilm - stepStartSolarThinFilm;
        end
        
        % Track lunar solar mass increase
        metrics.lunarSolarMass(step) = factory.powerLunarSolar.mass - stepStartLunarSolarMass;
        
        if isfield(factory.economics, 'profit') && length(factory.economics.profit) >= factory.currentTimeStep + step
            metrics.profit(step) = factory.economics.profit(factory.currentTimeStep + step);
        end
        
        if isfield(factory.economics, 'revenue') && length(factory.economics.revenue) >= factory.currentTimeStep + step
            metrics.revenue(step) = factory.economics.revenue(factory.currentTimeStep + step);
        end
        
        metrics.nonReplicable(step) = factory.inventory.nonReplicable;
        
        if step > 1
            metrics.monthlyGrowthRate(step) = (factory.totalMass / metrics.massGrowth(step-1)) - 1;
        end
        
        % Track processing-to-manufacturing ratio
        stepEndProcessingCapacity = calculateProcessingCapacity(factory);
        stepEndManufacturingCapacity = calculateManufacturingCapacity(factory);
        
        metrics.processingCapacity(step) = stepEndProcessingCapacity;
        metrics.manufacturingCapacity(step) = stepEndManufacturingCapacity;
        
        if stepEndManufacturingCapacity > 0
            metrics.processingRatio(step) = stepEndProcessingCapacity / stepEndManufacturingCapacity;
        else
            metrics.processingRatio(step) = 1.0; % Default when no manufacturing
        end
        
        % Track individual subsystem masses
        metrics.processingMREMass(step) = factory.processingMRE.mass;
        metrics.processingHClMass(step) = factory.processingHCl.mass;
        metrics.processingVPMass(step) = 0;
        if isfield(factory, 'processingVP')
            metrics.processingVPMass(step) = factory.processingVP.mass;
        end
        
        metrics.manufacturingLPBFMass(step) = factory.manufacturingLPBF.mass;
        metrics.manufacturingEBPVDMass(step) = factory.manufacturingEBPVD.mass;
        metrics.manufacturingSCMass(step) = 0;
        if isfield(factory, 'manufacturingSC')
            metrics.manufacturingSCMass(step) = factory.manufacturingSC.mass;
        end
        metrics.manufacturingPCMass(step) = 0;
        if isfield(factory, 'manufacturingPC')
            metrics.manufacturingPCMass(step) = factory.manufacturingPC.mass;
        end
        metrics.manufacturingSSLSMass(step) = 0;
        if isfield(factory, 'manufacturingSSLS')
            metrics.manufacturingSSLSMass(step) = factory.manufacturingSSLS.mass;
        end
    end
    
    % Store additional summary metrics
    metrics.finalMass = factory.totalMass;

% Calculate maximum theoretical power demand
maxPowerDemand = 0;
% Extraction
extractionPower = factory.extraction.units * factory.extraction.excavationRate * factory.extraction.energyPerKg;
maxPowerDemand = maxPowerDemand + extractionPower;

% MRE processing
totalMrePower = 0;
for i = 1:factory.processingMRE.units
    N = factory.processingMRE.oxygenPerUnitPerYear;
    t = factory.processingMRE.dutyCycle;
    unitPower = 264 * (N/(2*t))^0.577;
    totalMrePower = totalMrePower + unitPower;
end
maxPowerDemand = maxPowerDemand + totalMrePower;

% HCl processing
if factory.processingHCl.mass > 0
    hclPower = factory.processingHCl.mass * factory.processingHCl.powerScalingFactor / factory.processingHCl.massScalingFactor;
    maxPowerDemand = maxPowerDemand + hclPower;
end

% VP processing
if factory.processingVP.mass > 0
    vpPower = factory.processingVP.powerScalingFactor * factory.processingVP.mass / factory.processingVP.massScalingFactor;
    maxPowerDemand = maxPowerDemand + vpPower;
end

% LPBF manufacturing
lpbfPower = factory.manufacturingLPBF.units * factory.manufacturingLPBF.powerPerUnit;
maxPowerDemand = maxPowerDemand + lpbfPower;

% EBPVD manufacturing
if factory.manufacturingEBPVD.mass > 0
    productionCapacity = factory.manufacturingEBPVD.mass / factory.manufacturingEBPVD.massScalingFactor;
    EBPVDPower = productionCapacity * factory.manufacturingEBPVD.powerScalingFactor;
    maxPowerDemand = maxPowerDemand + EBPVDPower;
end

% Sand Casting manufacturing
if isfield(factory, 'manufacturingSC') && factory.manufacturingSC.mass > 0
    if isfield(factory.manufacturingSC, 'powerScalingFactor') && isfield(factory.manufacturingSC, 'massScalingFactor')
        scPower = factory.manufacturingSC.powerScalingFactor * factory.manufacturingSC.mass / factory.manufacturingSC.massScalingFactor;
    else
        scPower = 43.1 * factory.manufacturingSC.mass / 33.3;
    end
    maxPowerDemand = maxPowerDemand + scPower;
end

% PC manufacturing
if factory.manufacturingPC.mass > 0
    pcPower = factory.manufacturingPC.powerScalingFactor * factory.manufacturingPC.mass / factory.manufacturingPC.massScalingFactor;
    maxPowerDemand = maxPowerDemand + pcPower;
end

% SSLS manufacturing
if factory.manufacturingSSLS.mass > 0
    sslsPower = factory.manufacturingSSLS.powerScalingFactor * factory.manufacturingSSLS.mass / factory.manufacturingSSLS.massScalingFactor;
    maxPowerDemand = maxPowerDemand + sslsPower;
end

% Assembly
assemblyPower = factory.assembly.units * factory.assembly.powerPerUnit;
maxPowerDemand = maxPowerDemand + assemblyPower;

metrics.finalMaxPowerDemand = maxPowerDemand;


    metrics.finalPowerCapacity = factory.powerCapacity;
    metrics.finalPowerDemand = factory.powerDemand;
    metrics.powerUtilization = factory.powerDemand / factory.powerCapacity;
    metrics.totalPowerGrowth = factory.powerCapacity - initialPowerCapacity;
    metrics.avgPowerGrowthRate = mean(metrics.powerGrowthRate(metrics.powerGrowthRate > 0));
    metrics.totalProfit = sum(metrics.profit);
    metrics.totalRevenue = sum(metrics.revenue);
    metrics.finalNonReplicable = factory.inventory.nonReplicable;
    metrics.totalLunarSolarMassAdded = sum(metrics.lunarSolarMass);
    metrics.totalLunarBuiltMass = lunarBuiltMassTotal;
    metrics.totalNonReplicableConsumed = cumulativeNonReplicableConsumed;
    
    % Calculate processing growth metrics for specific tracking
    metrics.processingMREGrowth = factory.processingMRE.mass - initialProcessingMRE;
    metrics.processingHClGrowth = factory.processingHCl.mass - initialProcessingHCl;
    metrics.processingVPGrowth = 0;
    if isfield(factory, 'processingVP')
        metrics.processingVPGrowth = factory.processingVP.mass - initialProcessingVP;
    end
    
    metrics.manufacturingLPBFGrowth = factory.manufacturingLPBF.mass - initialManufacturingLPBF;
    metrics.manufacturingEBPVDGrowth = factory.manufacturingEBPVD.mass - initialManufacturingEBPVD;
    metrics.manufacturingSCGrowth = 0;
    if isfield(factory, 'manufacturingSC')
        metrics.manufacturingSCGrowth = factory.manufacturingSC.mass - initialManufacturingSC;
    end
    metrics.manufacturingPCGrowth = 0;
    if isfield(factory, 'manufacturingPC')
        metrics.manufacturingPCGrowth = factory.manufacturingPC.mass - initialManufacturingPC;
    end
    metrics.manufacturingSSLSGrowth = 0;
    if isfield(factory, 'manufacturingSSLS')
        metrics.manufacturingSSLSGrowth = factory.manufacturingSSLS.mass - initialManufacturingSSLS;
    end
    
    % Calculate total processing and manufacturing growth
    metrics.totalProcessingGrowth = metrics.processingMREGrowth + metrics.processingHClGrowth + metrics.processingVPGrowth;
    metrics.totalManufacturingGrowth = metrics.manufacturingLPBFGrowth + metrics.manufacturingEBPVDGrowth + ...
                                     metrics.manufacturingSCGrowth + metrics.manufacturingPCGrowth + ...
                                     metrics.manufacturingSSLSGrowth;
    
    % Calculate revised self-reliance score based on the ratio of lunar-built mass to non-replicable components consumed
    if metrics.totalNonReplicableConsumed > 0
        metrics.selfReliance = metrics.totalLunarBuiltMass / metrics.totalNonReplicableConsumed;
    else
        % If no non-replicable components consumed (unlikely), use a reasonable default
        if metrics.totalLunarBuiltMass > 0
            metrics.selfReliance = 1.0;
        else
            metrics.selfReliance = 0.0;
        end
    end
    
    % Calculate processing-to-manufacturing ratio metric
    finalProcessingCapacity = calculateProcessingCapacity(factory);
    finalManufacturingCapacity = calculateManufacturingCapacity(factory);
    
    if finalManufacturingCapacity > 0
        metrics.finalProcessingRatio = finalProcessingCapacity / finalManufacturingCapacity;
    else
        metrics.finalProcessingRatio = 1.0; % Default when no manufacturing
    end
    
    % Calculate ratio improvement
    initialProcessingCapacity = calculateProcessingCapacity(factory);
    initialManufacturingCapacity = calculateManufacturingCapacity(factory);
    
    initialRatio = 1.0;
    if initialManufacturingCapacity > 0
        initialRatio = initialProcessingCapacity / initialManufacturingCapacity;
    end
    
    metrics.processingRatioImprovement = metrics.finalProcessingRatio - initialRatio;
    
catch exception
    % If simulation fails, return failure
    fprintf('Simulation failed: %s\n', exception.message);
    success = false;
end

return;
end
function score = calculateFitnessScore(metrics, weights, lookAheadSteps)
% Calculates a weighted fitness score from simulation metrics
% Enhanced version that rewards processing system growth and balanced factory

if ~isfield(metrics, 'finalMass')
    % Handle case where metrics are incomplete
    score = -1000;
    return;
end

% Base expansion score based on mass growth
expansionScore = metrics.finalMass / 1000; 

% Power expansion score - added as an explicit component
powerExpansionScore = 0;
% Consider both absolute power capacity and growth rate
if isfield(metrics, 'finalPowerCapacity') && metrics.finalPowerCapacity > 0
    powerExpansionScore = powerExpansionScore + (metrics.finalPowerCapacity / 5000);
end
if isfield(metrics, 'totalPowerGrowth') && metrics.totalPowerGrowth > 0
    powerExpansionScore = powerExpansionScore + (metrics.totalPowerGrowth / 1000);
end
if isfield(metrics, 'avgPowerGrowthRate') && metrics.avgPowerGrowthRate > 0
    powerExpansionScore = powerExpansionScore + (metrics.avgPowerGrowthRate * 10);
end
% Bonus for adding lunar solar mass
if isfield(metrics, 'totalLunarSolarMassAdded') && metrics.totalLunarSolarMassAdded > 0
    powerExpansionScore = powerExpansionScore + (metrics.totalLunarSolarMassAdded / 500);
end

% Self-reliance score - enhanced to consider processing system growth
selfRelianceScore = metrics.selfReliance / 100;

% ENHANCEMENT: Add significant bonus for processing system growth
processingGrowthBonus = 0;
if isfield(metrics, 'processingMREGrowth') && metrics.processingMREGrowth > 0
    processingGrowthBonus = processingGrowthBonus + (metrics.processingMREGrowth / 200);
end
if isfield(metrics, 'processingHClGrowth') && metrics.processingHClGrowth > 0
    processingGrowthBonus = processingGrowthBonus + (metrics.processingHClGrowth / 200);
end
if isfield(metrics, 'processingVPGrowth') && metrics.processingVPGrowth > 0
    processingGrowthBonus = processingGrowthBonus + (metrics.processingVPGrowth / 100);
end

% Processing-to-manufacturing balance bonus
balanceBonus = 0;
if isfield(metrics, 'finalProcessingRatio')
    if metrics.finalProcessingRatio >= 0.5
        % Excellent balance (processing capacity >= 50% of manufacturing)
        balanceBonus = 1.0;
    elseif metrics.finalProcessingRatio >= 0.3
        % Good balance (30-50%)
        balanceBonus = 0.7;
    elseif metrics.finalProcessingRatio >= 0.2
        % Moderate balance (20-30%)
        balanceBonus = 0.4;
    elseif metrics.finalProcessingRatio >= 0.1
        % Poor balance (10-20%)
        balanceBonus = 0.2;
    else
        % Very poor balance (<10%)
        balanceBonus = 0.0;
    end
end

% ENHANCEMENT: Give significant bonus for improved processing-to-manufacturing ratio
ratioImprovementBonus = 0;
if isfield(metrics, 'processingRatioImprovement') && metrics.processingRatioImprovement > 0
    ratioImprovementBonus = metrics.processingRatioImprovement * 5.0; % Substantial bonus for ratio improvement
end

% Add processing growth and balance bonuses to self-reliance score
selfRelianceScore = selfRelianceScore + processingGrowthBonus + balanceBonus + ratioImprovementBonus;

% Economic performance score
if metrics.totalRevenue > 0
    revenueScore = metrics.totalRevenue / 1e6; % Scale for reasonable values
else
    revenueScore = 0;
end
if metrics.totalProfit > 0
    profitScore = metrics.totalProfit / 1e5; % Scale for reasonable values
else
    profitScore = 0;
end


% Combine scores with weights
totalScore = weights.expansion * expansionScore + ...
            weights.powerExpansion * powerExpansionScore +...
            weights.selfReliance * selfRelianceScore + ...
            weights.revenue * revenueScore + ...
            weights.cost * profitScore;

% Add bonus for power utilization in optimal range (70-90%)
if metrics.powerUtilization >= 0.85 && metrics.powerUtilization <= 0.99
    totalScore = totalScore * 2; % 100% bonus
end

% ENHANCEMENT: Add significant penalty for zero processing growth in unbalanced factory
if isfield(metrics, 'totalProcessingGrowth') && metrics.totalProcessingGrowth <= 0 && ...
   isfield(metrics, 'finalProcessingRatio') && metrics.finalProcessingRatio < 0.3
    fprintf('PENALTY: No processing growth in unbalanced factory (ratio: %.4f)\n', metrics.finalProcessingRatio);
    totalScore = totalScore * 0.5; % 50% penalty for unbalanced strategies that don't grow processing
end

% Add power capacity to demand ratio consideration
powerCapacityRatio = metrics.finalPowerCapacity / metrics.finalPowerDemand;
if powerCapacityRatio < 0.4
    % Penalty for very low power capacity ratio (severely underpowered factory)
    totalScore = totalScore * 0.5;
elseif powerCapacityRatio > 1.1
    % Bonus for optimal power capacity ratio
    totalScore = totalScore * 2.00;
end
% ENHANCEMENT: Display detailed breakdown of score components
fprintf('Score Breakdown: Expansion=%.2f, Power=%.2f, SelfReliance=%.2f, ProcGrowth=%.2f, BalanceBonus=%.2f, RatioImprovement=%.2f\n', ...
        expansionScore, powerExpansionScore, metrics.selfReliance/100, processingGrowthBonus, balanceBonus, ratioImprovementBonus);

score = totalScore;
end

function factoryCopy = copyFactoryForSimulation(factory)
% Creates a deep copy of the factory for simulation

% Create a new factory with the same configurations
factoryCopy = LunarFactory(factory.envConfig, factory.subConfig, factory.econConfig, factory.simConfig);

% Copy current state values
factoryCopy.currentTimeStep = factory.currentTimeStep;
factoryCopy.inRecoveryMode = factory.inRecoveryMode;

% Copy subsystem properties
copySubsystems(factory, factoryCopy);

% Copy inventory
copyInventory(factory, factoryCopy);

% Copy production allocation
if isfield(factory, 'productionAllocation')
    factoryCopy.productionAllocation = factory.productionAllocation;
end

% Copy power and mass distribution
if isfield(factory, 'powerDistribution')
    factoryCopy.powerDistribution = factory.powerDistribution;
end
if isfield(factory, 'massDistribution')
    factoryCopy.massDistribution = factory.massDistribution;
end

% Recalculate state
factoryCopy.calculatePowerCapacity();
factoryCopy.calculatePowerDemand();
factoryCopy.totalMass = factoryCopy.calculateTotalMass();

return;
end

function copySubsystems(source, target)
% Copies subsystem state from source to target factory

% Extraction
target.extraction = source.extraction;

% Processing subsystems
target.processingMRE = source.processingMRE;
target.processingHCl = source.processingHCl;
target.processingVP = source.processingVP;

% Manufacturing subsystems
target.manufacturingLPBF = source.manufacturingLPBF;
target.manufacturingEBPVD = source.manufacturingEBPVD;
target.manufacturingSC = source.manufacturingSC;
target.manufacturingPC = source.manufacturingPC;
target.manufacturingSSLS = source.manufacturingSSLS;

% Assembly
target.assembly = source.assembly;

% Power
target.powerLandedSolar = source.powerLandedSolar;
target.powerLunarSolar = source.powerLunarSolar;

return;
end

function copyInventory(source, target)
% Copies inventory state from source to target factory

fields = fieldnames(source.inventory);
for i = 1:length(fields)
    target.inventory.(fields{i}) = source.inventory.(fields{i});
end

return;
end

function lunarBuiltMass = calculateLunarBuiltMass(assemblyDecisions)
% Calculates the mass of components built on the Moon from assembly decisions
% This tracks only newly assembled mass, not what was already there

lunarBuiltMass = 0;

% If no assembly was done, return 0
if isempty(assemblyDecisions) || isempty(fieldnames(assemblyDecisions))
    return;
end

% Sum up all masses from assembly decisions
% All assembly represents lunar-built components since we're using lunar resources
fields = fieldnames(assemblyDecisions);
for i = 1:length(fields)
    subsystem = fields{i};
    if assemblyDecisions.(subsystem) > 0
        lunarBuiltMass = lunarBuiltMass + assemblyDecisions.(subsystem);
    end
end

return;
end

%% Assembly Planning Functions

function assemblyDecisions = calculateOptimalAssembly(factory, strategy)
% Calculate optimal assembly decisions based on available resources and strategy
% This enhanced version prioritizes processing systems when bottlenecks are detected

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

% Calculate processing to manufacturing capacity ratio
processingCapacity = calculateProcessingCapacity(factory);
manufacturingCapacity = calculateManufacturingCapacity(factory);
processingRatio = 1.0;
if manufacturingCapacity > 0
    processingRatio = processingCapacity / manufacturingCapacity;
end

% ENHANCEMENT: Print diagnostic information about capacities
fprintf('Capacity Analysis: Processing: %.2f kg/hr, Manufacturing: %.2f kg/hr, Ratio: %.4f\n', ...
    processingCapacity, manufacturingCapacity, processingRatio);

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
    
    % ENHANCEMENT: Add specialized priority boosting for processing subsystems
    % based on the ratio of processing to manufacturing capacity
    isProcessingSystem = startsWith(subsystem, 'processing');
    if isProcessingSystem
        % ENHANCEMENT: Progressive priority boosting based on capacity ratio
        if processingRatio < 0.1
            % Severe bottleneck - massive priority boost
            subsystemPriorities(i) = subsystemPriorities(i) * 10.0;
            fprintf('CRITICAL: Severe processing bottleneck detected (%.4f). Massively prioritizing %s\n', ...
                processingRatio, subsystem);
        elseif processingRatio < 0.3
            % Significant bottleneck - large priority boost
            subsystemPriorities(i) = subsystemPriorities(i) * 5.0;
            fprintf('WARNING: Significant processing bottleneck detected (%.4f). Highly prioritizing %s\n', ...
                processingRatio, subsystem);
        elseif processingRatio < 0.5
            % Moderate bottleneck - medium priority boost
            subsystemPriorities(i) = subsystemPriorities(i) * 3.0;
            fprintf('NOTICE: Moderate processing bottleneck detected (%.4f). Prioritizing %s\n', ...
                processingRatio, subsystem);
        elseif processingRatio < 0.8
            % Mild bottleneck - small priority boost
            subsystemPriorities(i) = subsystemPriorities(i) * 2.0;
            fprintf('INFO: Mild processing bottleneck detected (%.4f). Somewhat prioritizing %s\n', ...
                processingRatio, subsystem);
        end
    end
    
    % ENHANCEMENT: Limit priority for manufacturing systems when processing is bottlenecked
    isManufacturingSystem = startsWith(subsystem, 'manufacturing');
    if isManufacturingSystem && processingRatio < 0.5
        % Manufacturing systems should get lower priority when processing is bottlenecked
        subsystemPriorities(i) = subsystemPriorities(i) * 0.5;
        fprintf('LIMITING: Reducing priority for %s due to processing bottleneck\n', subsystem);
    end
    
    % Adjust priorities based on strategic considerations
    switch subsystem
        case 'powerLunarSolar'
            % Higher priority for power based on multiple factors
            powerUtilization = factory.powerDemand / factory.powerCapacity;
            
            % Check for solar thin film availability
            hasSolarThinFilm = false;
            if isfield(factory.inventory, 'solarThinFilm') && factory.inventory.solarThinFilm > 0
                hasSolarThinFilm = true;
            end
            
            % Power priority matrix based on utilization and materials
            if powerUtilization > 0.9
                % Critical power shortage - highest priority
                subsystemPriorities(i) = subsystemPriorities(i) * 2.5;
                if hasSolarThinFilm
                    subsystemPriorities(i) = subsystemPriorities(i) * 1.5; % Additional boost when materials are ready
                end
            elseif powerUtilization > 0.8
                % Significant power shortage
                subsystemPriorities(i) = subsystemPriorities(i) * 2.0;
                if hasSolarThinFilm
                    subsystemPriorities(i) = subsystemPriorities(i) * 1.2;
                end
            elseif powerUtilization > 0.7
                % Moderate power shortage
                subsystemPriorities(i) = subsystemPriorities(i) * 1.5;
            end
            
            % Always higher priority in early game to build power infrastructure
            if factory.currentTimeStep < 5
                subsystemPriorities(i) = subsystemPriorities(i) * 1.3;
            end
            
        case 'extraction'
            % Higher priority if regolith is low
            if factory.inventory.regolith < 1000
                subsystemPriorities(i) = subsystemPriorities(i) * 1.2;
            elseif factory.inventory.regolith < 500
                subsystemPriorities(i) = subsystemPriorities(i) * 1.5;
            elseif factory.inventory.regolith < 100
                subsystemPriorities(i) = subsystemPriorities(i) * 2.0;
            end
            
        case 'processingMRE'
            % ENHANCEMENT: Special priority for MRE system
            if processingRatio < 0.5
                subsystemPriorities(i) = subsystemPriorities(i) * 1.5;
            end
            
        case 'processingHCl'
            % ENHANCEMENT: Special priority for HCl system
            if processingRatio < 0.5
                subsystemPriorities(i) = subsystemPriorities(i) * 1.5;
            end
            
        case 'processingVP'
            % ENHANCEMENT: Special priority for VP system when it doesn't exist
            if factory.processingVP.mass == 0
                subsystemPriorities(i) = subsystemPriorities(i) * 1.8;
            end
            
        case 'manufacturingEBPVD'
            % Give higher priority to EBPVD to enable power generation
            powerUtilization = factory.powerDemand / factory.powerCapacity;
            if powerUtilization > 0.8
                subsystemPriorities(i) = subsystemPriorities(i) * 1.5;
            end
            
            % ENHANCEMENT: But still reduce priority if processing is bottlenecked
            if processingRatio < 0.2
                subsystemPriorities(i) = subsystemPriorities(i) * 0.6;
            end
    end
end

% ENHANCEMENT: Debug output to show priorities
fprintf('\nSubsystem assembly priorities:\n');
for i = 1:length(buildableSubsystems)
    fprintf('  %s: %.4f\n', buildableSubsystems{i}, subsystemPriorities(i));
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

% ENHANCEMENT: Process processing systems first to address bottlenecks
sortedIndices = 1:length(buildableSubsystems);
processingIndices = [];
nonProcessingIndices = [];

for i = 1:length(buildableSubsystems)
    if startsWith(buildableSubsystems{i}, 'processing')
        processingIndices(end+1) = i;
    else
        nonProcessingIndices(end+1) = i;
    end
end

% Combine indices with processing systems first
sortedIndices = [processingIndices, nonProcessingIndices];

% Build each subsystem according to the sorted priority order
for sortedIdx = 1:length(sortedIndices)
    i = sortedIndices(sortedIdx);
    subsystem = buildableSubsystems{i};
    
    % Get maximum buildable mass for this subsystem
    [canBuild, maxUnits, requiredMaterials] = factory.checkBuildRequirements(subsystem);
    
    if canBuild
        allocatedCapacity = remainingCapacity * subsystemPriorities(i);
        massToAssemble = min(allocatedCapacity, maxUnits * requiredMaterials.total);
        
        % ENHANCEMENT: For processing systems, ensure we're building at least some if they're a bottleneck
        if startsWith(subsystem, 'processing') && processingRatio < 0.5 && massToAssemble < 50
            minimumMassToAssemble = min(50, maxUnits * requiredMaterials.total);
            massToAssemble = max(massToAssemble, minimumMassToAssemble);
            fprintf('BOOSTING: Ensuring minimum build of %.2f kg for bottlenecked %s\n', ...
                massToAssemble, subsystem);
        end
        
        % ENHANCEMENT: Apply capacity limits for manufacturing systems based on processing ratio
        if startsWith(subsystem, 'manufacturing') && processingRatio < 0.5
            % Calculate manufacturing system's contribution to total capacity
            currentCapacity = 0;
            if strcmp(subsystem, 'manufacturingLPBF') && factory.manufacturingLPBF.mass > 0
                currentCapacity = factory.manufacturingLPBF.units * (0.23 + 0.68 + 0.34); % Sum of input rates
            elseif strcmp(subsystem, 'manufacturingEBPVD') && factory.manufacturingEBPVD.mass > 0
                currentCapacity = factory.manufacturingEBPVD.mass / factory.manufacturingEBPVD.massScalingFactor;
            elseif strcmp(subsystem, 'manufacturingSC') && isfield(factory, 'manufacturingSC') && factory.manufacturingSC.mass > 0
                currentCapacity = factory.manufacturingSC.mass / factory.manufacturingSC.massScalingFactor;
            elseif strcmp(subsystem, 'manufacturingPC') && factory.manufacturingPC.mass > 0
                currentCapacity = factory.manufacturingPC.mass / factory.manufacturingPC.massScalingFactor;
            elseif strcmp(subsystem, 'manufacturingSSLS') && factory.manufacturingSSLS.mass > 0
                currentCapacity = factory.manufacturingSSLS.mass / factory.manufacturingSSLS.massScalingFactor;
            end
            
            % Calculate the additional capacity this would add
            additionalCapacity = 0;
            if strcmp(subsystem, 'manufacturingLPBF')
                additionalUnits = massToAssemble / factory.manufacturingLPBF.massPerUnit;
                additionalCapacity = additionalUnits * (0.23 + 0.68 + 0.34);
            elseif strcmp(subsystem, 'manufacturingEBPVD')
                additionalCapacity = massToAssemble / factory.manufacturingEBPVD.massScalingFactor;
            elseif strcmp(subsystem, 'manufacturingSC')
                additionalCapacity = massToAssemble / factory.manufacturingSC.massScalingFactor;
            elseif strcmp(subsystem, 'manufacturingPC')
                additionalCapacity = massToAssemble / factory.manufacturingPC.massScalingFactor;
            elseif strcmp(subsystem, 'manufacturingSSLS')
                additionalCapacity = massToAssemble / factory.manufacturingSSLS.massScalingFactor;
            end
            
            % Calculate the projected manufacturing-to-processing ratio
            totalMfgCapacity = manufacturingCapacity + additionalCapacity;
            projectedRatio = processingCapacity / totalMfgCapacity;
            
            % If the projected ratio would make the bottleneck worse, limit growth
            if projectedRatio < processingRatio * 0.9  % Would worsen the bottleneck by more than 10%
                limitFactor = max(0.1, projectedRatio / processingRatio);
                limitedMass = massToAssemble * limitFactor;
                
                fprintf('CONSTRAINING: Limiting %s growth from %.2f kg to %.2f kg to avoid worsening processing bottleneck\n', ...
                    subsystem, massToAssemble, limitedMass);
                
                massToAssemble = limitedMass;
            end
        end
        
        % Store in assembly decisions
        if massToAssemble > 0
            assemblyDecisions.(subsystem) = massToAssemble;
            remainingCapacity = remainingCapacity - massToAssemble;
            
            fprintf('ASSEMBLY: Allocated %.2f kg for %s\n', massToAssemble, subsystem);
        else
            assemblyDecisions.(subsystem) = 0;
        end
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

% ENHANCEMENT: More aggressive bottleneck detection for processing systems
% Now we use a higher threshold (1.0 instead of 0.8) for processing capacity
% This means we want processing capacity to be at least equal to manufacturing
if processingCapacity < 1.0 * manufacturingCapacity
    % Calculate the severity of the bottleneck as a ratio
    bottleneckSeverity = 1.0 - (processingCapacity / manufacturingCapacity);
    
    % ENHANCEMENT: Add all processing subsystems as bottlenecks with
    % scores proportional to their capacity contribution
    
    % Calculate the capacity contribution of each processing subsystem
    mreCapacity = 0;
    if factory.processingMRE.mass > 0
        mreCapacity = factory.processingMRE.oxygenPerYear / 24 / 365;
        mreContribution = mreCapacity / max(processingCapacity, 0.001);
        bottlenecks{end+1} = 'processingMRE';
        scores(end+1) = bottleneckSeverity * mreContribution;
    end
    
    hclCapacity = 0;
    if factory.processingHCl.mass > 0
        hclCapacity = factory.processingHCl.mass / factory.processingHCl.massScalingFactor;
        hclContribution = hclCapacity / max(processingCapacity, 0.001);
        bottlenecks{end+1} = 'processingHCl';
        scores(end+1) = bottleneckSeverity * hclContribution;
    end
    
    vpCapacity = 0;
    if factory.processingVP.mass > 0
        vpCapacity = factory.processingVP.mass / factory.processingVP.massScalingFactor;
        vpContribution = vpCapacity / max(processingCapacity, 0.001);
        bottlenecks{end+1} = 'processingVP';
        scores(end+1) = bottleneckSeverity * vpContribution;
    end
    
    % ENHANCEMENT: If no processing systems exist, add all as potential bottlenecks
    if isempty(bottlenecks)
        bottlenecks{end+1} = 'processingMRE';
        scores(end+1) = bottleneckSeverity * 0.4; % Higher priority to MRE
        
        bottlenecks{end+1} = 'processingHCl';
        scores(end+1) = bottleneckSeverity * 0.4; % Higher priority to HCl
        
        bottlenecks{end+1} = 'processingVP';
        scores(end+1) = bottleneckSeverity * 0.2; % Lower priority to VP as it's less essential
    end
    
    % ENHANCEMENT: If bottleneck is severe (ratio < 0.2), boost scores dramatically
    if processingCapacity / manufacturingCapacity < 0.2
        for i = 1:length(bottlenecks)
            if startsWith(bottlenecks{i}, 'processing')
                scores(i) = scores(i) * 2.5; % Significant score increase for severe bottlenecks
            end
        end
    end
end

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
    if isfield(factory, 'manufacturingSC') && factory.manufacturingSC.mass > 0
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

% This file contains additional helper functions to enforce balanced growth

function capacity = calculateProcessingCapacity(factory)
% Calculate processing capacity in kg/hr with improved accuracy
capacity = 0;

% MRE capacity - improved calculation based on oxygen production
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

function isUnbalanced = isManufacturingUnbalanced(factory)
    % Check if manufacturing capacity is significantly higher than processing capacity
    % Returns true if unbalanced, false if balanced
    
    processingCapacity = calculateProcessingCapacity(factory);
    manufacturingCapacity = calculateManufacturingCapacity(factory);
    
    % Initialize output variable to false (balanced)
    isUnbalanced = false;
    
    % Calculate the ratio of processing to manufacturing capacity
    if manufacturingCapacity > 0
        ratio = processingCapacity / manufacturingCapacity;
        
        % If processing capacity is less than 50% of manufacturing capacity,
        % the factory is considered unbalanced
        if ratio < 0.5
            fprintf('BALANCE CHECK: Factory is unbalanced! Processing-to-manufacturing ratio: %.4f\n', ratio);
            isUnbalanced = true;
            return;
        end
    end
    
end
function weights = adjustOptimizationWeights(factory, originalWeights)
% Dynamically adjust optimization weights based on factory balance
weights = originalWeights;

% Check if processing is bottlenecked
processingCapacity = calculateProcessingCapacity(factory);
manufacturingCapacity = calculateManufacturingCapacity(factory);

if manufacturingCapacity > 0
    ratio = processingCapacity / manufacturingCapacity;
    
    % Adjust weights based on processing-to-manufacturing ratio
    if ratio < 0.1
        % Severe bottleneck - heavily prioritize self-reliance and balanced growth
        fprintf('WEIGHT ADJUSTMENT: Severe processing bottleneck (ratio: %.4f) - prioritizing self-reliance\n', ratio);
        weights.selfReliance = weights.selfReliance * 2.0;
        weights.expansion = weights.expansion * 0.5;
        weights.revenue = weights.revenue * 0.5;
    elseif ratio < 0.3
        % Significant bottleneck - moderately prioritize self-reliance
        fprintf('WEIGHT ADJUSTMENT: Significant processing bottleneck (ratio: %.4f) - increasing self-reliance\n', ratio);
        weights.selfReliance = weights.selfReliance * 1.5;
        weights.expansion = weights.expansion * 0.7;
    elseif ratio < 0.5
        % Moderate bottleneck - slightly prioritize self-reliance
        fprintf('WEIGHT ADJUSTMENT: Moderate processing bottleneck (ratio: %.4f) - slightly increasing self-reliance\n', ratio);
        weights.selfReliance = weights.selfReliance * 1.2;
        weights.expansion = weights.expansion * 0.9;
    end
    
    % Normalize weights to sum to 1.0
    totalWeight = weights.expansion + weights.selfReliance + weights.revenue + weights.cost;
    if isfield(weights, 'powerExpansion')
        totalWeight = totalWeight + weights.powerExpansion;
    end
    
    if abs(totalWeight - 1.0) > 0.01
        fprintf('Normalizing weights from sum of %.2f to 1.0\n', totalWeight);
        
        weights.expansion = weights.expansion / totalWeight;
        weights.selfReliance = weights.selfReliance / totalWeight;
        weights.revenue = weights.revenue / totalWeight;
        weights.cost = weights.cost / totalWeight;
        
        if isfield(weights, 'powerExpansion')
            weights.powerExpansion = weights.powerExpansion / totalWeight;
        end
    end
end

return;
end

function [success, metrics] = validateFactoryBalance(factory, strategy, metrics)
% Validate that the projected strategy maintains reasonable factory balance
success = true;

processingCapacity = calculateProcessingCapacity(factory);
manufacturingCapacity = calculateManufacturingCapacity(factory);

% Calculate current ratio
currentRatio = 1.0;
if manufacturingCapacity > 0
    currentRatio = processingCapacity / manufacturingCapacity;
end

% Check if metrics shows growth in manufacturing without growth in processing
if isfield(metrics, 'finalMass') && isfield(metrics, 'totalLunarBuiltMass')
    processingGrowth = false;
    manufacturingGrowth = false;
    
    % Look for evidence of growth in processing systems
    if isfield(metrics, 'processingMREGrowth') && metrics.processingMREGrowth > 0
        processingGrowth = true;
    elseif isfield(metrics, 'processingHClGrowth') && metrics.processingHClGrowth > 0
        processingGrowth = true;
    elseif isfield(metrics, 'processingVPGrowth') && metrics.processingVPGrowth > 0
        processingGrowth = true;
    end
    
    % Look for evidence of growth in manufacturing systems
    if isfield(metrics, 'manufacturingLPBFGrowth') && metrics.manufacturingLPBFGrowth > 0
        manufacturingGrowth = true;
    elseif isfield(metrics, 'manufacturingEBPVDGrowth') && metrics.manufacturingEBPVDGrowth > 0
        manufacturingGrowth = true;
    elseif isfield(metrics, 'manufacturingSCGrowth') && metrics.manufacturingSCGrowth > 0
        manufacturingGrowth = true;
    elseif isfield(metrics, 'manufacturingPCGrowth') && metrics.manufacturingPCGrowth > 0
        manufacturingGrowth = true;
    elseif isfield(metrics, 'manufacturingSSLSGrowth') && metrics.manufacturingSSLSGrowth > 0
        manufacturingGrowth = true;
    end
    
    % If we see manufacturing growth but no processing growth when ratio is already bad,
    % the strategy is likely to worsen the bottleneck
    if manufacturingGrowth && ~processingGrowth && currentRatio < 0.3
        success = false;
        fprintf('VALIDATION FAILED: Strategy would grow manufacturing without processing when ratio is already %.4f\n', currentRatio);
    end
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




%% Utility Functions

function distributeFactoryPower(factory, powerDistribution)
% Distribute power to factory subsystems based on the powerDistribution strategy
% Simplified implementation from runAutomatedSimulation.m

% Calculate total available power
factory.calculatePowerCapacity();
availablePower = factory.powerCapacity;

% Initialize allocatedPower fields for all subsystems if they don't exist
subsystems = {'extraction', 'processingMRE', 'processingHCl', 'processingVP', ...
              'manufacturingLPBF', 'manufacturingEBPVD', 'manufacturingSC', ...
              'manufacturingPC', 'manufacturingSSLS', 'assembly'};

for i = 1:length(subsystems)
    subsystem = subsystems{i};
    if ~isfield(factory.(subsystem), 'allocatedPower')
        factory.(subsystem).allocatedPower = 0;
    end
end

% Allocate power to each subsystem
fields = fieldnames(powerDistribution);
for i = 1:length(fields)
    subsystem = fields{i};
    allocatedPower = availablePower * powerDistribution.(subsystem);
    
    % Set allocated power for the subsystem
    factory.(subsystem).allocatedPower = allocatedPower;
end

% Update total power demand
totalAllocated = 0;
for i = 1:length(fields)
    subsystem = fields{i};
    totalAllocated = totalAllocated + factory.(subsystem).allocatedPower;
end

factory.powerDemand = totalAllocated;
end