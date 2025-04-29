using SpatialRust
using Plots
using DataFrames
using Statistics # Need this for mean
using Agents

# Load the model with default parameters
model = init_spatialrust(
    seed = 42,              # Random seed for reproducibility
    steps = 100,            # Total simulation steps intended (used for weather generation, etc.)
    p_rusts = 0.01,         # Initial rust infection probability
    rain_prob = 0.8,        # Probability of rain
    wind_prob = 0.7,        # Probability of wind
    mean_temp = 22.0        # Mean temperature
)

# Create a directory for visualizations
if !isdir("visualizations")
    mkdir("visualizations")
end

# Plot initial state
p1 = plot_farm_state(model, 0)
savefig(p1, "visualizations/initial_state.png")

# Plot shade distribution
p2 = plot_shade_distribution(model)
savefig(p2, "visualizations/shade_distribution.png")

# Run simulation and collect data
data = DataFrame(step=Int[], rust_infection=Float64[], coffee_yield=Float64[], shade_coverage=Float64[])

# --- Define the number of steps per loop iteration ---
steps_per_iteration = 1
# ----------------------------------------------------

for step in 1:100
    step_n!(model, steps_per_iteration)

    # Collect metrics (Ensure Coffee type exists if model is empty initially)
    current_agents = collect(allagents(model)) # Collect agents once per step
    coffee_agents = filter(a -> typeof(a) == Coffee, current_agents)

    # Handle cases where there might be no coffee agents (e.g., early simulation or extinction)
    rust_inf = isempty(coffee_agents) ? 0.0 : mean([a.rusted for a in coffee_agents])
    coffee_yld = isempty(coffee_agents) ? 0.0 : sum([a.production for a in coffee_agents])

    push!(data, (
        step = abmtime(model), # Use abmtime for consistency if step! is called multiple times
        rust_infection = rust_inf,
        coffee_yield = coffee_yld,
        shade_coverage = mean(model.shade_map) # Assuming shade_map exists in properties
    ))

    # Save state plot every 20 steps
    if abmtime(model) % 20 == 0 || abmtime(model) == 1 # Save initial and every 20 steps
        p = plot_farm_state(model, abmtime(model))
        savefig(p, "visualizations/state_step_$(abmtime(model)).png")
    end
end

# Plot metrics over time
p3 = plot_metrics_over_time(data)
savefig(p3, "visualizations/metrics_over_time.png")

# Plot rust progression
p4 = plot_rust_progression(data)
savefig(p4, "visualizations/rust_progression.png")

println("Visualizations have been saved to the 'visualizations' directory.")