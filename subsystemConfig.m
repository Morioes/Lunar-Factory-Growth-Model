function config = subsystemConfig()
    % SUBSYSTEMCONFIG Returns the subsystem configuration for the lunar factory
    %   This function initializes parameters for all subsystems including
    %   extraction, processing, manufacturing, assembly, power and storage.
    
    % Create config structure
    config = struct();
    
    %% 3.1 Extraction
    config.extraction = struct();
    config.extraction.massPerUnit = 30; % kg
    config.extraction.excavationRate = 42; % kg/hr
    config.extraction.energyPerKg = 1.71; % Wh/kg
    config.extraction.replicableComponents = 18; % kg
    config.extraction.nonReplicableComponents = 12; % kg
    config.extraction.TRL = 6;
    
    % Lunar-Produced Extraction Rover
    config.extractionLunar = struct();
    config.extractionLunar.massPerUnit = 36; % kg - Updated to match documentation
    config.extractionLunar.excavationRate = 30; % kg/hr
    config.extractionLunar.energyPerKg = 2.5; % Wh/kg
    config.extractionLunar.replicableComponents = struct('castAluminum', 18, 'precisionAluminum', 4, 'precisionIron', 3, 'precisionAlumina', 1);
    config.extractionLunar.nonReplicableComponents = 9; % kg
    
    %% 3.2 Processing
    % 3.2.1 Molten Regolith Electrolysis (MRE)
    config.processingMRE = struct();
    config.processingMRE.dutyCycle = 0.5; % ratio
    config.processingMRE.oxygenPerYear = 3*10^4; % kg
    config.processingMRE.oxygenPerYearPerUnit = 10^4; % kg/year/unit
    config.processingMRE.massFormula = '1.492 * (N/(2*t))^0.608'; % Formula for mass
    config.processingMRE.powerFormula = '264 * (N/(2*t))^0.577'; % Formula for power
    config.processingMRE.TRL = 5;
    
    % Output Ratios for MRE - Updated to match documentation
    config.processingMRE.outputRatios = struct();
    config.processingMRE.outputRatios.iron = 0.107; % kg iron per kg oxygen
    config.processingMRE.outputRatios.silicon = 0.460; % kg silicon per kg oxygen
    config.processingMRE.outputRatios.aluminum = 0.205; % kg aluminum per kg oxygen
    config.processingMRE.outputRatios.slag = 0.600; % kg slag per kg oxygen
    
    % Components for MRE - Updated to match documentation
    config.processingMRE.components = struct();
    config.processingMRE.components.structure = struct('massFraction', 0.45, 'materials', struct('castIron', 1.0));
    config.processingMRE.components.refractory = struct('massFraction', 0.145, 'materials', struct('sinteredAlumina', 1.0));
    config.processingMRE.components.anode = struct('massFraction', 0.01, 'materials', struct('nonReplicable', 1.0));
    config.processingMRE.components.cathode = struct('massFraction', 0.005, 'materials', struct('nonReplicable', 1.0));
    config.processingMRE.components.insulation = struct('massFraction', 0.37, 'materials', struct('silicaGlass', 1.0));
    config.processingMRE.components.electronics = struct('massFraction', 0.02, 'materials', struct('nonReplicable', 1.0));
    
    % 3.2.2 HCl Acid Treatment - Updated to match documentation
    config.processingHCl = struct();
    config.processingHCl.massScalingFactorHCl = 928; % kg/(kg/hr) - Updated to match documentation 
    config.processingHCl.powerScalingFactor = 2.8e5; % W/(kg/hr) - Updated to match documentation
    config.processingHCl.reagentConsumptionRate = 1e-4; % kg/kg
    config.processingHCl.TRL = 3;
    
    % Output Ratios for HCl - Updated to match documentation
    config.processingHCl.outputRatios = struct();
    config.processingHCl.outputRatios.silica = 0.409; % kg silica per kg regolith
    config.processingHCl.outputRatios.alumina = 0.211; % kg alumina per kg regolith
    
    % Components for HCl - Updated to match documentation
    config.processingHCl.components = struct();
    config.processingHCl.components.beneficiation = struct('massFraction', 0.08, 'materials', struct('castIron', 0.4, 'precisionIron', 0.25, 'precisionAluminum', 0.25, 'precisionAlumina', 0.1));
    config.processingHCl.components.leaching = struct('massFraction', 0.09, 'materials', struct('silicaGlass', 1.0));
    config.processingHCl.components.centrifuge = struct('massFraction', 0.19, 'materials', struct('castIron', 0.4, 'precisionIron', 0.25, 'precisionAluminum', 0.25, 'precisionAlumina', 0.1));
    config.processingHCl.components.calcination = struct('massFraction', 0.18, 'materials', struct('castIron', 0.25, 'sinteredAlumina', 0.25, 'silicaGlass', 0.25, 'precisionAluminum', 0.25));
    config.processingHCl.components.fluidHandling = struct('massFraction', 0.18, 'materials', struct('castIron', 0.2, 'sinteredAlumina', 0.2, 'silicaGlass', 0.2, 'precisionAluminum', 0.2, 'nonReplicable', 0.2));
    config.processingHCl.components.reagent = struct('massFraction', 0.10, 'materials', struct('nonReplicable', 1.0));
    config.processingHCl.components.water = struct('massFraction', 0.18, 'materials', struct('nonReplicable', 1.0));
    
    % 3.2.3 Vacuum Pyrolysis - Updated to match documentation
    config.processingVP = struct();
    config.processingVP.massScalingFactor = 276; % kg/(kg/hr) - Updated to match documentation
    config.processingVP.powerScalingFactor = 281; % W/(kg/hr) - Updated to match documentation
    config.processingVP.TRL = 3;
    
    % Output Ratios for VP - Updated to match documentation
    config.processingVP.outputRatios = struct();
    config.processingVP.outputRatios.oxygen = 0.14; % kg oxygen per kg regolith
    config.processingVP.outputRatios.silicon = 0.006; % kg silicon per kg regolith
    config.processingVP.outputRatios.aluminum = 0.029; % kg aluminum per kg regolith
    config.processingVP.outputRatios.iron = 0.015; % kg iron per kg regolith
    config.processingVP.outputRatios.slag = 0.81; % kg slag per kg regolith
    
    % Components for VP - Updated to match documentation
    config.processingVP.components = struct();
    config.processingVP.components.crucible = struct('massFraction', 0.2, 'materials', struct('sinteredAlumina', 1.0));
    config.processingVP.components.fresnelLens = struct('massFraction', 0.1, 'materials', struct('silicaGlass', 0.3, 'precisionIron', 0.4, 'precisionAluminum', 0.2, 'precisionAlumina', 0.1));
    config.processingVP.components.vacuumPump = struct('massFraction', 0.1, 'materials', struct('precisionIron', 0.45, 'precisionAluminum', 0.23, 'precisionAlumina', 0.1, 'nonReplicable', 0.22));
    config.processingVP.components.condenser = struct('massFraction', 0.25, 'materials', struct('precisionIron', 0.5, 'precisionAluminum', 0.5));
    config.processingVP.components.structure = struct('massFraction', 0.35, 'materials', struct('castIron', 1.0));
    
    %% 3.3 Manufacturing
    % 3.3.1 Laser Powder Bed Fusion (L-PBF) - Updated to match documentation
    config.manufacturingLPBF = struct();
    config.manufacturingLPBF.massPerUnit = 1300; % kg - Earth manufactured
    config.manufacturingLPBF.massPerUnitLunar = 1950; % kg - Lunar manufactured
    config.manufacturingLPBF.powerPerUnit = 5500; % W - Updated to match documentation
    config.manufacturingLPBF.TRL = 4;
    
    % Input/Output Materials for L-PBF - Updated to match documentation
    config.manufacturingLPBF.inputRates = struct();
    config.manufacturingLPBF.inputRates.aluminum = 0.23; % kg/hr
    config.manufacturingLPBF.inputRates.iron = 0.68; % kg/hr
    config.manufacturingLPBF.inputRates.alumina = 0.34; % kg/hr
    
    config.manufacturingLPBF.outputMapping = struct();
    config.manufacturingLPBF.outputMapping.aluminum = 'precisionAluminum';
    config.manufacturingLPBF.outputMapping.iron = 'precisionIron';
    config.manufacturingLPBF.outputMapping.alumina = 'precisionAlumina';
    
    % Components for L-PBF - Updated to match documentation
    config.manufacturingLPBF.components = struct();
    config.manufacturingLPBF.components.laserSystem = struct('massFraction', 0.19, 'materials', struct('nonReplicable', 1.0));
    config.manufacturingLPBF.components.buildPlatform = struct('massFraction', 0.19, 'materials', struct('castIron', 0.6, 'precisionIron', 0.15, 'precisionAluminum', 0.15, 'precisionAlumina', 0.1));
    config.manufacturingLPBF.components.powderStorage = struct('massFraction', 0.19, 'materials', struct('castIron', 0.6, 'precisionIron', 0.15, 'precisionAluminum', 0.15, 'precisionAlumina', 0.1));
    config.manufacturingLPBF.components.recoatingMechanism = struct('massFraction', 0.19, 'materials', struct('castIron', 0.6, 'precisionIron', 0.15, 'precisionAluminum', 0.15, 'precisionAlumina', 0.1));
    config.manufacturingLPBF.components.structures = struct('massFraction', 0.19, 'materials', struct('castAluminum', 1.0));
    config.manufacturingLPBF.components.controlElectronics = struct('massFraction', 0.05, 'materials', struct('nonReplicable', 1.0));
    
    % 3.3.2 Sand Casting - Added from documentation
    config.manufacturingSC = struct();
    config.manufacturingSC.massScalingFactor = 33.3; % kg/(kg/hr)
    config.manufacturingSC.powerScalingFactor = 43.1; % W/(kg/hr)
    config.manufacturingSC.TRL = 4;
    
    % Components for Sand Casting - Added from documentation
    config.manufacturingSC.components = struct();
    config.manufacturingSC.components.flask = struct('massFraction', 0.06, 'materials', struct('castIron', 1.0));
    config.manufacturingSC.components.pattern = struct('massFraction', 0.07, 'materials', struct('precisionAluminum', 1.0));
    config.manufacturingSC.components.sandManagement = struct('massFraction', 0.07, 'materials', struct('castAluminum', 0.6, 'precisionIron', 0.15, 'precisionAluminum', 0.15, 'precisionAlumina', 0.1));
    config.manufacturingSC.components.sand = struct('massFraction', 0.77, 'materials', struct('regolith', 1.0));
    config.manufacturingSC.components.controlElectronics = struct('massFraction', 0.03, 'materials', struct('nonReplicable', 1.0));
    
    % Input/Output Materials for Sand Casting
    config.manufacturingSC.outputMapping = struct();
    config.manufacturingSC.outputMapping.aluminum = 'castAluminum';
    config.manufacturingSC.outputMapping.iron = 'castIron';
    config.manufacturingSC.outputMapping.slag = 'castSlag';
    
    % 3.3.3 Permanent Casting - Updated to match documentation
    config.manufacturingPC = struct();
    config.manufacturingPC.massScalingFactor = 10; % kg/(kg/hr)
    config.manufacturingPC.powerScalingFactor = 43.1; % W/(kg/hr) 
    config.manufacturingPC.castingRate = 5; % kg/hr
    config.manufacturingPC.TRL = 3;
    
    % Input/Output Materials for PC - REMOVED IRON
    config.manufacturingPC.outputMapping = struct();
    config.manufacturingPC.outputMapping.aluminum = 'castAluminum';
    config.manufacturingPC.outputMapping.slag = 'castSlag';
    
    % Components for PC 
    config.manufacturingPC.components = struct();
    config.manufacturingPC.components.alignmentSystem = struct('massFraction', 0.15, 'materials', struct('castIron', 0.6, 'precisionIron', 0.15, 'precisionAluminum', 0.15, 'precisionAlumina', 0.1));
    config.manufacturingPC.components.clamps = struct('massFraction', 0.15, 'materials', struct('castIron', 1.0));
    config.manufacturingPC.components.furnace = struct('massFraction', 0.1, 'materials', struct('sinteredAlumina', 0.7, 'silicaGlass', 0.3));
    config.manufacturingPC.components.moldMaterial = struct('massFraction', 0.57, 'materials', struct('sinteredRegolith', 1.0));
    config.manufacturingPC.components.controlElectronics = struct('massFraction', 0.03, 'materials', struct('nonReplicable', 1.0));

    % 3.3.4 Vacuum Deposition
    config.manufacturingEBPVD = struct();
    config.manufacturingEBPVD.massScalingFactorEarth = 13400; % kg/(kg/hr) - Earth manufactured
    config.manufacturingEBPVD.massScalingFactorLunar = 20100; % kg/(kg/hr) - Lunar manufactured
    config.manufacturingEBPVD.powerScalingFactor = 2.7e4; % W/(kg/hr) 
    
    % Solar thin film parameters - Updated to match documentation
    config.manufacturingEBPVD.aluminumThickness = 1.52e-6; % m
    config.manufacturingEBPVD.aluminumThicknessFraction = 0.23;
    config.manufacturingEBPVD.aluminumMassPerArea = 0.0041; % kg/m²
    config.manufacturingEBPVD.aluminumDepositionRate = 1.45e-8; % kg/m²s
    
    config.manufacturingEBPVD.siliconThickness = 5.7e-6; % m
    config.manufacturingEBPVD.siliconThicknessFraction = 0.74;
    config.manufacturingEBPVD.siliconMassPerArea = 0.0133; % kg/m²
    config.manufacturingEBPVD.siliconDepositionRate = 1.31e-8; % kg/m²s
    
    config.manufacturingEBPVD.silicaThickness = 0.15e-6; % m
    config.manufacturingEBPVD.silicaThicknessFraction = 0.022;
    config.manufacturingEBPVD.silicaMassPerArea = 0.0004; % kg/m²
    config.manufacturingEBPVD.silicaDepositionRate = 1.71e-8; % kg/m²s
    
    % Input/Output Materials for EBPVD
    config.manufacturingEBPVD.inputRatio = struct('aluminum', 0.0041, 'silicon', 0.0133, 'silica', 0.022);
    config.manufacturingEBPVD.outputMapping = struct('input', 'aluminum,silicon,silica', 'output', 'solarThinFilm');
    
    % Components for EBPVD
    config.manufacturingEBPVD.components = struct();
    config.manufacturingEBPVD.components.substrateHolder = struct('massFraction', 0.24, 'materials', struct('precisionAluminum', 0.45, 'precisionIron', 0.45, 'precisionAlumina', 0.1));
    config.manufacturingEBPVD.components.heatingElement = struct('massFraction', 0.23, 'materials', struct('nonReplicable', 1.0));
    config.manufacturingEBPVD.components.evaporationBoats = struct('massFraction', 0.24, 'materials', struct('nonReplicable', 1.0));
    config.manufacturingEBPVD.components.structure = struct('massFraction', 0.23, 'materials', struct('castAluminum', 1.0));
    config.manufacturingEBPVD.components.controlElectronics = struct('massFraction', 0.05, 'materials', struct('nonReplicable', 1.0));
    
    % 3.3.5 Regolith Sintering (SSLS)
    config.manufacturingSSLS = struct();
    config.manufacturingSSLS.massScalingFactorEarth = 22.9; % kg/(kg/hr) - Earth manufactured
    config.manufacturingSSLS.massScalingFactorLunar = 34.4; % kg/(kg/hr) - Lunar manufactured
    config.manufacturingSSLS.powerScalingFactor = 86.2; % W/(kg/hr)
    config.manufacturingSSLS.massProdRateSSLS = 100.8; % kg/hr
    
    % Input/Output Materials for SSLS
    config.manufacturingSSLS.outputMapping = struct();
    config.manufacturingSSLS.outputMapping.silica = 'silicaGlass';
    config.manufacturingSSLS.outputMapping.alumina = 'sinteredAlumina';
    config.manufacturingSSLS.outputMapping.regolith = 'sinteredRegolith';
    
    % Components for SSLS - Updated to match documentation
    config.manufacturingSSLS.components = struct();
    config.manufacturingSSLS.components.solarConcentrator = struct('massFraction', 0.1, 'materials', struct('silicaGlass', 1.0));
    config.manufacturingSSLS.components.actuationMount = struct('massFraction', 0.21, 'materials', struct('precisionAluminum', 0.45, 'precisionIron', 0.45, 'precisionAlumina', 0.1));
    config.manufacturingSSLS.components.roller = struct('massFraction', 0.21, 'materials', struct('castIron', 0.6, 'precisionIron', 0.15, 'precisionAluminum', 0.15, 'precisionAlumina', 0.1));
    config.manufacturingSSLS.components.feedstockTank = struct('massFraction', 0.21, 'materials', struct('castAluminum', 1.0));
    config.manufacturingSSLS.components.holderStructure = struct('massFraction', 0.22, 'materials', struct('castIron', 1.0));
    config.manufacturingSSLS.components.controlElectronics = struct('massFraction', 0.05, 'materials', struct('nonReplicable', 1.0));
    
    %% 3.4 Assembly - Updated to match documentation
    config.assembly = struct();
    config.assembly.massScalingFactorEarth = 0.94; % kg/(kg/hr) - Earth manufactured
    config.assembly.massScalingFactorLunar = 1.41; % kg/(kg/hr) - Lunar manufactured
    config.assembly.powerScalingFactorEarth = 3.96; % W/(kg/hr) - Earth manufactured
    config.assembly.powerScalingFactorLunar = 5.94; % W/(kg/hr) - Lunar manufactured
    config.assembly.massPerUnit = 1130; % kg
    config.assembly.powerPerUnit = 5000; % W
    config.assembly.payloadCapacity = 1260; % kg
    config.assembly.assemblyRate = 90; % deg/sec
    config.assembly.assemblyCapacity = 1260; % kg/hr
    
    % Components for Assembly - Updated to match documentation
    config.assembly.components = struct();
    config.assembly.components.structure = struct('massFraction', 0.27, 'materials', struct('castAluminum', 1.0));
    config.assembly.components.actuators = struct('massFraction', 0.27, 'materials', struct('precisionAluminum', 0.45, 'precisionIron', 0.45, 'precisionAlumina', 0.1));
    config.assembly.components.endEffectors = struct('massFraction', 0.26, 'materials', struct('precisionAluminum', 0.35, 'precisionIron', 0.35, 'precisionAlumina', 0.1, 'nonReplicable', 0.2));
    config.assembly.components.controlSensors = struct('massFraction', 0.20, 'materials', struct('nonReplicable', 1.0));
    
    %% 3.5 Power Generation
    % 3.5.1 Landed Solar 
    config.powerLandedSolar = struct();
    config.powerLandedSolar.powerScaling = 110; % W/(kg/hr)
    config.powerLandedSolar.massPerW = 1/110; % kg/W
    config.powerLandedSolar.TRL = 9;
    
    % 3.5.2 Solar Production (Lunar-made) 
    config.powerLunarSolar = struct();
    config.powerLunarSolar.massPerArea = 15.43; % kg/m^2
    config.powerLunarSolar.efficiency = 0.05; % ratio (5% efficiency)
    config.powerLunarSolar.TRL = 3;
    
    % Components for Solar Production 
    config.powerLunarSolar.components = struct();
    config.powerLunarSolar.components.thinFilm = struct('massFraction', 0.00115, 'materials', struct('solarThinFilm', 1.0));
    config.powerLunarSolar.components.superstrate = struct('massFraction', 0.499, 'materials', struct('silicaGlass', 1.0));
    config.powerLunarSolar.components.structure = struct('massFraction', 0.450, 'materials', struct('castAluminum', 1.0));
    config.powerLunarSolar.components.solarArrayDriveAssembly = struct('massFraction', 0.05, 'materials', struct('precisionAluminum', 0.45, 'precisionIron', 0.45, 'precisionAlumina', 0.1));
    
    %% 4. Material Flow Definitions
    % Define material flow structures for all the flows listed in section 4
    config.materialFlows = struct();
    
    % 4.1 castAluminum Flow 
    config.materialFlows.castAluminum = struct();
    config.materialFlows.castAluminum.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'MRE', 'output', 'aluminum', 'ratio', 0.086),...
        struct('input', 'regolith', 'process', 'Vacuum Pyrolysis', 'output', 'aluminum', 'ratio', 0.029),...
        struct('input', 'aluminum', 'process', 'Permanent Casting', 'output', 'castAluminum', 'ratio', 0.95),...
        struct('input', 'castAluminum', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)...
    };
    
    % 4.2 castIron Flow 
    config.materialFlows.castIron = struct();
    config.materialFlows.castIron.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'MRE', 'output', 'iron', 'ratio', 0.045),...
        struct('input', 'regolith', 'process', 'Vacuum Pyrolysis', 'output', 'iron', 'ratio', 0.015),...
        struct('input', 'iron', 'process', 'Permanent Casting', 'output', 'castIron', 'ratio', 0.95),...
        struct('input', 'castIron', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
    
    % 4.3 precisionAluminum Flow
    config.materialFlows.precisionAluminum = struct();
    config.materialFlows.precisionAluminum.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'MRE', 'output', 'aluminum', 'ratio', 0.086),...
        struct('input', 'regolith', 'process', 'Vacuum Pyrolysis', 'output', 'aluminum', 'ratio', 0.029),...
        struct('input', 'aluminum', 'process', 'L-PBF', 'output', 'precisionAluminum', 'ratio', 0.98),...
        struct('input', 'precisionAluminum', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
    
    % 4.4 precisionIron Flow 
    config.materialFlows.precisionIron = struct();
    config.materialFlows.precisionIron.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'MRE', 'output', 'iron', 'ratio', 0.045),...
        struct('input', 'regolith', 'process', 'Vacuum Pyrolysis', 'output', 'iron', 'ratio', 0.015),...
        struct('input', 'iron', 'process', 'L-PBF', 'output', 'precisionIron', 'ratio', 0.98),...
        struct('input', 'precisionIron', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
    
    % 4.5 precisionAlumina Flow
    config.materialFlows.precisionAlumina = struct();
    config.materialFlows.precisionAlumina.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'HCl Acid Treatment', 'output', 'alumina', 'ratio', 0.211),...
        struct('input', 'alumina', 'process', 'L-PBF', 'output', 'precisionAlumina', 'ratio', 0.98),...
        struct('input', 'precisionAlumina', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
    
    % 4.6 sinteredAlumina Flow
    config.materialFlows.sinteredAlumina = struct();
    config.materialFlows.sinteredAlumina.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'HCl Acid Treatment', 'output', 'alumina', 'ratio', 0.211),...
        struct('input', 'alumina', 'process', 'Regolith Sintering', 'output', 'sinteredAlumina', 'ratio', 0.95),...
        struct('input', 'sinteredAlumina', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
    
    % 4.7 silicaGlass Flow 
    config.materialFlows.silicaGlass = struct();
    config.materialFlows.silicaGlass.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'HCl Acid Treatment', 'output', 'silica', 'ratio', 0.409),...
        struct('input', 'silica', 'process', 'Regolith Sintering', 'output', 'silicaGlass', 'ratio', 0.95),...
        struct('input', 'silicaGlass', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
    
    % 4.8 sinteredRegolith Flow
    config.materialFlows.sinteredRegolith = struct();
    config.materialFlows.sinteredRegolith.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'Regolith Sintering', 'output', 'sinteredRegolith', 'ratio', 0.95),...
        struct('input', 'sinteredRegolith', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
    
    % 4.9 solarThinFilm Flow
    config.materialFlows.solarThinFilm = struct();
    config.materialFlows.solarThinFilm.steps = {
        struct('input', 'raw regolith', 'process', 'Extraction', 'output', 'regolith', 'ratio', 1.0),...
        struct('input', 'regolith', 'process', 'MRE', 'output', 'silicon', 'ratio', 0.194),...
        struct('input', 'regolith', 'process', 'MRE', 'output', 'aluminum', 'ratio', 0.086),...
        struct('input', 'regolith', 'process', 'Vacuum Pyrolysis', 'output', 'silicon', 'ratio', 0.006),...
        struct('input', 'regolith', 'process', 'Vacuum Pyrolysis', 'output', 'aluminum', 'ratio', 0.029),...
        struct('input', 'regolith', 'process', 'HCl Acid Treatment', 'output', 'silica', 'ratio', 0.409),...
        struct('input', 'aluminum + silicon + silica', 'process', 'Thermal Vacuum Deposition', 'output', 'solarThinFilms', 'ratio', 0.97),...
        struct('input', 'solarThinFilms', 'process', 'Assembly', 'output', 'Final Product', 'ratio', 1.0)
    };
end