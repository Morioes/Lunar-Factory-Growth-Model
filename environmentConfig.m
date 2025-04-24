function config = environmentConfig()
    % ENVIRONMENTCONFIG Returns the environmental configuration for the lunar factory
    %   This function initializes environmental parameters such as location,
    %   sunlight, regolith composition, and other lunar surface conditions.
    
    % Create config structure
    config = struct();
    
    % Location parameters
    config.location = 'LunarSouthPole';
    config.sunlightFraction = 0.5; % Fraction of time with sunlight
    
    % Regolith properties
    config.regolithDensity = 1500; % kg/m^3
    
    % Solar illumination
    config.solarIllumination = 1361; % W/m^2
    
    % Regolith composition by element
    config.regolithComposition.elements.oxygen = 0.446;
    config.regolithComposition.elements.silicon = 0.21;
    config.regolithComposition.elements.aluminum = 0.133;
    config.regolithComposition.elements.iron = 0.049;
    config.regolithComposition.elements.calcium = 0.1070;
    config.regolithComposition.elements.other = 0.0551;
    
    % Regolith composition by oxide
    config.regolithComposition.oxides.silica = 0.449;
    config.regolithComposition.oxides.alumina = 0.251;
end