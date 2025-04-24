%% Self-Expanding Lunar Factory Simulation
% Main execution script for lunar factory simulation with both interactive and automated modes

clear all;
close all;
clc;

% Load configurations
disp('Loading configurations...');
envConfig = environmentConfig();
subConfig = subsystemConfig();
econConfig = economicConfig();
simConfig = simulationConfig();

% Option to run interactive or automated simulation
simulationMode = input('Run simulation in [1] Interactive mode or [2] Automated mode (default)? ');

if isempty(simulationMode) || simulationMode ~= 1
    %% Automated Simulation Mode
    disp('=== Optimization Configuration ===');
    
    % Get look-ahead steps
    lookAheadSteps = input('Enter number of look-ahead steps for optimization (default: 3): ');
    if isempty(lookAheadSteps)
        lookAheadSteps = 3;
    end
    
    % Get cost function weights
    disp('Enter weights for cost function components (0.0 to 1.0):');
    weights = struct();
    
    weights.expansion = input('  Weight for factory expansion (default: 0.35): ');
    if isempty(weights.expansion)
        weights.expansion = 0.35;
    end
    
    weights.powerExpansion = input('  Weight for power expansion (default: 0.25): ');
    if isempty(weights.powerExpansion)
        weights.powerExpansion = 0.25;
    end
    
    weights.selfReliance = input('  Weight for factory self-reliance (default: 0.15): ');
    if isempty(weights.selfReliance)
        weights.selfReliance = 0.15;
    end
    
    weights.revenue = input('  Weight for revenue generation (default: 0.2): ');
    if isempty(weights.revenue)
        weights.revenue = 0.2;
    end
    
    weights.cost = input('  Weight for cost minimization (default: 0.05): ');
    if isempty(weights.cost)
        weights.cost = 0.05;
    end
    
    % Normalize weights to sum to 1.0
    totalWeight = weights.expansion + weights.powerExpansion + weights.selfReliance + weights.revenue + weights.cost;
    if abs(totalWeight - 1.0) > 0.01
        fprintf('Normalizing weights from sum of %.2f to 1.0\n', totalWeight);
        weights.expansion = weights.expansion / totalWeight;
        weights.powerExpansion = weights.powerExpansion / totalWeight;
        weights.selfReliance = weights.selfReliance / totalWeight;
        weights.revenue = weights.revenue / totalWeight;
        weights.cost = weights.cost / totalWeight;
    end
    
    % Check if user wants to provide initial resource allocation strategy
    useCustomInitialGuess = input('Do you want to provide an initial resource allocation strategy? (1 = Yes, 0 = No, default: No): ');
    
    initialGuess = [];
    if useCustomInitialGuess == 1
        initialGuess = struct();
        
        % Power allocation
        disp('Enter initial power distribution (percentage of available power):');
        disp('Power allocation percentages (must sum to 100):');
        
        initialGuess.powerDistribution = struct();
        initialGuess.powerDistribution.extraction = input('  Extraction (%): ') / 100;
        initialGuess.powerDistribution.processingMRE = input('  Processing MRE (%): ') / 100;
        initialGuess.powerDistribution.processingHCl = input('  Processing HCl (%): ') / 100;
        initialGuess.powerDistribution.processingVP = input('  Processing VP (%): ') / 100;
        initialGuess.powerDistribution.manufacturingLPBF = input('  Manufacturing LPBF (%): ') / 100;
        initialGuess.powerDistribution.manufacturingEBPVD = input('  Manufacturing EBPVD (%): ') / 100;
        initialGuess.powerDistribution.manufacturingSC = input('  Manufacturing SC (%): ') / 100;
        initialGuess.powerDistribution.manufacturingPC = input('  Manufacturing PC (%): ') / 100;
        initialGuess.powerDistribution.manufacturingSSLS = input('  Manufacturing SSLS (%): ') / 100;
        initialGuess.powerDistribution.assembly = input('  Assembly (%): ') / 100;
        
        % Normalize power allocation
        totalPower = sum(struct2array(initialGuess.powerDistribution));
        if totalPower > 0 && abs(totalPower - 1.0) > 0.01
            disp(['Power allocations sum to ' num2str(totalPower*100) '%. Normalizing to 100%.']);
            fields = fieldnames(initialGuess.powerDistribution);
            for i = 1:length(fields)
                initialGuess.powerDistribution.(fields{i}) = initialGuess.powerDistribution.(fields{i}) / totalPower;
            end
        end
        
        % Production allocation strategies
        disp('Production allocation strategy:');
        initialGuess.productionAllocation = struct();
        initialGuess.productionAllocation.replication = input('  Percentage for replication (vs. sales) (default: 70%): ') / 100;
        if isempty(initialGuess.productionAllocation.replication)
            initialGuess.productionAllocation.replication = 0.70;
        end
        initialGuess.productionAllocation.sales = 1 - initialGuess.productionAllocation.replication;
    end
    
    % Run automated simulation with user-provided parameters
    disp('Running automated simulation with optimization...');
    factory = runAutomatedSimulation(envConfig, subConfig, econConfig, simConfig, weights, lookAheadSteps, initialGuess);
    
    % Display visualizations for automated simulation results
    if ~isempty(factory)
        disp('Displaying visualizations for automated simulation...');
        
        % Create visualization options
        visOptions = struct('saveToFile', true, 'figuresDir', 'automated_results');
        
        % Ensure the directory exists
        if ~exist(visOptions.figuresDir, 'dir')
            fprintf('Creating visualization directory: %s\n', visOptions.figuresDir);
            mkdir(visOptions.figuresDir);
        end
        
        % Display summary
        disp('Displaying summary...');
        options = struct('saveToFile', true, 'filename', [visOptions.figuresDir, '/automated_summary.txt']);
        displaySummary(factory, options);
        
%         % Generate visualizations
%         visualizeFactoryPerformance(factory, visOptions);
        
        % Generate enhanced visualizations
        disp('Generating enhanced visualizations for automated simulation...');
        enhancedOptions = struct('saveToFile', true, 'figuresDir', 'enhanced_automated_results');
        if ~exist(enhancedOptions.figuresDir, 'dir')
            mkdir(enhancedOptions.figuresDir);
        end
        visualizeFactoryPerformance(factory, enhancedOptions);
    end
else
    %% Interactive Simulation Mode
    % Create factory object for interactive mode
    disp('Creating lunar factory object for interactive mode...');
    factory = LunarFactory(envConfig, subConfig, econConfig, simConfig);
    
    % Run the interactive simulation
    disp('Running simulation with user input...');
    factory.runSimulationWithUserInput();
    
    % Display summary
    disp('Displaying summary...');
    options = struct('saveToFile', true, 'filename', 'interactive_summary.txt');
    displaySummary(factory, options);
    
    % Display additional visualizations
    disp('Generating performance visualizations...');
    visOptions = struct('saveToFile', true, 'figuresDir', 'interactive_results');
    
    % Ensure the directory exists
    if ~exist(visOptions.figuresDir, 'dir')
        fprintf('Creating visualization directory: %s\n', visOptions.figuresDir);
        mkdir(visOptions.figuresDir);
    end
    
    visualizeFactoryPerformance(factory, visOptions);
    
    % Ask user which visualizations they want to see in detail
    disp('Which specific visualizations would you like to examine in detail?');
    disp('1. Material Flow Rates');
    disp('2. Growth Rates');
    disp('3. Power Utilization');
    disp('4. Lunar-Manufactured Percentage');
    disp('5. Bottleneck Analysis');
    disp('6. Subsystem Growth');
    disp('7. All Visualizations');
    disp('0. None (continue)');
    
    visChoice = input('Enter your choice (0-7): ');
    
    if ~isempty(visChoice) && visChoice > 0
        focusedOptions = struct('saveToFile', true, 'figuresDir', 'interactive_focused_results');
        if ~exist(focusedOptions.figuresDir, 'dir')
            mkdir(focusedOptions.figuresDir);
        end
        
        % Set selected visualizations based on user choice
        if visChoice == 1
            focusedOptions.selectedVisuals = {'flowRates'};
        elseif visChoice == 2
            focusedOptions.selectedVisuals = {'visualizeGrowthRates'};
        elseif visChoice == 3
            focusedOptions.selectedVisuals = {'power'};
        elseif visChoice == 4
            focusedOptions.selectedVisuals = {'lunarPercentage'};
        elseif visChoice == 5
            focusedOptions.selectedVisuals = {'bottleneck'};
        elseif visChoice == 6
            focusedOptions.selectedVisuals = {'visualizeSubsystemGrowth'};
        else % visChoice == 7 or other
            focusedOptions.selectedVisuals = {
                'flowRates',
                'visualizeGrowthRates',
                'power',
                'lunarPercentage',
                'bottleneck',
                'visualizeSubsystemGrowth'
            };
        end
        
        % Generate focused visualizations
        visualizeFactoryPerformance(factory, focusedOptions);
    end
    
    % Generate enhanced visualizations
    disp('Generating enhanced visualizations for academic analysis...');
    enhancedOptions = struct('saveToFile', true, 'figuresDir', 'enhanced_interactive_results');
    if ~exist(enhancedOptions.figuresDir, 'dir')
        mkdir(enhancedOptions.figuresDir);
    end
    visualizeFactoryPerformance(factory, enhancedOptions);
end

%% Optional: Run Comparison (disabled by default)
runComparison = 0; % Set to 1 to enable comparison mode
if runComparison == 1
    compareSimulationModes();
end

%% Comparison function to run both modes and compare results
function compareSimulationModes()
    % Load configurations
    envConfig = environmentConfig();
    subConfig = subsystemConfig();
    econConfig = economicConfig();
    simConfig = simulationConfig();
    
    % Reduce number of time steps for quick comparison
    simConfig.numTimeSteps = 5;
    
    % Run automated simulation
    disp('Running automated simulation...');
    autoFactory = runAutomatedSimulation(envConfig, subConfig, econConfig, simConfig);
    
    % Reset and run interactive simulation
    disp('NOTE: For interactive mode, use default values by pressing Enter for simplicity of comparison');
    disp('Running interactive simulation...');
    interactiveFactory = LunarFactory(envConfig, subConfig, econConfig, simConfig);
    interactiveFactory.runSimulationWithUserInput();
    
    % Compare metrics
    compareMetrics(autoFactory, interactiveFactory);
    
    % Generate comparative visualizations
    disp('Generating comparative visualizations...');
    visOptions = struct('saveToFile', true, 'figuresDir', 'comparison_results');
    
    % Ensure the directory exists
    if ~exist(visOptions.figuresDir, 'dir')
        fprintf('Creating visualization directory: %s\n', visOptions.figuresDir);
        mkdir(visOptions.figuresDir);
    end
    
    % Create comparison visualization figure
    figure('Name', 'Simulation Mode Comparison', 'Position', [100, 100, 1200, 800]);
    
    % Compare subsystem growth
    subplot(2, 2, 1);
    timeMonths1 = (1:autoFactory.currentTimeStep) * (autoFactory.simConfig.timeStepSize / 720);
    timeMonths2 = (1:interactiveFactory.currentTimeStep) * (interactiveFactory.simConfig.timeStepSize / 720);
    plot(timeMonths1, sum(autoFactory.metrics.subsystemMasses(1:autoFactory.currentTimeStep,:), 2), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths2, sum(interactiveFactory.metrics.subsystemMasses(1:interactiveFactory.currentTimeStep,:), 2), 'r--', 'LineWidth', 2);
    title('Total Factory Mass Comparison');
    xlabel('Time (months)');
    ylabel('Mass (kg)');
    legend('Automated', 'Interactive', 'Location', 'northwest');
    grid on;
    
    % Compare growth rates
    subplot(2, 2, 2);
    if autoFactory.currentTimeStep > 1 && interactiveFactory.currentTimeStep > 1
        plot(timeMonths1(2:end), autoFactory.metrics.monthlyGrowthRate(2:end)*100, 'b-', 'LineWidth', 2);
        hold on;
        plot(timeMonths2(2:end), interactiveFactory.metrics.monthlyGrowthRate(2:end)*100, 'r--', 'LineWidth', 2);
        title('Monthly Growth Rate Comparison');
        xlabel('Time (months)');
        ylabel('Growth Rate (%)');
        legend('Automated', 'Interactive', 'Location', 'northwest');
        grid on;
    else
        text(0.5, 0.5, 'Insufficient data for growth rate comparison', 'HorizontalAlignment', 'center');
    end
    
    % Compare power capacity
    subplot(2, 2, 3);
    plot(timeMonths1, autoFactory.metrics.powerCapacity(1:autoFactory.currentTimeStep), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths2, interactiveFactory.metrics.powerCapacity(1:interactiveFactory.currentTimeStep), 'r--', 'LineWidth', 2);
    title('Power Capacity Comparison');
    xlabel('Time (months)');
    ylabel('Power (W)');
    legend('Automated', 'Interactive', 'Location', 'northwest');
    grid on;
    
    % Compare economic performance
    subplot(2, 2, 4);
    plot(timeMonths1, autoFactory.economics.cumulativeProfit(1:autoFactory.currentTimeStep), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths2, interactiveFactory.economics.cumulativeProfit(1:interactiveFactory.currentTimeStep), 'r--', 'LineWidth', 2);
    title('Cumulative Profit Comparison');
    xlabel('Time (months)');
    ylabel('Profit ($)');
    legend('Automated', 'Interactive', 'Location', 'northwest');
    grid on;
    
    % Save comparison figure
    if visOptions.saveToFile
        figFilename = fullfile(visOptions.figuresDir, 'mode_comparison.png');
        saveas(gcf, figFilename);
        fprintf('Mode comparison visualization saved to %s\n', figFilename);
    end
end

function compareMetrics(factory1, factory2)
    % Compare metrics between two factory runs
    figure('Name', 'Simulation Comparison', 'Position', [100, 100, 1200, 800]);
    
    % Get time steps
    numSteps = min(factory1.currentTimeStep, factory2.currentTimeStep);
    timeMonths = (1:numSteps) * (factory1.simConfig.timeStepSize / 720);
    
    % Total Mass comparison
    subplot(2, 2, 1);
    plot(timeMonths, factory1.metrics.totalMass(1:numSteps), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths, factory2.metrics.totalMass(1:numSteps), 'r--', 'LineWidth', 2);
    title('Total Mass Comparison');
    xlabel('Time (months)');
    ylabel('Mass (kg)');
    legend('Automated', 'Interactive', 'Location', 'northwest');
    grid on;
    
    % Power capacity comparison
    subplot(2, 2, 2);
    plot(timeMonths, factory1.metrics.powerCapacity(1:numSteps), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths, factory2.metrics.powerCapacity(1:numSteps), 'r--', 'LineWidth', 2);
    title('Power Capacity Comparison');
    xlabel('Time (months)');
    ylabel('Power (W)');
    legend('Automated', 'Interactive', 'Location', 'northwest');
    grid on;
    
    % Economic comparison
    subplot(2, 2, 3);
    plot(timeMonths, factory1.economics.cumulativeProfit(1:numSteps), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths, factory2.economics.cumulativeProfit(1:numSteps), 'r--', 'LineWidth', 2);
    title('Cumulative Profit Comparison');
    xlabel('Time (months)');
    ylabel('Profit ($)');
    legend('Automated', 'Interactive', 'Location', 'northwest');
    grid on;
    
    % Material inventory comparison (regolith as example)
    subplot(2, 2, 4);
    plot(timeMonths, factory1.metrics.materialFlows.regolith(1:numSteps), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths, factory2.metrics.materialFlows.regolith(1:numSteps), 'r--', 'LineWidth', 2);
    title('Regolith Inventory Comparison');
    xlabel('Time (months)');
    ylabel('Mass (kg)');
    legend('Automated', 'Interactive', 'Location', 'northwest');
    grid on;
    
    % Print summary statistics
    fprintf('\n==== Simulation Comparison Summary ====\n');
    fprintf('Final Total Mass: Automated = %.2f kg, Interactive = %.2f kg\n', ...
        factory1.metrics.totalMass(numSteps), factory2.metrics.totalMass(numSteps));
    fprintf('Final Power Capacity: Automated = %.2f W, Interactive = %.2f W\n', ...
        factory1.metrics.powerCapacity(numSteps), factory2.metrics.powerCapacity(numSteps));
    fprintf('Final Cumulative Profit: Automated = $%.2f, Interactive = $%.2f\n', ...
        factory1.economics.cumulativeProfit(numSteps), factory2.economics.cumulativeProfit(numSteps));
end