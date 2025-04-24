# Lunar Factory Simulation

This GitHub repository contains the MATLAB code for my Princeton Unviersity undergardaute thesis on simulating a self-expanding lunar factory system capable of using lunar regolith o produce various materials and components that can be used to produce new subsystems and expand the factory over time.

## Overview

The simulation models extraction, processing, manufacturing, and assembly operations, along with power generation and economic factors. It allows for both interactive decision-making and automated optimization using a genetic algorithm.

## Main Files

- main.m: Main execution script that allows running the simulation in either interactive or automated mode
- LunarFactory.m: Core class that implements the simulation logic for the self-expanding lunar factory
- optimizeFactoryGrowth.m: Implements the genetic algorithm optimization for automated decision-making
- visualizeFactoryPerformance.m: Creates visualizations of simulation results and factory performance

## Configuration Files

- subsystemConfig.m: Configures all factory subsystems (extraction, processing, manufacturing, etc.)
- simulationConfig.m: Sets simulation parameters (time steps, initial factory setup)
- environmentConfig.m: Defines lunar environmental parameters (sunlight, regolith composition)
- economicConfig.m: Specifies economic parameters (costs, prices, investment)

## Utility Files

- displaySummary.m: Displays summary information about simulation results
- runAutomatedSimulation.m: Handles the automated simulation mode with optimization

## Software Structure

The simulation is built around the LunarFactory class which manages all subsystems:

1. Extraction: Rovers that mine raw regolith
2. Processing: Systems that separate raw materials (MRE, HCl, VP)
3. Manufacturing: Systems that produce components (LPBF, EBPVD, Sand Casting, etc.)
4. Assembly: Robots that assemble components into new systems
5. Power: Solar power generation systems

## Running the Simulation

The simulation can run in two modes:

### Interactive Mode

In interactive mode, you'll be prompted to make decisions at each time step about:
- Power allocation to different subsystems
- Material processing priorities
- Assembly of new subsystems

### Automated Mode

In automated mode, you can configure:
- Optimization weights (expansion, power, self-reliance, revenue, cost)
- Look-ahead steps for the genetic algorithm
- Initial resource allocation strategy (optional)

## Usage Instructions

1. Ensure you have MATLAB installed (R2019b or newer recommended)
2. Clone this repository to your local machine
3. Open MATLAB and navigate to the repository directory
4. Run the main script main.m
5. Choose between interactive or automated mode when prompted

## Output

Both modes generate visualizations showing:
- Factory growth over time
- Power capacity and demand
- Material inventory changes
- Subsystem mass distribution
- Economic performance

Results are saved to directories named interactive_results or automated_results depending on the mode.
