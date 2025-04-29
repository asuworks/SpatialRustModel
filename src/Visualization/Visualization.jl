# src/Visualization.jl
module Visualization

using Plots
using DataFrames
using Agents
using ..SpatialRust

export plot_farm_state, plot_shade_distribution, plot_metrics_over_time, plot_rust_progression

"""
    plot_farm_state(model, step)

Plot the current state of the farm, showing coffee plants, shade trees, and rust infection.
"""
function plot_farm_state(model, step)
    # Create a plot showing the current state of the farm
    p = scatter(title="Farm State at Step $step")
    
    # Plot coffee plants
    for agent in allagents(model)
        if typeof(agent) == Coffee
            color = agent.rusted ? :red : :green
            scatter!([agent.pos[1]], [agent.pos[2]], color=color, label="")
        end
    end
    
    return p
end

"""
    plot_shade_distribution(model)

Plot the distribution of shade across the farm.
"""
function plot_shade_distribution(model)
    # Calculate the effective shade map by multiplying the base shade map
    # with the current individual shade intensity.
    effective_shade = model.shade_map .* model.current.ind_shade

    # Create a heatmap of the effective shade distribution
    heatmap(effective_shade,
            title="Effective Shade Distribution (Intensity: $(round(model.current.ind_shade, digits=3)))",
            color=:viridis,
            # Set consistent color limits for better comparison between steps
            # Use the theoretical max shade from parameters if available
            clims=(0, model.mngpars.max_shade),
            colorbar_title="Effective Shade Level")
end

"""
    plot_metrics_over_time(data)

Plot various metrics over time from the simulation data.
"""
function plot_metrics_over_time(data::DataFrame)
    # Plot multiple metrics over time
    p = plot(layout=(3,1), size=(800,600))
    
    plot!(p[1], data.step, data.rust_infection, 
          title="Rust Infection Over Time",
          label="Rust Infection",
          ylabel="Infection Ratio")
          
    plot!(p[2], data.step, data.coffee_yield,
          title="Coffee Yield Over Time",
          label="Yield",
          ylabel="Yield")
          
    plot!(p[3], data.step, data.shade_coverage,
          title="Shade Coverage Over Time",
          label="Shade",
          ylabel="Coverage")
          
    return p
end

"""
    plot_rust_progression(data)

Plot the progression of rust infection over time.
"""
function plot_rust_progression(data::DataFrame)
    # Plot rust progression over time
    plot(data.step, data.rust_infection,
         title="Rust Disease Progression",
         label="Infection Ratio",
         xlabel="Time Steps",
         ylabel="Proportion of Infected Plants")
end

end # module