function displaySummary(factory, options)
% DISPLAYSUMMARY Displays a summary of the lunar factory simulation
%   This function presents key metrics, subsystem information, and
%   economic performance of the lunar factory simulation.
%
%   Inputs:
%       factory - LunarFactory object containing simulation results
%       options - Structure with display options (optional)
%           .saveToFile - Boolean indicating whether to save results to file
%           .filename - Custom filename for saved results (optional)

% Handle optional inputs
if nargin < 2
    options = struct();
end
if ~isfield(options, 'saveToFile')
    options.saveToFile = false;
end
if ~isfield(options, 'filename') && options.saveToFile
    options.filename = 'lunar_factory_summary.txt';
end

% Open file for saving if requested
if options.saveToFile
    fid = fopen(options.filename, 'w');
    if fid == -1
        warning('Could not open file for writing. Results will not be saved.');
        options.saveToFile = false;
        fid = 1; % Use standard output
    end
else
    fid = 1; % Use standard output (display to command window)
end

% Display header
fprintf(fid, '====================================================\n');
fprintf(fid, '           LUNAR FACTORY SIMULATION SUMMARY         \n');
fprintf(fid, '====================================================\n\n');

% Display simulation parameters
fprintf(fid, 'Simulation Parameters:\n');
fprintf(fid, '  Time step size: %d hours\n', factory.simConfig.timeStepSize);
fprintf(fid, '  Number of time steps: %d\n', factory.simConfig.numTimeSteps);
fprintf(fid, '  Initial landed mass: %.2f kg\n', factory.simConfig.initialLandedMass);
fprintf(fid, '  Resupply rate: %.2f kg/year\n\n', factory.simConfig.resupplyRate);

% Display final state
fprintf(fid, 'Final Factory State:\n');
fprintf(fid, '  Total mass: %.2f kg\n', factory.totalMass);
fprintf(fid, '  Power capacity: %.2f W\n', factory.powerCapacity);
fprintf(fid, '  Power demand: %.2f W\n', factory.powerDemand);
fprintf(fid, '  Power utilization: %.1f%%\n\n', (factory.powerDemand / factory.powerCapacity) * 100);

% Display growth metrics
lastStep = factory.currentTimeStep;
if lastStep > 0
    fprintf(fid, 'Growth Metrics:\n');
    if lastStep > 1
        fprintf(fid, '  Final monthly growth rate: %.2f%%\n', factory.metrics.monthlyGrowthRate(lastStep) * 100);
        fprintf(fid, '  Final annual growth rate: %.2f%%\n', factory.metrics.annualGrowthRate(lastStep) * 100);
    end
    fprintf(fid, '  Final replication factor: %.2f\n\n', factory.metrics.replicationFactor(lastStep));
end

% Display economic metrics
if lastStep > 0
    fprintf(fid, 'Economic Performance:\n');
    fprintf(fid, '  Total revenue: $%.2f\n', sum(factory.economics.revenue(1:lastStep)));
    fprintf(fid, '  Total costs: $%.2f\n', sum(factory.economics.costs(1:lastStep)));
    fprintf(fid, '  Cumulative profit: $%.2f\n', factory.economics.cumulativeProfit(lastStep));
    fprintf(fid, '  Return on Investment: %.2f%%\n\n', factory.economics.ROI(lastStep) * 100);
end

% Display subsystem breakdown
fprintf(fid, 'Subsystem Mass Breakdown:\n');

% Get subsystem masses and names
subsystemMasses = [
    factory.extraction.mass,...
    factory.processingMRE.mass,...
    factory.processingHCl.mass,...
    factory.processingVP.mass,...
    factory.manufacturingLPBF.mass,...
    factory.manufacturingEBPVD.mass,...
    factory.manufacturingSC.mass,... % Added Sand Casting
    factory.manufacturingPC.mass,...
    factory.manufacturingSSLS.mass,...
    factory.assembly.mass,...
    factory.powerLandedSolar.mass,...
    factory.powerLunarSolar.mass,...
];

subsystemNames = {
    'Extraction', ...
    'Processing (MRE)', ...
    'Processing (HCl)', ...
    'Processing (VP)',...
    'Manufacturing (LPBF)', ...
    'Manufacturing (EBPVD)', ...
    'Manufacturing (SC)', ... % Added Sand Casting
    'Manufacturing (PC)', ...
    'Manufacturing (SSLS)',...
    'Assembly', ...
    'Power (Landed Solar)', ...
    'Power (Lunar Solar)'
};

% Sort subsystems by mass (descending)
[sortedMasses, sortIndices] = sort(subsystemMasses, 'descend');
sortedNames = subsystemNames(sortIndices);

% Display subsystem masses
totalMass = sum(subsystemMasses);
for i = 1:length(sortedMasses)
    if sortedMasses(i) > 0
        percentage = (sortedMasses(i) / totalMass) * 100;
        fprintf(fid, '  %s: %.2f kg (%.1f%%)\n', sortedNames{i}, sortedMasses(i), percentage);
    end
end
fprintf(fid, '\n');

% Display key inventory levels
fprintf(fid, 'Key Material Inventory:\n');
inventoryFields = fieldnames(factory.inventory);
for i = 1:length(inventoryFields)
    field = inventoryFields{i};
    if factory.inventory.(field) > 0
        fprintf(fid, '  %s: %.2f kg\n', field, factory.inventory.(field));
    end
end
fprintf(fid, '\n');

% Create performance plots if running in non-batch mode
if ~isdeployed && usejava('desktop')
    % Create time vector (in months)
    timeMonths = (1:factory.currentTimeStep) * (factory.simConfig.timeStepSize / 720);
    
    % Plot 1: Total Mass Growth
    figure('Name', 'Lunar Factory Performance', 'Position', [100, 100, 1200, 800]);
    
    subplot(2, 2, 1);
    plot(timeMonths, factory.metrics.totalMass(1:factory.currentTimeStep), 'b-', 'LineWidth', 2);
    title('Total Factory Mass');
    xlabel('Time (months)');
    ylabel('Mass (kg)');
    grid on;
    
    % Plot 2: Power Capacity and Demand
    subplot(2, 2, 2);
    plot(timeMonths, factory.metrics.powerCapacity(1:factory.currentTimeStep), 'b-', 'LineWidth', 2);
    hold on;
    plot(timeMonths, factory.metrics.powerDemand(1:factory.currentTimeStep), 'r--', 'LineWidth', 2);
    title('Power Capacity and Demand');
    xlabel('Time (months)');
    ylabel('Power (W)');
    legend('Capacity', 'Demand', 'Location', 'northwest');
    grid on;
    
    % Plot 3: Subsystem Mass Evolution
    subplot(2, 2, 3);
    
    % Get mass evolution for each subsystem
    massEvolution = factory.metrics.subsystemMasses(1:factory.currentTimeStep, :);
    
    % Plot stacked area
    area(timeMonths, massEvolution);
    title('Subsystem Mass Evolution');
    xlabel('Time (months)');
    ylabel('Mass (kg)');
    legend(subsystemNames, 'Location', 'northwest', 'FontSize', 8);
    grid on;
    
    % Plot 4: Economic Performance
    subplot(2, 2, 4);
    plot(timeMonths, factory.economics.revenue(1:factory.currentTimeStep), 'g-', 'LineWidth', 2);
    hold on;
    plot(timeMonths, factory.economics.costs(1:factory.currentTimeStep), 'r-', 'LineWidth', 2);
    plot(timeMonths, factory.economics.cumulativeProfit(1:factory.currentTimeStep), 'b-', 'LineWidth', 2);
    title('Economic Performance');
    xlabel('Time (months)');
    ylabel('Amount ($)');
    legend('Revenue', 'Costs', 'Cumulative Profit', 'Location', 'northwest');
    grid on;
    
    % Adjust layout
    set(gcf, 'PaperPositionMode', 'auto');
    set(gcf, 'Renderer', 'painters');
    
    % Save figure if requested
    if options.saveToFile
        figFilename = [options.filename(1:end-4), '.png'];
        saveas(gcf, figFilename);
        fprintf(fid, 'Performance plots saved to %s\n\n', figFilename);
    end
end

% Display footer
fprintf(fid, '====================================================\n');
fprintf(fid, '                    END OF SUMMARY                  \n');
fprintf(fid, '====================================================\n');

% Close file if it was opened
if options.saveToFile && fid ~= 1
    fclose(fid);
    fprintf('Summary saved to %s\n', options.filename);
end
end