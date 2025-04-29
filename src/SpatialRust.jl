module SpatialRust

using Agents, DataFrames, Distributions, Random
using Agents.Schedulers # Need this for Schedulers.fastest type
using Random: Xoshiro # Need this for RNG type

using StatsBase: sample, weights
using Statistics
using CSV
using Plots

# Forward declare the step function type if needed, or ensure it's defined/imported before the alias
function step_model! end # Placeholder if step_model! is defined later
using Agents: dummystep # Import dummystep if you use it as the agent_step! type

include("ABM/MainSetup.jl")

# Update the type alias to use StandardABM with the correct parameters
const SpatialRustABM = StandardABM{
    Agents.GridSpaceSingle{2, false}, # S: Space Type
    Coffee,                           # A: Agent Type
    Vector{Coffee},                   # C: Container Type (Must be Vector)
    Tuple{DataType},                  # T: Type of agent_types tuple (Single type Coffee)
    typeof(dummystep),                # G: Agent Step Function Type (Assuming dummystep here)
    typeof(step_model!),              # K: Model Step Function Type
    typeof(Schedulers.fastest),       # F: Scheduler Type
    SpatialRust.Props,                # P: Properties Type
    Xoshiro,                          # R: RNG Type
    # The following fields are implicitly part of StandardABM's definition
    # agents_first::Bool
    # maxid::Base.RefValue{Int64}
    # time::Base.RefValue{Int64}
}
include("ABM/CreateABM.jl")
include("ABM/FarmMap.jl")
include("ABM/ShadeMap.jl")

include("ABM/MainStep.jl")
include("ABM/ShadeSteps.jl")
include("ABM/CoffeeSteps.jl")
include("ABM/RustGrowth.jl")
include("ABM/RustDispersal.jl")
include("ABM/CGrowerSteps.jl")

include("QuickRuns.jl")
include("QuickMetrics.jl")

# Include and export Visualization module
include("Visualization/Visualization.jl")
using .Visualization

export SpatialRustABM
export step_n!
export initialize_model, step!, run_simulation
export CoffeePlant, ShadeTree, RustSpore
export plot_farm_state, plot_rust_progression, plot_shade_distribution, plot_metrics_over_time

end
