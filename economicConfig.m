function config = economicConfig()
    % ECONOMICCONFIG Returns the economic configuration for the lunar factory
    %   This function initializes economic parameters such as product prices,
    %   transport costs, operating costs, and initial investment.
    
    % Create config structure
    config = struct();
    
    % Transport and operating costs
    config.transportCostPerKg = 2.5e5; % $ per kg
    config.operatingCostsPerYear = 1e7; % $ per year
    config.initialInvestment = 1e9; % $ initial funding
    
    % Product prices
    config.productPrices = struct();
    config.productPrices.oxygen = 6.25e4; % $ per kg (average of 5e5 - 7.5e5)
    config.productPrices.slag = 325; % $ per kg (average of 15000 - 50000)
    config.productPrices.daytimePower = 0.0025; % $ per kWh (example value)
    config.productPrices.nighttimeMultiplier = 25; % nighttime rate is 25x daytime
    config.productPrices.isruComponents = 1e5; % $ per kg
end