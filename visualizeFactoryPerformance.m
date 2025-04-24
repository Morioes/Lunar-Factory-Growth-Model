%% Lunar-Manufactured Percentage Visualization
function visualizeFactoryPerformance(factory, options)
    % Function to generate all enhanced visualizations for lunar factory simulation
    %
    % Inputs:
    %   factory - LunarFactory object containing simulation results
    %   options - Structure with display options (optional)
    %       .saveToFile - Boolean indicating whether to save results to file
    %       .figuresDir - Directory to save figures (default: 'enhanced_figures')
    %       .selectedVisuals - Cell array of visualization types to generate
    %           (default: all visualizations)
    
    % Handle optional inputs
    if nargin < 2
        options = struct();
    end
    if ~isfield(options, 'saveToFile')
        options.saveToFile = true;
    end
    if ~isfield(options, 'figuresDir') && options.saveToFile
        options.figuresDir = 'enhanced_figures';
    end
    
    % Create directory if it doesn't exist
    if options.saveToFile
        if ~exist(options.figuresDir, 'dir')
            fprintf('Creating output directory: %s\n', options.figuresDir);
            mkdir(options.figuresDir);
        end
    end
    
    % Get time steps
    numSteps = factory.currentTimeStep;
    if numSteps < 2
        warning('Insufficient time steps for meaningful visualization. Need at least 2 time steps.');
        return;
    end
    
    % Create time vector (in months)
    timeMonths = (1:numSteps) * (factory.simConfig.timeStepSize / 720);
    
% Default visualizations to generate
if ~isfield(options, 'selectedVisuals')
    options.selectedVisuals = {
        'flowRates',          % Material flow rates
        'materialDependency', % Material dependency graph
        'strategy',           % Strategy effectiveness
        'power',              % Power utilization
        'lunarPercentage',    % Lunar manufactured percentage
        'bottleneck',         % Bottleneck analysis
        'visualizeGrowthRates',
        'visualizeSubsystemGrowth',
        'individualSubsystemMass'  % New visualization
    };
end
    
    % Generate selected visualizations
    if ismember('flowRates', options.selectedVisuals)
        fprintf('Generating material flow rates visualization...\n');
        visualizeMaterialFlowRates(factory, timeMonths, options);
    end
    

    if ismember('strategy', options.selectedVisuals)
        fprintf('Generating strategy effectiveness visualization...\n');
        visualizeStrategyEffectiveness(factory, timeMonths, options);
    end
    
    if ismember('power', options.selectedVisuals)
        fprintf('Generating power utilization visualization...\n');
        visualizePowerUtilization(factory, timeMonths, options);
    end
    
    if ismember('lunarPercentage', options.selectedVisuals)
        fprintf('Generating lunar manufactured percentage visualization...\n');
        visualizeLunarManufacturedPercentage(factory, timeMonths, options);
    end
    
    if ismember('bottleneck', options.selectedVisuals)
        fprintf('Generating bottleneck analysis visualization...\n');
        visualizeBottleneckAnalysis(factory, timeMonths, options);
    end

    if ismember('visualizeGrowthRates', options.selectedVisuals)
        fprintf('Generating growth rate visualization...\n');
        visualizeGrowthRates(factory, timeMonths, options);
    end

    if ismember('visualizeSubsystemGrowth', options.selectedVisuals)
        fprintf('Generating subsystem growth rate visualization...\n');
        visualizeSubsystemGrowth(factory, timeMonths, options);
    end

    if ismember('individualSubsystemMass', options.selectedVisuals) || ~isfield(options, 'selectedVisuals')
        fprintf('Generating individual subsystem mass visualization...\n');
        visualizeIndividualSubsystemMass(factory, timeMonths, options);
    end

    fprintf('Enhanced visualizations complete.\n');
end

%% Material Flow Rates Visualization
function visualizeMaterialFlowRates(factory, timeMonths, options)
    % Create figure for inventory changes 
    figInventory = figure('Name', 'Lunar Factory Inventory', 'Position', [100, 100, 1200, 800]);
    
    % Set figure properties
    set(figInventory, 'Color', 'white');
    set(findall(figInventory, '-property', 'FontName'), 'FontName', 'Garamond');
    set(findall(figInventory, '-property', 'FontSize'), 'FontSize', 12);
    
    % Get material flows
    materialFields = {'regolith', 'oxygen', 'iron', 'silicon', 'aluminum', 'slag', 'silica', 'alumina'};
    legendLabels = {};
    
    % Define custom colors (darker for slag and non-replicables)
    customColors = containers.Map();
    customColors('slag') = [0.5, 0.3, 0.0]; % Darker brown for slag
    
    % Filter out materials with no data
    validMaterials = [];
    for i = 1:length(materialFields)
        if isfield(factory.metrics.materialFlows, materialFields{i})
            data = factory.metrics.materialFlows.(materialFields{i})(1:factory.currentTimeStep);
            if any(data > 0)
                validMaterials = [validMaterials, i];
            end
        end
    end
    
    % Plot line for each material - RAW MATERIALS
    subplot(2, 1, 1);
    hold on;
    
    % Use a professional colormap suitable for publication
    % Using the 'parula' colormap which has good differentiation
    colorMap = parula(length(validMaterials));
    
    % Set line styles for better differentiation even in B&W printing
    lineStyles = {'-', '--', ':', '-.', '-', '--', ':', '-.'};
    
    % Track minimum non-zero value for log scale adjustment
    minNonZeroValue = inf;
    
    for i = 1:length(validMaterials)
        idx = validMaterials(i);
        materialName = materialFields{idx};
        if isfield(factory.metrics.materialFlows, materialName)
            data = factory.metrics.materialFlows.(materialName)(1:factory.currentTimeStep);
            
            % Find minimum non-zero value for log scale
            nonZeroData = data(data > 0);
            if ~isempty(nonZeroData)
                minNonZeroValue = min(minNonZeroValue, min(nonZeroData));
            end
            
            % Select line style to improve differentiation
            lineStyleIdx = mod(i-1, length(lineStyles)) + 1;
            
            % Use custom color for slag, default colormap otherwise
            if strcmp(materialName, 'slag')
                color = customColors(materialName);
            else
                color = colorMap(i,:);
            end
            
            % Plot with enhanced styling
            plot(timeMonths, data, lineStyles{lineStyleIdx}, 'LineWidth', 2, 'Color', color, 'MarkerSize', 6);
            legendLabels{end+1} = strrep(materialName, '_', ' ');
        end
    end
    
    % Set log scale for y-axis
    set(gca, 'YScale', 'log');
    
    % Handle zero values for log scale
    if minNonZeroValue == inf
        minNonZeroValue = 1;
    end
    % Set lower limit to slightly below minimum non-zero value
    yLimLower = minNonZeroValue * 0.1;
    % Get current y limits and adjust only the lower limit
    yLims = get(gca, 'YLim');
    set(gca, 'YLim', [yLimLower, yLims(2)]);
    
    % Enhance axis properties - add FontName property
    xlabel('Time (months)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    ylabel('Raw Material Inventory (kg) - Log Scale', 'FontWeight', 'bold', 'FontName', 'Garamond');
    title('Raw Material Inventory Changes Over Time', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Garamond');
    
    % Enhanced legend - add FontName property
    if ~isempty(legendLabels)
        leg = legend(legendLabels, 'Location', 'best', 'FontSize', 10, 'Box', 'off');
        set(leg, 'FontName', 'Garamond');
    end
    
    % Enhanced grid
    grid on;
    set(gca, 'GridLineStyle', ':');
    set(gca, 'Layer', 'top');  % Ensure grid is behind the data
    set(gca, 'FontName', 'Garamond'); % Ensure tick labels use Garamond
    
    % Add box for clean appearance
    box on;
    
    % MANUFACTURED MATERIALS
    subplot(2, 1, 2);
    hold on;
    
    % Check for manufactured materials
    manufacturedMaterials = {'castAluminum', 'castIron', 'castSlag', 'precisionAluminum', 'precisionIron', ...
                             'precisionAlumina', 'sinteredAlumina', 'silicaGlass', 'sinteredRegolith', 'solarThinFilm', 'nonReplicable'};
    
    % Define custom color for nonReplicable
    customColors('nonReplicable') = [0.3, 0.3, 0.3]; % Darker gray for nonReplicable
    
    legendLabels = {};
    
    % Filter out materials with no data
    validMaterials = [];
    for i = 1:length(manufacturedMaterials)
        if isfield(factory.metrics.materialFlows, manufacturedMaterials{i})
            data = factory.metrics.materialFlows.(manufacturedMaterials{i})(1:factory.currentTimeStep);
            if any(data > 0)
                validMaterials = [validMaterials, i];
            end
        end
    end
    
    % Track minimum non-zero value for log scale adjustment
    minNonZeroValue = inf;
    
    % Plot line for each material with enhanced styling
    colorMap = parula(length(validMaterials));
    for i = 1:length(validMaterials)
        idx = validMaterials(i);
        materialName = manufacturedMaterials{idx};
        if isfield(factory.metrics.materialFlows, materialName)
            data = factory.metrics.materialFlows.(materialName)(1:factory.currentTimeStep);
            
            % Find minimum non-zero value for log scale
            nonZeroData = data(data > 0);
            if ~isempty(nonZeroData)
                minNonZeroValue = min(minNonZeroValue, min(nonZeroData));
            end
            
            % Select line style to improve differentiation
            lineStyleIdx = mod(i-1, length(lineStyles)) + 1;
            
            % Use custom color for nonReplicable, default colormap otherwise
            if strcmp(materialName, 'nonReplicable')
                color = customColors(materialName);
            else
                color = colorMap(i,:);
            end
            
            % Plot with enhanced styling
            plot(timeMonths, data, lineStyles{lineStyleIdx}, 'LineWidth', 2, 'Color', color, 'MarkerSize', 6);
            legendLabels{end+1} = strrep(materialName, '_', ' ');
        end
    end
    
    % Set log scale for y-axis
    set(gca, 'YScale', 'log');
    
    % Handle zero values for log scale
    if minNonZeroValue == inf
        minNonZeroValue = 1;
    end
    % Set lower limit to slightly below minimum non-zero value
    yLimLower = minNonZeroValue * 0.1;
    % Get current y limits and adjust only the lower limit
    yLims = get(gca, 'YLim');
    set(gca, 'YLim', [yLimLower, yLims(2)]);
    
    % Enhance axis properties - add FontName property
    xlabel('Time (months)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    ylabel('Manufactured Material Inventory (kg) - Log Scale', 'FontWeight', 'bold', 'FontName', 'Garamond');
    title('Manufactured Material Inventory', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Garamond');
    
    % Enhanced legend with better placement - add FontName property
    if ~isempty(legendLabels)
        if length(legendLabels) > 6
            leg = legend(legendLabels, 'Location', 'eastoutside', 'FontSize', 10, 'Box', 'off');
        else
            leg = legend(legendLabels, 'Location', 'best', 'FontSize', 10, 'Box', 'off');
        end
        set(leg, 'FontName', 'Garamond');
    end
    
    % Enhanced grid
    grid on;
    set(gca, 'GridLineStyle', ':');
    set(gca, 'Layer', 'top');
    set(gca, 'FontName', 'Garamond'); % Ensure tick labels use Garamond
    
    % Add box for clean appearance
    box on;
    
    % Improve overall figure layout
    set(figInventory, 'PaperPositionMode', 'auto');
    set(figInventory, 'Renderer', 'painters');  % Better for vector output
    
    % Final pass to ensure all text elements use Garamond
    set(findall(figInventory, '-property', 'FontName'), 'FontName', 'Garamond');
    
    % Save figure if requested
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'inventory_changes.png');
        print(figInventory, figFilename, '-dpng', '-r300');  % Higher resolution (300 dpi)
        fprintf('Inventory changes visualization saved to %s\n', figFilename);
    end
end

%% Strategy Effectiveness with Annotations
function visualizeStrategyEffectiveness(factory, timeMonths, options)
    % Create figure for strategy effectiveness
    figStrategy = figure('Name', 'Strategy Effectiveness Analysis', 'Position', [100, 100, 1200, 800]);
    
    % Check if optimization history exists (for automated runs)
    hasOptimizationHistory = isfield(factory, 'optimizationHistory') && ...
                            ~isempty(factory.optimizationHistory) && ...
                            isfield(factory.optimizationHistory, 'strategies');
    
    % Plot main metrics
    subplot(2, 1, 1);
    yyaxis left;
    plot(timeMonths, factory.metrics.totalMass(1:factory.currentTimeStep), 'b-', 'LineWidth', 2);
    ylabel('Total Mass (kg)', 'FontWeight', 'bold');
    
    yyaxis right;
    if factory.currentTimeStep > 1
        plot(timeMonths(2:end), factory.metrics.monthlyGrowthRate(2:end)*100, 'r-', 'LineWidth', 2);
    end
    ylabel('Monthly Growth Rate (%)', 'FontWeight', 'bold');
    
    title('Factory Growth and Strategy Effectiveness', 'FontWeight', 'bold', 'FontSize', 14);
    xlabel('Time (months)', 'FontWeight', 'bold');
    grid on;
    
    % Add legend
    legend('Total Mass', 'Growth Rate', 'Location', 'best', 'FontSize', 10);
    
    % Plot subsystem contributions
    subplot(2, 1, 2);
    hold on;
    
    % Group subsystems by category
    processingMass = factory.metrics.subsystemMasses(1:factory.currentTimeStep, 2:4);  % MRE, HCl, VP
    manufacturingMass = factory.metrics.subsystemMasses(1:factory.currentTimeStep, 5:9);  % LPBF, EBPVD, SC, PC, SSLS
    powerMass = factory.metrics.subsystemMasses(1:factory.currentTimeStep, 11:12);  % Landed Solar, Lunar Solar
    otherMass = factory.metrics.subsystemMasses(1:factory.currentTimeStep, [1, 10]);  % Extraction, Assembly
    
    % Calculate total for each category
    processingTotal = sum(processingMass, 2);
    manufacturingTotal = sum(manufacturingMass, 2);
    powerTotal = sum(powerMass, 2);
    otherTotal = sum(otherMass, 2);
    
    % Plot each category
    plot(timeMonths, processingTotal, 'g-', 'LineWidth', 2);
    plot(timeMonths, manufacturingTotal, 'm-', 'LineWidth', 2);
    plot(timeMonths, powerTotal, 'c-', 'LineWidth', 2);
    plot(timeMonths, otherTotal, 'k-', 'LineWidth', 2);
    
    % Add legend and labels
    legend('Processing Systems', 'Manufacturing Systems', 'Power Systems', 'Other Systems', ...
           'Location', 'best', 'FontSize', 10);
    xlabel('Time (months)', 'FontWeight', 'bold');
    ylabel('Mass (kg)', 'FontWeight', 'bold');
    title('Subsystem Category Growth', 'FontWeight', 'bold', 'FontSize', 14);
    grid on;
    
    % Add economics overlay if available
    if isfield(factory, 'economics') && isfield(factory.economics, 'cumulativeProfit')
        yyaxis right;
        plot(timeMonths, factory.economics.cumulativeProfit(1:factory.currentTimeStep), 'r--', 'LineWidth', 2);
        ylabel('Cumulative Profit ($)', 'FontWeight', 'bold');
        legend('Processing Systems', 'Manufacturing Systems', 'Power Systems', 'Other Systems', 'Cumulative Profit', ...
               'Location', 'best', 'FontSize', 10);
    end
    
    % Add strategy effectiveness annotation with key takeaways
    if factory.currentTimeStep > 2
        % Calculate average growth rates for different phases
        earlyPhase = 1:min(3, factory.currentTimeStep);
        midPhase = max(1, floor(factory.currentTimeStep/3)):min(floor(2*factory.currentTimeStep/3), factory.currentTimeStep);
        latePhase = max(1, floor(2*factory.currentTimeStep/3)):factory.currentTimeStep;
        
        earlyGrowth = mean(factory.metrics.monthlyGrowthRate(earlyPhase)) * 100;
        midGrowth = mean(factory.metrics.monthlyGrowthRate(midPhase)) * 100;
        lateGrowth = mean(factory.metrics.monthlyGrowthRate(latePhase)) * 100;
        
        % Create annotation text with strategy effectiveness insights
        annotationText = {
            'Strategy Effectiveness:',
            sprintf('Early phase avg. growth: %.1f%%', earlyGrowth),
            sprintf('Mid phase avg. growth: %.1f%%', midGrowth),
            sprintf('Late phase avg. growth: %.1f%%', lateGrowth)
        };
        
        % Add annotation
        annotation('textbox', [0.15, 0.35, 0.2, 0.1], 'String', annotationText, ...
                  'FitBoxToText', 'on', 'BackgroundColor', 'white', 'FontSize', 10);
    end
    
    hold off;
    
    % Set publication-quality formatting
    set(figStrategy, 'Color', 'white');
    set(findall(figStrategy, '-property', 'FontSize'), 'FontSize', 12);
    set(findall(figStrategy, '-property', 'FontName'), 'FontName', 'Garamond');
    
    % Save figure if requested
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'strategy_effectiveness.png');
        print(figStrategy, figFilename, '-dpng', '-r300');
        fprintf('Strategy effectiveness visualization saved to %s\n', figFilename);
    end
end

%% Power Utilization Efficiency Visualization
function visualizePowerUtilization(factory, timeMonths, options)
    % Create figure for power utilization
    figPower = figure('Name', 'Power Utilization Efficiency', 'Position', [100, 100, 1200, 800]);
    
    % Extract power data
    powerCapacity = factory.metrics.powerCapacity(1:factory.currentTimeStep);
    powerDemand = factory.metrics.powerDemand(1:factory.currentTimeStep);
    
    % Check if we have subsystem power allocation data
    hasSubsystemPower = isfield(factory.metrics, 'subsystemPower') && ...
                        ~isempty(factory.metrics.subsystemPower) && ...
                        size(factory.metrics.subsystemPower, 1) >= factory.currentTimeStep;
    
    % Plot power capacity and demand
    subplot(2, 1, 1);
    plot(timeMonths, powerCapacity, 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths, powerDemand, 'r-', 'LineWidth', 2);
    
    % Calculate and plot power utilization ratio
    utilizationRatio = zeros(size(powerCapacity));
    for i = 1:length(powerCapacity)
        if powerCapacity(i) > 0
            utilizationRatio(i) = min(powerDemand(i) / powerCapacity(i), 1);  % Cap at 100%
        else
            utilizationRatio(i) = 0;
        end
    end
    
    yyaxis right;
    plot(timeMonths, utilizationRatio * 100, 'g-', 'LineWidth', 2);
    
    % Add labels and legend
    xlabel('Time (months)', 'FontWeight', 'bold');
    yyaxis left;
    ylabel('Power (W)', 'FontWeight', 'bold');
    yyaxis right;
    ylabel('Utilization (%)', 'FontWeight', 'bold');
    title('Power Capacity, Demand, and Utilization Over Time', 'FontWeight', 'bold', 'FontSize', 14);
    legend('Generation Capacity', 'Power Demand', 'Utilization Ratio', 'Location', 'best', 'FontSize', 10);
    grid on;
   
    
    % Plot detailed power allocation if available
    subplot(2, 1, 2);
    if hasSubsystemPower
        % Get subsystem power data
        subsystemPower = factory.metrics.subsystemPower(1:factory.currentTimeStep, :);
        
        % Get names for power distribution
        powerDistFields = fieldnames(factory.powerDistribution);
        
        % Calculate total allocated power for each time step
        totalAllocated = sum(subsystemPower, 2);
        
        % Define the same custom colormap used in visualizeSubsystemGrowth
        customColorMap = [
            0.2, 0.7, 0.2;  % Extraction (green)
            0.1, 0.3, 0.8;  % Processing MRE (blue)
            0.2, 0.4, 0.9;  % Processing HCl (lighter blue)
            0.3, 0.5, 1.0;  % Processing VP (lightest blue)
            0.8, 0.0, 0.0;  % Manufacturing LPBF (dark red)
            0.9, 0.2, 0.2;  % Manufacturing EBPVD (purple)
            1.0, 0.4, 0.4;  % Manufacturing SC (pink)
            0.7, 0.5, 0.5;  % Manufacturing PC (orange/brown)
            0.8, 0.6, 0.6;  % Manufacturing SSLS (orange)
            0.5, 0.5, 0.5;  % Assembly (gray)
            0.9, 0.7, 0.1;  % Power Landed Solar (gold)
            1.0, 0.8, 0.2   % Power Lunar Solar (yellow)
        ];
        
        % Plot stacked area chart for power allocation
        areaHandle = area(timeMonths, subsystemPower);
    
    % Apply custom colors to each area
    for i = 1:length(areaHandle)
        if i <= size(customColorMap, 1)
            set(areaHandle(i), 'FaceColor', customColorMap(i,:));
            % Add edge color for better differentiation in B&W printing
            set(areaHandle(i), 'EdgeColor', [0.3, 0.3, 0.3], 'LineWidth', 0.5);
        end
    end
    
    hold on;
    
    % Add power capacity and demand lines
    plot(timeMonths, powerCapacity, 'k-', 'LineWidth', 2);
    plot(timeMonths, powerDemand, 'r--', 'LineWidth', 2);
    
    % Add labels and legend
    xlabel('Time (months)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    ylabel('Power (W)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    title('Power Allocation by Subsystem', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Garamond');
    
    % FIX: Convert column cell array to row cell array for legend labels
    subsystemLabels = strrep(powerDistFields, '_', ' ');
    subsystemLabels = subsystemLabels(:)';  % Force to be a row vector
    
    % Combine with 'Capacity' and 'Demand'
    legendLabels = [subsystemLabels, {'Capacity', 'Demand'}];
    leg = legend(legendLabels, 'Location', 'eastoutside', 'FontSize', 10);
    set(leg, 'FontName', 'Garamond'); % Ensure legend uses Garamond
    
    grid on;
    set(gca, 'FontName', 'Garamond'); % Ensure tick labels use Garamond
        
        % Calculate efficiency metrics
        avgUtilization = mean(utilizationRatio) * 100;
        maxUtilization = max(utilizationRatio) * 100;
        
        % Calculate allocation efficiency (allocated vs. actually used)
        allocationEfficiency = zeros(size(totalAllocated));
        for i = 1:length(totalAllocated)
            if totalAllocated(i) > 0
                allocationEfficiency(i) = min(powerDemand(i) / totalAllocated(i), 1) * 100;
            else
                allocationEfficiency(i) = 0;
            end
        end
        avgAllocationEfficiency = mean(allocationEfficiency);
        
        % Add text annotation with efficiency metrics
        efficiency_text = {
            'Power Efficiency Metrics:',
            ['Average Utilization: ' num2str(avgUtilization, '%.1f') '%'],
            ['Peak Utilization: ' num2str(maxUtilization, '%.1f') '%'],
            ['Allocation Efficiency: ' num2str(avgAllocationEfficiency, '%.1f') '%']
        };
        
        annotation('textbox', [0.15, 0.25, 0.3, 0.1], 'String', efficiency_text, ...
                  'FitBoxToText', 'on', 'BackgroundColor', 'white', 'FontSize', 10);
    else
        % If detailed data not available, show simplified view
        bar(timeMonths, [powerCapacity, powerDemand]);
        xlabel('Time (months)', 'FontWeight', 'bold');
        ylabel('Power (W)', 'FontWeight', 'bold');
        title('Power Generation and Demand', 'FontWeight', 'bold', 'FontSize', 14);
        legend('Generation Capacity', 'Power Demand', 'Location', 'best', 'FontSize', 10);
        grid on;
        
        % Add text warning
        text(0.5, 0.5, 'Detailed power allocation data not available in this simulation', ...
             'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
    
    % Set publication-quality formatting
    set(figPower, 'Color', 'white');
    set(findall(figPower, '-property', 'FontSize'), 'FontSize', 12);
    set(findall(figPower, '-property', 'FontName'), 'FontName', 'Garamond');
    
    % Save figure if requested
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'power_utilization.png');
        print(figPower, figFilename, '-dpng', '-r300');
        fprintf('Power utilization visualization saved to %s\n', figFilename);
    end
end

%% Bottleneck Analysis Visualization
function visualizeBottleneckAnalysis(factory, timeMonths, options)
    % Create figure for bottleneck analysis
    figBottleneck = figure('Name', 'Factory Bottleneck Analysis', 'Position', [100, 100, 1200, 800]);
    
    % Calculate capacities over time for each system category
    numSteps = factory.currentTimeStep;
    extractionCapacity = zeros(numSteps, 1);
    processingCapacity = zeros(numSteps, 1);
    manufacturingCapacity = zeros(numSteps, 1);
    assemblyCapacity = zeros(numSteps, 1);
    powerCapacity = factory.metrics.powerCapacity(1:numSteps);
    powerDemand = factory.metrics.powerDemand(1:numSteps);
    
    % Get subsystem masses over time
    subsystemMasses = factory.metrics.subsystemMasses(1:numSteps, :);
    
    % Capacity scaling factors from factory configuration
    % Extraction
    extractionRate = factory.subConfig.extraction.excavationRate; % kg/hr per unit
    
    % Processing
    mreCoefficient = 1.492; % kg/(kg oxygen/year) - from formula in subsystemConfig
    mreScaling = 23720 / 10000; % Ratio of regolith to oxygen
    hclScalingFactor = factory.subConfig.processingHCl.massScalingFactorHCl; % kg/(kg/hr)
    vpScalingFactor = factory.subConfig.processingVP.massScalingFactor; % kg/(kg/hr)
    
    % Manufacturing
    lpbfInputRate = 0.23 + 0.68 + 0.34; % Sum of input rates (aluminum, iron, alumina)
    EBPVDScalingFactorLunar = factory.subConfig.manufacturingEBPVD.massScalingFactorLunar; % kg/(kg/hr)
    scScalingFactor = 33.3; % kg/(kg/hr) - default value
    if isfield(factory.subConfig, 'manufacturingSC') && isfield(factory.subConfig.manufacturingSC, 'massScalingFactor')
        scScalingFactor = factory.subConfig.manufacturingSC.massScalingFactor;
    end
    pcScalingFactor = factory.subConfig.manufacturingPC.massScalingFactor; % kg/(kg/hr)
    sslsScalingFactor = factory.subConfig.manufacturingSSLS.massScalingFactorLunar; % kg/(kg/hr)
    
    % Assembly
    assemblyRate = factory.subConfig.assembly.assemblyCapacity; % kg/hr per unit
    
    % Calculate capacities for each time step
    for step = 1:numSteps
        % Extraction capacity
        if isfield(factory.metrics, 'extractionRate')
            extractionCapacity(step) = factory.metrics.extractionRate(step);
        else
            % Estimate from extraction subsystem mass and configuration
            units = subsystemMasses(step, 1) / factory.subConfig.extraction.massPerUnit;
            extractionCapacity(step) = units * extractionRate;
        end
        
        % Processing capacity
        % MRE
        mreMass = subsystemMasses(step, 2);
        if mreMass > 0
            % Convert based on MRE formula and scaling
            mreCapacity = (mreMass / mreCoefficient)^(1/0.608) * 2 * factory.processingMRE.dutyCycle;
            mreCapacity = mreCapacity * mreScaling / (24 * 365); % Convert to kg/hr
        else
            mreCapacity = 0;
        end
        
        % HCl
        hclMass = subsystemMasses(step, 3);
        hclCapacity = 0;
        if hclMass > 0
            hclCapacity = hclMass / hclScalingFactor;
        end
        
        % VP
        vpMass = subsystemMasses(step, 4);
        vpCapacity = 0;
        if vpMass > 0
            vpCapacity = vpMass / vpScalingFactor;
        end
        
        % Total processing capacity
        processingCapacity(step) = mreCapacity + hclCapacity + vpCapacity;
        
        % Manufacturing capacity
        % LPBF
        lpbfMass = subsystemMasses(step, 5);
        lpbfCapacity = 0;
        if lpbfMass > 0
            % Use units estimated from mass
            units = lpbfMass / factory.manufacturingLPBF.massPerUnit;
            lpbfCapacity = units * lpbfInputRate;
        end
        
        % EBPVD
        EBPVDMass = subsystemMasses(step, 6);
        EBPVDCapacity = 0;
        if EBPVDMass > 0
            EBPVDCapacity = EBPVDMass / EBPVDScalingFactorLunar;
        end
        
        % SC
        scMass = subsystemMasses(step, 7);
        scCapacity = 0;
        if scMass > 0
            scCapacity = scMass / scScalingFactor;
        end
        
        % PC
        pcMass = subsystemMasses(step, 8);
        pcCapacity = 0;
        if pcMass > 0
            pcCapacity = pcMass / pcScalingFactor;
        end
        
        % SSLS
        sslsMass = subsystemMasses(step, 9);
        sslsCapacity = 0;
        if sslsMass > 0
            sslsCapacity = sslsMass / sslsScalingFactor;
        end
        
        % Total manufacturing capacity
        manufacturingCapacity(step) = lpbfCapacity + EBPVDCapacity + scCapacity + pcCapacity + sslsCapacity;
        
        % Assembly capacity
        assemblyMass = subsystemMasses(step, 10);
        units = assemblyMass / factory.subConfig.assembly.massPerUnit;
        assemblyCapacity(step) = units * assemblyRate;
    end
    
    % Plot capacity evolution over time
    subplot(2, 1, 1);
    hold on;
    plot(timeMonths, extractionCapacity, 'g-', 'LineWidth', 2);
    plot(timeMonths, processingCapacity, 'b-', 'LineWidth', 2);
    plot(timeMonths, manufacturingCapacity, 'r-', 'LineWidth', 2);
    plot(timeMonths, assemblyCapacity, 'm-', 'LineWidth', 2);
    
    % Add labels and legend
    xlabel('Time (months)', 'FontWeight', 'bold');
    ylabel('Capacity (kg/hr)', 'FontWeight', 'bold');
    title('System Capacity Evolution Over Time', 'FontWeight', 'bold', 'FontSize', 14);
    legend('Extraction', 'Processing', 'Manufacturing', 'Assembly', ...
           'Location', 'best', 'FontSize', 10);
    grid on;
    
    % Plot power utilization as secondary axis
    yyaxis right;
    powerUtil = zeros(size(powerCapacity));
    for i = 1:length(powerCapacity)
        if powerCapacity(i) > 0
            powerUtil(i) = min(powerDemand(i) / powerCapacity(i), 1) * 100;
        end
    end
    plot(timeMonths, powerUtil, 'c--', 'LineWidth', 2);
    ylabel('Power Utilization (%)', 'FontWeight', 'bold');
    legend('Extraction', 'Processing', 'Manufacturing', 'Assembly', 'Power Utilization', ...
           'Location', 'best', 'FontSize', 10);
    
    % Calculate and plot capacity ratios to identify bottlenecks
    subplot(2, 1, 2);
    hold on;
    
    % Calculate capacity ratios
    extractToProcess = zeros(numSteps, 1);
    processToManufacture = zeros(numSteps, 1);
    manufactureToAssembly = zeros(numSteps, 1);
    
    % Set threshold for balanced ratios (1.0 means perfectly balanced)
    balancedThreshold = 1.0;
    
    for step = 1:numSteps
        % Avoid division by zero
        if processingCapacity(step) > 0
            extractToProcess(step) = extractionCapacity(step) / processingCapacity(step);
        else
            extractToProcess(step) = 0;
        end
        
        if manufacturingCapacity(step) > 0
            processToManufacture(step) = processingCapacity(step) / manufacturingCapacity(step);
        else
            processToManufacture(step) = 0;
        end
        
        if assemblyCapacity(step) > 0
            manufactureToAssembly(step) = manufacturingCapacity(step) / assemblyCapacity(step);
        else
            manufactureToAssembly(step) = 0;
        end
    end
    
    % Plot capacity ratios
    plot(timeMonths, extractToProcess, 'g-', 'LineWidth', 2);
    plot(timeMonths, processToManufacture, 'b-', 'LineWidth', 2);
    plot(timeMonths, manufactureToAssembly, 'r-', 'LineWidth', 2);
    
    % Add balanced threshold line
    plot([timeMonths(1), timeMonths(end)], [balancedThreshold, balancedThreshold], 'k--', 'LineWidth', 1.5);
    
    % Add labels and legend
    xlabel('Time (months)', 'FontWeight', 'bold');
    ylabel('Capacity Ratio', 'FontWeight', 'bold');
    title('Capacity Ratios and Bottleneck Identification', 'FontWeight', 'bold', 'FontSize', 14);
    legend('Extraction/Processing', 'Processing/Manufacturing', 'Manufacturing/Assembly', 'Balanced Ratio', ...
           'Location', 'best', 'FontSize', 10);
    grid on;

    % Create annotation of bottleneck analysis
    bottleneckMetrics = {
        'Bottleneck Analysis:',
        ['Extraction/Processing Ratio: ', num2str(extractToProcess(end), '%.2f')],
        ['Processing/Manufacturing Ratio: ', num2str(processToManufacture(end), '%.2f')],
        ['Manufacturing/Assembly Ratio: ', num2str(manufactureToAssembly(end), '%.2f')],
    };
    
    annotation('textbox', [0.25, 0.15, 0.3, 0.18], 'String', bottleneckMetrics, ...
              'FitBoxToText', 'on', 'BackgroundColor', 'white', 'FontSize', 10);
    
    % Set publication-quality formatting
    set(figBottleneck, 'Color', 'white');
    set(findall(figBottleneck, '-property', 'FontSize'), 'FontSize', 12);
    set(findall(figBottleneck, '-property', 'FontName'), 'FontName', 'Garamond');
    
    % Save figure if requested
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'bottleneck_analysis.png');
        print(figBottleneck, figFilename, '-dpng', '-r300');
        fprintf('Bottleneck analysis visualization saved to %s\n', figFilename);
    end
end
function visualizeSubsystemGrowth(factory, timeMonths, options)
    % Create figure for subsystem growth with publication-quality standards
    figSubsystems = figure('Name', 'Lunar Factory Subsystem Growth', 'Position', [100, 100, 1200, 900]);
    
    % Set figure properties for publication quality
    set(figSubsystems, 'Color', 'white');
    set(findall(figSubsystems, '-property', 'FontName'), 'FontName', 'Garamond');
    set(findall(figSubsystems, '-property', 'FontSize'), 'FontSize', 12);
    
    % Get subsystem names
    subsystemNames = {
        'Extraction', ...
        'Processing (MRE)', ...
        'Processing (HCl)', ...
        'Processing (VP)',...
        'Manufacturing (LPBF)', ...
        'Manufacturing (EBPVD)', ...
        'Manufacturing (SC)', ...
        'Manufacturing (PC)', ...
        'Manufacturing (SSLS)',...
        'Assembly', ...
        'Power (Landed Solar)', ...
        'Power (Lunar Solar)'
    };
    
    % Define a custom colormap with more contrast between manufacturing systems
    customColorMap = [
        0.2, 0.7, 0.2;  % Extraction (green)
        0.1, 0.3, 0.8;  % Processing MRE (blue)
        0.2, 0.4, 0.9;  % Processing HCl (lighter blue)
        0.3, 0.5, 1.0;  % Processing VP (lightest blue)
        0.8, 0.0, 0.0;  % Manufacturing LPBF (dark red)
        0.9, 0.2, 0.2;  % Manufacturing EBPVD (purple)
        1.0, 0.4, 0.4;  % Manufacturing SC (pink)
        0.7, 0.5, 0.5;  % Manufacturing PC (orange/brown)
        0.8, 0.6, 0.6;  % Manufacturing SSLS (orange)
        0.5, 0.5, 0.5;  % Assembly (gray)
        0.9, 0.7, 0.1;  % Power Landed Solar (gold)
        1.0, 0.8, 0.2   % Power Lunar Solar (yellow)
    ];
    
    % Get subsystem masses evolution
    if isfield(factory.metrics, 'subsystemMasses') && ~isempty(factory.metrics.subsystemMasses)
        % We have historical subsystem mass data
        massEvolution = factory.metrics.subsystemMasses(1:factory.currentTimeStep, :);
        
        % Create stacked area chart for overall mass evolution with academic styling
        subplot(3, 1, [1, 2]);  % Take up 2/3 of the figure height
        
        % Create area chart with custom colormap
        areaHandle = area(timeMonths, massEvolution);
        
        % Apply custom colors to each area
        for i = 1:length(areaHandle)
            set(areaHandle(i), 'FaceColor', customColorMap(i,:));
            % Add edge color for better differentiation in B&W printing
            set(areaHandle(i), 'EdgeColor', [0.3, 0.3, 0.3], 'LineWidth', 0.5);
        end
        
        % Enhance axes
        xlabel('Time (months)', 'FontWeight', 'bold','FontName', 'Garamond');
        ylabel('Mass (kg)', 'FontWeight', 'bold','FontName', 'Garamond');
        title('Total Subsystem Mass Evolution', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Garamond');
        
        % Calculate and display total mass - MOVED UP TO AVOID OVERLAP WITH GRAPH
        totalMass = sum(massEvolution(end,:));
        text(timeMonths(end)*0.98, sum(massEvolution(end,:))*1.15, ...
             ['Total: ' num2str(totalMass, '%.0f') ' kg'], ...
             'HorizontalAlignment', 'right', 'FontWeight', 'bold', ...
             'BackgroundColor', [1 1 0.9], 'EdgeColor', 'k');
        
        % Enhanced legend with better placement
        legend(subsystemNames, 'Location', 'eastoutside', 'FontSize', 10, 'Box', 'off','FontName', 'Garamond');
        grid on;
        set(gca, 'GridLineStyle', ':');
        set(gca, 'Layer', 'top');
        box on;
        
        % Create a pie chart to show the final mass distribution
        subplot(3, 1, 3);  % Bottom third
        
        % Get final masses
        finalMasses = massEvolution(end, :);
        
        % Remove zero mass subsystems for cleaner pie chart
        nonZeroIdx = find(finalMasses > 0);
        nonZeroMasses = finalMasses(nonZeroIdx);
        nonZeroNames = subsystemNames(nonZeroIdx);
        nonZeroColors = customColorMap(nonZeroIdx, :);
        
        % Calculate percentages for labels
        percentages = 100 * nonZeroMasses / sum(nonZeroMasses);
        
        % Create custom labels with percentages and masses
        pieLabels = cell(size(nonZeroMasses));
        for i = 1:length(nonZeroMasses)
            % Empty labels - we'll add text annotations later
            pieLabels{i} = '';
        end
        
        % Create pie chart with enhanced styling and no labels initially
        p = pie(nonZeroMasses, pieLabels);
        
        % Apply custom colors
        h = findobj(gca, 'Type', 'patch');
        for i = 1:length(h)
            set(h(i), 'FaceColor', nonZeroColors(length(h)-i+1,:));
            set(h(i), 'EdgeColor', [0.3, 0.3, 0.3], 'LineWidth', 0.5);
        end
        
        % Add title
        title('Final Subsystem Mass Distribution', 'FontWeight', 'bold', 'FontSize', 14,'FontName', 'Garamond');
        
        % Create legend entries with percentages and masses
        legendText = cell(size(nonZeroMasses));
        for i = 1:length(nonZeroMasses)
            legendText{i} = sprintf('%s: %.1f%% (%.0f kg)', ...
                           nonZeroNames{i}, percentages(i), nonZeroMasses(i));
        end
        
        % Add legend to the side of the pie chart
        sliceHandles = p(1:2:end);  % Get handles to the pie slices
        legend(sliceHandles, legendText, 'Location', 'eastoutside', 'FontSize', 9,'FontName', 'Garamond');
        
    else
        % Fallback: show current subsystem masses only
        warning('Historical subsystem mass data not available. Showing current distribution only.');
        
        % Get current subsystem masses
        subsystemMasses = [
            factory.extraction.mass,...
            factory.processingMRE.mass,...
            factory.processingHCl.mass,...
            factory.processingVP.mass,...
            factory.manufacturingLPBF.mass,...
            factory.manufacturingEBPVD.mass,...
            factory.manufacturingSC.mass,...
            factory.manufacturingPC.mass,...
            factory.manufacturingSSLS.mass,...
            factory.assembly.mass,...
            factory.powerLandedSolar.mass,...
            factory.powerLunarSolar.mass,...
        ];
        
        % Create bar chart with enhanced styling
        barHandle = bar(subsystemMasses);
        
        % Apply custom colors to the bars
        for i = 1:length(subsystemMasses)
            % Access the correct bar element
            if subsystemMasses(i) > 0
                % For bar handles in newer MATLAB versions
                if isfield(get(barHandle), 'FaceColor')
                    set(barHandle, 'FaceColor', 'flat');
                    set(barHandle, 'CData', customColorMap);
                else
                    % Try alternative approach for older versions
                    try
                        barChildren = get(barHandle, 'Children');
                        if ~isempty(barChildren)
                            set(barChildren, 'FaceColor', customColorMap(i,:));
                        end
                    catch
                        % Last resort: just set color properties
                        set(barHandle, 'FaceColor', customColorMap(i,:));
                    end
                end
            end
        end
        
        % Enhance appearance for publication
        set(gca, 'XTick', 1:length(subsystemNames), 'XTickLabel', subsystemNames, 'XTickLabelRotation', 45);
        ylabel('Mass (kg)', 'FontWeight', 'bold');
        title('Current Subsystem Masses', 'FontWeight', 'bold', 'FontSize', 14);
        grid on;
        set(gca, 'GridLineStyle', ':');
        set(gca, 'Layer', 'top');
        box on;
        
        % Add data labels on top of bars
        hold on;
        for i = 1:length(subsystemMasses)
            if subsystemMasses(i) > 0
                text(i, subsystemMasses(i)*1.02, num2str(subsystemMasses(i), '%.0f'), ...
                     'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
            end
        end
        hold off;
    end
    
    % Add explanatory note for the visualization
    subsystemCategories = {
        'Processing Systems (Blue)',
        'Manufacturing Systems (Red/Purple/Orange)',
        'Power Systems (Yellow)',
        'Other Systems (Green/Gray)'
    };
   
    
    % Improve overall figure layout
    set(figSubsystems, 'PaperPositionMode', 'auto');
    set(figSubsystems, 'Renderer', 'painters');  % Better for vector output
    
    % Save figure if requested with high resolution
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'subsystem_growth.png');
        print(figSubsystems, figFilename, '-dpng', '-r300');  % High resolution (300 dpi)
        fprintf('Subsystem growth visualization saved to %s\n', figFilename);
    end
end
function visualizeGrowthRates(factory, timeMonths, options)
    % Create figure for growth rates with publication-quality standards
    figGrowth = figure('Name', 'Lunar Factory Growth Rates', 'Position', [100, 100, 1200, 800]);
    
    % Set figure properties for publication quality
    set(figGrowth, 'Color', 'white');
    set(findall(figGrowth, '-property', 'FontName'), 'FontName', 'Garamond');
    set(findall(figGrowth, '-property', 'FontSize'), 'FontSize', 12);
    
    % Create subplot for monthly and annual growth rates
    subplot(2, 1, 1);
    
    % Only plot if we have more than one data point
    if factory.currentTimeStep > 1
        yyaxis left;
        plot(timeMonths(2:end), factory.metrics.monthlyGrowthRate(2:end)*100, 'b-', 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', 'b');
        ylabel('Monthly Growth Rate (%)', 'FontWeight', 'bold');
        
        % Set appropriate Y-axis limits to avoid extreme values
        monthlyGrowthData = factory.metrics.monthlyGrowthRate(2:end)*100;
        maxRate = max(monthlyGrowthData);
        minRate = min(monthlyGrowthData);
        range = maxRate - minRate;
        ylim([max(0, minRate - 0.1*range), maxRate + 0.1*range]);
        
        yyaxis right;
        plot(timeMonths(2:end), factory.metrics.annualGrowthRate(2:end)*100, 'r--', 'LineWidth', 2, 'Marker', 's', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        ylabel('Annual Growth Rate (%)', 'FontWeight', 'bold');
        
        % Highlight exceptional growth points
        hold on;
        yyaxis left;
        
        % Find remarkable points (local maxima and minima)
        if length(monthlyGrowthData) > 3
            for i = 2:length(monthlyGrowthData)-1
                if (monthlyGrowthData(i) > monthlyGrowthData(i-1) && monthlyGrowthData(i) > monthlyGrowthData(i+1)) || ...
                   (monthlyGrowthData(i) < monthlyGrowthData(i-1) && monthlyGrowthData(i) < monthlyGrowthData(i+1))
                    plot(timeMonths(i+1), monthlyGrowthData(i), 'ko', 'MarkerSize', 8);
                end
            end
        end
        
        % Add horizontal reference line at 0% growth
        plot([timeMonths(2), timeMonths(end)], [0, 0], 'k:', 'LineWidth', 1);
        
        hold off;
        
        % Title and legend with enhanced styling
        title('Factory Growth Rates Over Time', 'FontWeight', 'bold', 'FontSize', 14);
        legend('Monthly Growth Rate', 'Annual Growth Rate', 'Location', 'best', 'FontSize', 10, 'Box', 'off');
    else
        % Display message if insufficient data
        text(0.5, 0.5, 'Insufficient data for growth rate calculation', ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'Units', 'normalized');
    end
    
    % Enhanced grid styling
    grid on;
    set(gca, 'GridLineStyle', ':');
    set(gca, 'Layer', 'top');
    
    % Add box for clean appearance
    box on;
    
    % X-axis label for first subplot
    xlabel('Time (months)', 'FontWeight', 'bold');
    
    % Create subplot for replication factor with academic styling
    subplot(2, 1, 2);
    
    % Plot replication factor with enhanced styling
    plot(timeMonths, factory.metrics.replicationFactor(1:factory.currentTimeStep), ...
         'Color', [0.2, 0.6, 0.2], 'LineWidth', 2.5, 'Marker', 'o', 'MarkerSize', 4, ...
         'MarkerFaceColor', [0.2, 0.6, 0.2], 'MarkerEdgeColor', 'none');
    
    xlabel('Time (months)', 'FontWeight', 'bold');
    ylabel('Replication Factor', 'FontWeight', 'bold');
    title('Factory Replication Factor Over Time', 'FontWeight', 'bold', 'FontSize', 14);
    
    % Enhanced grid styling
    grid on;
    set(gca, 'GridLineStyle', ':');
    set(gca, 'Layer', 'top');
    
    % Add box for clean appearance
    box on;
    
    % Add reference line at replication factor = 1 with annotation
    hold on;
    plot([timeMonths(1), timeMonths(end)], [1, 1], 'k--', 'LineWidth', 1.5);
    
    % Add annotation for the reference line
    text(timeMonths(end)*0.98, 1.05, 'Break-even point (factor = 1)', ...
         'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
    
    % Calculate days to reach replication factor of 1
    repFactors = factory.metrics.replicationFactor(1:factory.currentTimeStep);
    if any(repFactors >= 1)
        firstIndex = find(repFactors >= 1, 1);
        daysToBreakEven = timeMonths(firstIndex) * 30; % Convert months to days (approximate)
        
        % Add annotation for break-even point
        text(timeMonths(firstIndex), repFactors(firstIndex)*1.1, ...
             sprintf('Break-even at %.1f months (≈%.0f days)', timeMonths(firstIndex), daysToBreakEven), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontWeight', 'bold', 'BackgroundColor', [1 1 0.8]);
        
        % Mark the break-even point
        plot(timeMonths(firstIndex), repFactors(firstIndex), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    end
    
    % Find maximum replication factor for annotation
    [maxReplication, maxIndex] = max(repFactors);
    text(timeMonths(maxIndex), maxReplication*1.05, ...
         sprintf('Max: %.2f', maxReplication), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
         'FontWeight', 'bold');
    
    % Improve overall figure layout
    set(figGrowth, 'PaperPositionMode', 'auto');
    set(figGrowth, 'Renderer', 'painters');  % Better for vector output
    
    % Save figure if requested with high resolution
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'growth_rates.png');
        print(figGrowth, figFilename, '-dpng', '-r300');  % High resolution (300 dpi)
        fprintf('Growth rates visualization saved to %s\n', figFilename);
    end
end



%% Lunar-Manufactured Percentage Visualization
function visualizeLunarManufacturedPercentage(factory, timeMonths, options)
    % Create figure for lunar manufacturing percentage
    figLunar = figure('Name', 'Lunar-Manufactured Components Analysis', 'Position', [100, 100, 1200, 800]);
    
    % Get subsystem masses
    subsystemMasses = factory.metrics.subsystemMasses(1:factory.currentTimeStep, :);
    
    % Define which subsystems can be lunar-manufactured
    subsystemNames = {
        'Extraction', ...
        'Processing (MRE)', ...
        'Processing (HCl)', ...
        'Processing (VP)',...
        'Manufacturing (LPBF)', ...
        'Manufacturing (EBPVD)', ...
        'Manufacturing (SC)', ...
        'Manufacturing (PC)', ...
        'Manufacturing (SSLS)',...
        'Assembly', ...
        'Power (Landed Solar)', ...
        'Power (Lunar Solar)'
    };
    
    % Power (Lunar Solar) is always 100% lunar-manufactured
    lunarSolarIndex = 12;
    
    % For other subsystems, estimate based on time or track using available data
    lunarManufacturedRatio = zeros(factory.currentTimeStep, length(subsystemNames));
    
    % Tracking Earth-sourced non-replicable components used in manufacturing
    nonReplicableUsed = zeros(factory.currentTimeStep, length(subsystemNames));
    
    % Get non-replicable consumption history if available
    hasNonReplicableHistory = false;
    if isfield(factory.metrics, 'nonReplicableBySubsystem') && ...
       ~isempty(factory.metrics.nonReplicableBySubsystem) && ...
       size(factory.metrics.nonReplicableBySubsystem, 1) >= factory.currentTimeStep
        hasNonReplicableHistory = true;
        nonReplicableHistory = factory.metrics.nonReplicableBySubsystem(1:factory.currentTimeStep, :);
    end
    
    % For MRE, we can check if earthManufacturedUnits is tracked
    if isfield(factory.processingMRE, 'earthManufacturedUnits') && factory.processingMRE.units > 0
        % Calculate ratio of lunar manufactured units for each time step
        for step = 1:factory.currentTimeStep
            % Use data from current state for the last step
            if step == factory.currentTimeStep
                lunarUnits = factory.processingMRE.units - factory.processingMRE.earthManufacturedUnits;
                if factory.processingMRE.units > 0
                    lunarManufacturedRatio(step, 2) = lunarUnits / factory.processingMRE.units;
                end
            else
                % For historical data, we need to estimate
                % This would ideally come from recorded metrics
                initialUnits = factory.simConfig.initialConfig.processingMRE.units;
                currentUnits = factory.processingMRE.units; % Estimate based on final state
                estimatedLunarRatio = max(0, (currentUnits - initialUnits) * step / factory.currentTimeStep / currentUnits);
                lunarManufacturedRatio(step, 2) = estimatedLunarRatio;
            end
        end
    else
        % Estimate based on growth from initial configuration
        initialMRE = factory.simConfig.initialConfig.processingMRE.mass;
        for step = 1:factory.currentTimeStep
            currentMass = subsystemMasses(step, 2);
            if currentMass > initialMRE
                lunarManufacturedRatio(step, 2) = (currentMass - initialMRE) / currentMass;
            end
        end
    end
    
    % Estimate for other subsystems based on growth from initial configuration
    
    % Extraction
    initialExtraction = factory.simConfig.initialConfig.extraction.mass;
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 1);
        if currentMass > initialExtraction
            lunarManufacturedRatio(step, 1) = (currentMass - initialExtraction) / currentMass;
        end
    end
    
    % HCl Processing
    initialHCl = factory.simConfig.initialConfig.processingHCl.mass;
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 3);
        if currentMass > initialHCl
            lunarManufacturedRatio(step, 3) = (currentMass - initialHCl) / currentMass;
        end
    end
    
    % VP Processing
    initialVP = 0;
    if isfield(factory.simConfig.initialConfig, 'processingVP')
        initialVP = factory.simConfig.initialConfig.processingVP.mass;
    end
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 4);
        if currentMass > initialVP
            lunarManufacturedRatio(step, 4) = (currentMass - initialVP) / currentMass;
        end
    end
    
    % LPBF Manufacturing
    initialLPBF = factory.simConfig.initialConfig.manufacturingLPBF.mass;
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 5);
        if currentMass > initialLPBF
            lunarManufacturedRatio(step, 5) = (currentMass - initialLPBF) / currentMass;
        end
    end
    
    % EBPVD Manufacturing
    initialEBPVD = factory.simConfig.initialConfig.manufacturingEBPVD.mass;
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 6);
        if currentMass > initialEBPVD
            lunarManufacturedRatio(step, 6) = (currentMass - initialEBPVD) / currentMass;
        end
    end
    
    % SC Manufacturing
    initialSC = 0;
    if isfield(factory.simConfig.initialConfig, 'manufacturingSC')
        initialSC = factory.simConfig.initialConfig.manufacturingSC.mass;
    end
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 7);
        if currentMass > initialSC
            lunarManufacturedRatio(step, 7) = (currentMass - initialSC) / currentMass;
        end
    end
    
    % PC Manufacturing
    initialPC = 0;
    if isfield(factory.simConfig.initialConfig, 'manufacturingPC')
        initialPC = factory.simConfig.initialConfig.manufacturingPC.mass;
    end
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 8);
        if currentMass > initialPC
            lunarManufacturedRatio(step, 8) = (currentMass - initialPC) / currentMass;
        end
    end
    
    % SSLS Manufacturing
    initialSSLS = factory.simConfig.initialConfig.manufacturingSSLS.mass;
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 9);
        if currentMass > initialSSLS
            lunarManufacturedRatio(step, 9) = (currentMass - initialSSLS) / currentMass;
        end
    end
    
    % Assembly
    initialAssembly = factory.simConfig.initialConfig.assembly.mass;
    for step = 1:factory.currentTimeStep
        currentMass = subsystemMasses(step, 10);
        if currentMass > initialAssembly
            lunarManufacturedRatio(step, 10) = (currentMass - initialAssembly) / currentMass;
        end
    end
    
    % Landed Solar is always 0% lunar-manufactured
    % (already initialized to 0)
    
    % Lunar Solar is always 100% lunar-manufactured
    lunarManufacturedRatio(:, 12) = 1;
    
    % IMPORTANT NEW SECTION: Estimate non-replicable components used in each subsystem
    % This will be subtracted from the lunar-manufactured mass
    
    % If we don't have direct tracking, estimate non-replicable consumption based on 
    % subsystem configurations and growth
    if ~hasNonReplicableHistory
        % Get the non-replicable component fractions from subsystem configs
        nonReplicableFractions = zeros(1, length(subsystemNames));
        
        % Extract non-replicable component fractions from configurations
        % Extraction
        if isfield(factory.subConfig, 'extractionLunar') && ...
           isfield(factory.subConfig.extractionLunar, 'nonReplicableComponents')
            % Use lunar-manufactured extraction configuration if available
            nonReplicableFractions(1) = factory.subConfig.extractionLunar.nonReplicableComponents / ...
                                         factory.subConfig.extractionLunar.massPerUnit;
        else
            % Default to 25% non-replicable components for extraction
            nonReplicableFractions(1) = 0.25;
        end
        
        % MRE
        if isfield(factory.subConfig, 'processingMRE') && ...
           isfield(factory.subConfig.processingMRE, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.processingMRE.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.processingMRE.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(2) = nonReplicableFraction;
        else
            % Default to 3.5% non-replicable components for MRE (from documentation)
            nonReplicableFractions(2) = 0.035;
        end
        
        % HCl
        if isfield(factory.subConfig, 'processingHCl') && ...
           isfield(factory.subConfig.processingHCl, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.processingHCl.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.processingHCl.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(3) = nonReplicableFraction;
        else
            % Default to 28% non-replicable components for HCl (from documentation)
            nonReplicableFractions(3) = 0.28;
        end
        
        % VP
        if isfield(factory.subConfig, 'processingVP') && ...
           isfield(factory.subConfig.processingVP, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.processingVP.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.processingVP.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(4) = nonReplicableFraction;
        else
            % Default to 9% non-replicable components for VP (from documentation)
            nonReplicableFractions(4) = 0.09;
        end
        
        % LPBF
        if isfield(factory.subConfig, 'manufacturingLPBF') && ...
           isfield(factory.subConfig.manufacturingLPBF, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.manufacturingLPBF.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.manufacturingLPBF.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(5) = nonReplicableFraction;
        else
            % Default to 24% non-replicable components for LPBF (from documentation)
            nonReplicableFractions(5) = 0.24;
        end
        
        % EBPVD
        if isfield(factory.subConfig, 'manufacturingEBPVD') && ...
           isfield(factory.subConfig.manufacturingEBPVD, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.manufacturingEBPVD.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.manufacturingEBPVD.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(6) = nonReplicableFraction;
        else
            % Default to 29% non-replicable components for EBPVD (from documentation)
            nonReplicableFractions(6) = 0.29;
        end
        
        % SC
        if isfield(factory.subConfig, 'manufacturingSC') && ...
           isfield(factory.subConfig.manufacturingSC, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.manufacturingSC.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.manufacturingSC.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(7) = nonReplicableFraction;
        else
            % Default to 3% non-replicable components for SC (from documentation)
            nonReplicableFractions(7) = 0.03;
        end
        
        % PC
        if isfield(factory.subConfig, 'manufacturingPC') && ...
           isfield(factory.subConfig.manufacturingPC, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.manufacturingPC.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.manufacturingPC.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(8) = nonReplicableFraction;
        else
            % Default to 3% non-replicable components for PC (from documentation)
            nonReplicableFractions(8) = 0.03;
        end
        
        % SSLS
        if isfield(factory.subConfig, 'manufacturingSSLS') && ...
           isfield(factory.subConfig.manufacturingSSLS, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.manufacturingSSLS.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.manufacturingSSLS.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(9) = nonReplicableFraction;
        else
            % Default to 5% non-replicable components for SSLS (from documentation)
            nonReplicableFractions(9) = 0.05;
        end
        
        % Assembly
        if isfield(factory.subConfig, 'assembly') && ...
           isfield(factory.subConfig.assembly, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.assembly.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.assembly.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(10) = nonReplicableFraction;
        else
            % Default to 20% non-replicable components for Assembly (from documentation)
            nonReplicableFractions(10) = 0.2;
        end
        
        % Landed Solar is 100% Earth-sourced, so 0% would be lunar
        nonReplicableFractions(11) = 1.0;
        
        % Lunar Solar - estimate non-replicable components
        if isfield(factory.subConfig, 'powerLunarSolar') && ...
           isfield(factory.subConfig.powerLunarSolar, 'components')
            % Calculate total non-replicable fraction from components
            nonReplicableFraction = 0;
            componentFields = fieldnames(factory.subConfig.powerLunarSolar.components);
            for i = 1:length(componentFields)
                component = factory.subConfig.powerLunarSolar.components.(componentFields{i});
                if isfield(component, 'materials') && ...
                   isfield(component.materials, 'nonReplicable')
                    nonReplicableFraction = nonReplicableFraction + ...
                                           component.massFraction * component.materials.nonReplicable;
                end
            end
            nonReplicableFractions(12) = nonReplicableFraction;
        else
            % Default to 0% non-replicable components for Lunar Solar
            nonReplicableFractions(12) = 0;
        end
        
        % Calculate non-replicable components used for each subsystem based on growth
        fprintf('Estimating non-replicable component usage based on component fractions:\n');
        for subsystem = 1:length(subsystemNames)
            if nonReplicableFractions(subsystem) > 0
                fprintf('  %s: %.1f%% non-replicable content\n', ...
                    subsystemNames{subsystem}, nonReplicableFractions(subsystem)*100);
            end
        end
        
        fprintf('\nCalculating non-replicable materials used in lunar-manufactured components:\n');
        for step = 1:factory.currentTimeStep
            for subsystem = 1:length(subsystemNames)
                % Only consider lunar-manufactured portion (built on the Moon)
                lunarMass = subsystemMasses(step, subsystem) * lunarManufacturedRatio(step, subsystem);
                
                % Calculate non-replicable components used in this lunar-built mass
                nonReplicableUsed(step, subsystem) = lunarMass * nonReplicableFractions(subsystem);
                
                % Debug output for final step
                if step == factory.currentTimeStep && lunarMass > 0
                    fprintf('  %s: %.2f kg lunar-built mass contains %.2f kg non-replicables\n', ...
                        subsystemNames{subsystem}, lunarMass, nonReplicableUsed(step, subsystem));
                end
            end
        end
    else
        % Use directly tracked non-replicable consumption if available
        nonReplicableUsed = nonReplicableHistory;
    end
    
    % IMPORTANT ADJUSTMENT: Modify lunar manufacturing ratio by subtracting non-replicable components
    adjustedLunarManufacturedRatio = zeros(size(lunarManufacturedRatio));
    
    % Debug: Print component fractions for verification
    fprintf('Adjusting lunar manufacturing ratios by subtracting non-replicable components:\n');
    
    for step = 1:factory.currentTimeStep
        for subsystem = 1:length(subsystemNames)
            if subsystemMasses(step, subsystem) > 0
                % Calculate lunar mass based on original ratio
                lunarMass = subsystemMasses(step, subsystem) * lunarManufacturedRatio(step, subsystem);
                
                % Subtract non-replicable components to get truly lunar mass
                trulyLunarMass = max(0, lunarMass - nonReplicableUsed(step, subsystem));
                
                % Calculate adjusted ratio (truly lunar / total)
                adjustedLunarManufacturedRatio(step, subsystem) = trulyLunarMass / subsystemMasses(step, subsystem);
                
                % Debug output for final step
                if step == factory.currentTimeStep && lunarManufacturedRatio(step, subsystem) > 0.01
                    fprintf('  %s: Original %.1f%%, Adjusted %.1f%% (NR: %.1f kg)\n', ...
                        subsystemNames{subsystem}, ...
                        lunarManufacturedRatio(step, subsystem)*100, ...
                        adjustedLunarManufacturedRatio(step, subsystem)*100, ...
                        nonReplicableUsed(step, subsystem));
                end
            end
        end
    end
    
    % Plot lunar manufacturing percentage by subsystem
    subplot(2, 1, 1);
    
    % Plot each subsystem as a line
    hold on;
    colorMap = lines(size(adjustedLunarManufacturedRatio, 2));
    
    legendEntries = {};
    for i = 1:size(adjustedLunarManufacturedRatio, 2)
        % Only plot subsystems that have lunar-manufactured components and valid data
        dataToPlot = adjustedLunarManufacturedRatio(:, i);
        % Check for invalid data (NaN, Inf, or empty)
        hasValidData = ~isempty(dataToPlot) && all(isfinite(dataToPlot)) && any(dataToPlot > 0.01);
        
        if hasValidData && length(timeMonths) == length(dataToPlot)
            plot(timeMonths, dataToPlot * 100, 'LineWidth', 2, 'Color', colorMap(i,:));
            legendEntries{end+1} = subsystemNames{i};
        end
    end
    
    % Add labels and legend
    xlabel('Time (months)', 'FontWeight', 'bold');
    ylabel('True Lunar-Sourced Percentage (%)', 'FontWeight', 'bold');
    title('Percentage of Truly Lunar-Sourced Materials by Subsystem', 'FontWeight', 'bold', 'FontSize', 14);
    
    
    if ~isempty(legendEntries)
        legend(legendEntries, 'Location', 'best', 'FontSize', 10);
    end
    grid on;
    
    % Plot overall lunar manufacturing percentage
    subplot(2, 1, 2);
    
    % Calculate overall lunar manufacturing percentage after non-replicable adjustment
    totalMass = sum(subsystemMasses, 2);
    trulyLunarManufacturedMass = zeros(size(totalMass));
    
    for step = 1:factory.currentTimeStep
        for i = 1:size(subsystemMasses, 2)
            trulyLunarManufacturedMass(step) = trulyLunarManufacturedMass(step) + ...
                                        subsystemMasses(step, i) * adjustedLunarManufacturedRatio(step, i);
        end
    end
    
    overallLunarPercentage = trulyLunarManufacturedMass ./ totalMass * 100;
    
    % Check data validity for area plot and percentage text
    validData = ~isempty(overallLunarPercentage) && all(isfinite(overallLunarPercentage)) && ...
                 length(timeMonths) == length(overallLunarPercentage);
    
    if validData
        % Ensure data is valid (no NaNs or Infs)
        overallLunarPercentage(~isfinite(overallLunarPercentage)) = 0;
        
        % Make sure percentages don't exceed 100%
        overallLunarPercentage = min(overallLunarPercentage, 100);
        
        % Create the area plot
        area(timeMonths, [overallLunarPercentage, 100-overallLunarPercentage], ...
             'FaceColor', 'flat', 'FaceAlpha', 0.6);
        colormap([0.2, 0.6, 0.2; 0.8, 0.8, 0.8]);  % Green for lunar, gray for Earth
        
        % Only add text labels if we have data points
        if length(overallLunarPercentage) > 0
            finalPct = overallLunarPercentage(end);
            
            % Extra safety check for scalar, finite value
            if isscalar(finalPct) && isfinite(finalPct)
                % Only add text if there's space to display it (at least 5%)
                if finalPct >= 5
                    text(timeMonths(end), finalPct/2, [num2str(finalPct, '%.1f') '%'], ...
                         'HorizontalAlignment', 'right', 'FontWeight', 'bold', 'Color', 'white');
                end
                
                % Similar check for Earth percentage
                if (100-finalPct) >= 5
                    text(timeMonths(end), finalPct + (100-finalPct)/2, [num2str(100-finalPct, '%.1f') '%'], ...
                         'HorizontalAlignment', 'right', 'FontWeight', 'bold');
                end
            end
        end
    else
        % Display a message if there's no valid data
        text(0.5, 0.5, 'Insufficient data for visualization', ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'Units', 'normalized');
    end
    
    % Add labels and legend
    xlabel('Time (months)', 'FontWeight', 'bold');
    ylabel('Percentage of Total Factory Mass (%)', 'FontWeight', 'bold');
    title('Overall Percentage of True Lunar-Sourced Components', 'FontWeight', 'bold', 'FontSize', 14);
    legend('Lunar-Sourced', 'Earth-Sourced', 'Location', 'best', 'FontSize', 10);
    grid on;
    
    % Add metrics annotation with safe handling of calculations
    if validData && length(overallLunarPercentage) > 0
        % Safely get initial and final percentages
        initialPct = 0;
        if length(overallLunarPercentage) > 0 && isfinite(overallLunarPercentage(1))
            initialPct = overallLunarPercentage(1);
        end
        
        finalPct = 0;
        if length(overallLunarPercentage) > 0 && isfinite(overallLunarPercentage(end))
            finalPct = overallLunarPercentage(end);
        end
        
        % Safely calculate max growth rate
        maxGrowthRate = 0;
        if length(overallLunarPercentage) > 2
            growthRates = diff(overallLunarPercentage);
            validRates = growthRates(isfinite(growthRates));
            if ~isempty(validRates)
                maxGrowthRate = max(validRates);
            end
        end
        
        % Calculate unadjusted percentage (without non-replicable subtraction)
        % with safety checks
        unadjustedLunarMass = zeros(size(totalMass));
        for step = 1:factory.currentTimeStep
            for i = 1:size(subsystemMasses, 2)
                if isfinite(lunarManufacturedRatio(step, i)) && isfinite(subsystemMasses(step, i))
                    unadjustedLunarMass(step) = unadjustedLunarMass(step) + ...
                                        subsystemMasses(step, i) * lunarManufacturedRatio(step, i);
                end
            end
        end
        
        unadjustedPercentage = zeros(size(totalMass));
        for step = 1:length(totalMass)
            if totalMass(step) > 0 && isfinite(unadjustedLunarMass(step))
                unadjustedPercentage(step) = unadjustedLunarMass(step) / totalMass(step) * 100;
            end
        end
        
        finalUnadjustedPct = 0;
        if ~isempty(unadjustedPercentage) && length(unadjustedPercentage) > 0 && isfinite(unadjustedPercentage(end))
            finalUnadjustedPct = unadjustedPercentage(end);
        end
        
        % Format numbers with safety checks
        initialPctStr = '0.0';
        if isfinite(initialPct)
            initialPctStr = num2str(initialPct, '%.1f');
        end
        
        finalPctStr = '0.0';
        if isfinite(finalPct)
            finalPctStr = num2str(finalPct, '%.1f');
        end
        
        finalUnadjustedPctStr = '0.0';
        if isfinite(finalUnadjustedPct)
            finalUnadjustedPctStr = num2str(finalUnadjustedPct, '%.1f');
        end
        
        diffPctStr = '0.0';
        if isfinite(finalUnadjustedPct) && isfinite(finalPct)
            diffPctStr = num2str(finalUnadjustedPct - finalPct, '%.1f');
        end
        
        maxGrowthRateStr = '0.00';
        if isfinite(maxGrowthRate)
            maxGrowthRateStr = num2str(maxGrowthRate, '%.2f');
        end
        
        % Create annotation
        metricText = {
            'Lunar Manufacturing Metrics:',
            ['Initial: ' initialPctStr '%'],
            ['Final: ' finalPctStr '%'],
            ['Without NR adjustment: ' finalUnadjustedPctStr '%'],
            ['Difference: ' diffPctStr '%'],
            ['Max monthly growth: ' maxGrowthRateStr '%']
        };
        
        % Create annotation with safe position
        try
            annotation('textbox', [0.15, 0.30, 0.3, 0.1], 'String', metricText, ...
                      'FitBoxToText', 'on', 'BackgroundColor', 'white', 'FontSize', 10);
        catch
            % If annotation fails, try a simpler approach
            text(0.15, 0.15, strjoin(metricText, '\n'), 'Units', 'normalized', ...
                 'FontSize', 10, 'BackgroundColor', 'white');
        end
    end
    
    % Set publication-quality formatting
    set(figLunar, 'Color', 'white');
    set(findall(figLunar, '-property', 'FontSize'), 'FontSize', 12);
    set(findall(figLunar, '-property', 'FontName'), 'FontName', 'Garamond');
    
    % Save figure if requested
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'lunar_manufactured_percentage.png');
        print(figLunar, figFilename, '-dpng', '-r300');
        fprintf('Lunar-manufactured percentage visualization saved to %s\n', figFilename);
    end
end

function visualizeIndividualSubsystemMass(factory, timeMonths, options)
    % Create figure for individual subsystem mass evolution
    figIndividualMass = figure('Name', 'Individual Subsystem Mass Evolution', 'Position', [100, 100, 1200, 800]);
    
    % Set figure properties for publication quality
    set(figIndividualMass, 'Color', 'white');
    set(findall(figIndividualMass, '-property', 'FontName'), 'FontName', 'Garamond');
    set(findall(figIndividualMass, '-property', 'FontSize'), 'FontSize', 12);
    
    % Get subsystem names
    subsystemNames = {
        'Extraction', ...
        'Processing (MRE)', ...
        'Processing (HCl)', ...
        'Processing (VP)',...
        'Manufacturing (LPBF)', ...
        'Manufacturing (EBPVD)', ...
        'Manufacturing (SC)', ...
        'Manufacturing (PC)', ...
        'Manufacturing (SSLS)',...
        'Assembly', ...
        'Power (Landed Solar)', ...
        'Power (Lunar Solar)'
    };
    
    % Define the same custom colormap
    customColorMap = [
        0.2, 0.7, 0.2;  % Extraction (green)
        0.1, 0.3, 0.8;  % Processing MRE (blue)
        0.2, 0.4, 0.9;  % Processing HCl (lighter blue)
        0.3, 0.5, 1.0;  % Processing VP (lightest blue)
        0.8, 0.0, 0.0;  % Manufacturing LPBF (dark red)
        0.9, 0.2, 0.2;  % Manufacturing EBPVD (purple)
        1.0, 0.4, 0.4;  % Manufacturing SC (pink)
        0.7, 0.5, 0.5;  % Manufacturing PC (orange/brown)
        0.8, 0.6, 0.6;  % Manufacturing SSLS (orange)
        0.5, 0.5, 0.5;  % Assembly (gray)
        0.9, 0.7, 0.1;  % Power Landed Solar (gold)
        1.0, 0.8, 0.2   % Power Lunar Solar (yellow)
    ];
    
    % Get subsystem masses over time
    massEvolution = factory.metrics.subsystemMasses(1:factory.currentTimeStep, :);
    
    % Create multi-panel plot - divide into 3 groups with 4 subsystems each
    
    % Group 1: Extraction and Processing Systems
    subplot(3, 1, 1);
    hold on;
    
    % Plot each subsystem in the first group
    for i = 1:4 % Extraction and Processing systems
        plot(timeMonths, massEvolution(:, i), 'LineWidth', 2, 'Color', customColorMap(i,:));
    end
    
    title('Extraction and Processing Subsystems', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Garamond');
    xlabel('Time (months)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    ylabel('Mass (kg)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    leg = legend(subsystemNames(1:4), 'Location', 'best', 'FontSize', 10);
    set(leg, 'FontName', 'Garamond');
    grid on;
    set(gca, 'FontName', 'Garamond');
    
    % Group 2: Manufacturing Systems
    subplot(3, 1, 2);
    hold on;
    
    % Plot each subsystem in the second group
    for i = 5:9 % Manufacturing systems
        plot(timeMonths, massEvolution(:, i), 'LineWidth', 2, 'Color', customColorMap(i,:));
    end
    
    title('Manufacturing Subsystems', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Garamond');
    xlabel('Time (months)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    ylabel('Mass (kg)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    leg = legend(subsystemNames(5:9), 'Location', 'best', 'FontSize', 10);
    set(leg, 'FontName', 'Garamond');
    grid on;
    set(gca, 'FontName', 'Garamond');
    
    % Group 3: Assembly and Power Systems
    subplot(3, 1, 3);
    hold on;
    
    % Plot each subsystem in the third group
    for i = 10:12 % Assembly and Power systems
        plot(timeMonths, massEvolution(:, i), 'LineWidth', 2, 'Color', customColorMap(i,:));
    end
    
    title('Assembly and Power Subsystems', 'FontWeight', 'bold', 'FontSize', 14, 'FontName', 'Garamond');
    xlabel('Time (months)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    ylabel('Mass (kg)', 'FontWeight', 'bold', 'FontName', 'Garamond');
    leg = legend(subsystemNames(10:12), 'Location', 'best', 'FontSize', 10);
    set(leg, 'FontName', 'Garamond');
    grid on;
    set(gca, 'FontName', 'Garamond');
    
    % Improve overall figure layout
    set(figIndividualMass, 'PaperPositionMode', 'auto');
    set(figIndividualMass, 'Renderer', 'painters');  % Better for vector output
    
    % Final pass to ensure all text elements use Garamond
    set(findall(figIndividualMass, '-property', 'FontName'), 'FontName', 'Garamond');
    
    % Save figure if requested
    if options.saveToFile
        figFilename = fullfile(options.figuresDir, 'individual_subsystem_mass.png');
        print(figIndividualMass, figFilename, '-dpng', '-r300');  % Higher resolution (300 dpi)
        fprintf('Individual subsystem mass visualization saved to %s\n', figFilename);
    end
end

