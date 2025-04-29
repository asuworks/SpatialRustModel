using Dash
using Base64
using Plots
using Serialization
using DataFrames
using Statistics
using Random
using Agents

include("src/SpatialRust.jl")
using .SpatialRust
using .SpatialRust.Visualization

function plot_to_base64(p)
    io = IOBuffer()
    png(p, io)
    data = take!(io)
    return "data:image/png;base64," * base64encode(data)
end

# Use Bootstrap CSS for better styling
app = dash(external_stylesheets = [
    "https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css"
])

# Define minimal custom styles for items not covered by Bootstrap
app_styles = Dict(
    "imageContainer" => Dict(
        "display" => "flex",
        "justifyContent" => "center",
        "alignItems" => "center"
    )
)

app.layout = html_div(className="container py-4") do
    # Add CSS for spinner animation
    html_div(
        style=Dict("display" => "none"),
        children=raw"""
        <style>
            @keyframes spinner {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
        </style>
        """
    ),
    
    html_h1("SpatialRust Model Simulation", className="text-center text-primary mb-4 fw-bold"),

    dcc_store(id="model-store"),
    dcc_store(id="metrics-store"),

    # Controls section using Bootstrap classes
    html_div(className="card mb-4 bg-light") do
        html_div(className="card-body") do
            html_div(className="d-flex flex-wrap justify-content-center align-items-center gap-3") do
                html_button(
                    "Initialize Model", 
                    id="init-button", 
                    n_clicks=0, 
                    className="btn btn-primary"
                ),
                html_span("Steps per click: ", className="mx-2"),
                dcc_input(
                    id="steps-input", 
                    value=1, 
                    type="number", 
                    min=1, 
                    step=1, 
                    className="form-control",
                    style=Dict("width" => "80px")
                ),
                html_button(
                    "Step Model", 
                    id="step-button", 
                    n_clicks=0, 
                    className="btn btn-success"
                )
            end,
            html_div(
                id="current-step-display", 
                children="Current Step: 0", 
                className="text-center fw-bold mt-3 text-secondary"
            )
        end
    end,

    # Visualizations section using Bootstrap grid and cards
    html_div(id="visualizations", className="row g-4") do
        html_div(className="col-md-6") do
            html_div(className="card h-100 shadow-sm") do
                html_div(className="card-header bg-white") do
                    html_h3("Farm State", className="card-title h5 text-primary border-bottom pb-2")
                end,
                html_div(className="card-body") do
                    html_div(style=app_styles["imageContainer"]) do
                        dcc_loading(
                            id="loading-farm-state",
                            type="circle",
                            color="#3498db",
                            children=[html_img(id="farm-state-img", className="img-fluid")]
                        )
                    end
                end
            end
        end,
        
        html_div(className="col-md-6") do
            html_div(className="card h-100 shadow-sm") do
                html_div(className="card-header bg-white") do
                    html_h3("Shade Distribution", className="card-title h5 text-primary border-bottom pb-2")
                end,
                html_div(className="card-body") do
                    html_div(style=app_styles["imageContainer"]) do
                        dcc_loading(
                            id="loading-shade-dist",
                            type="circle",
                            color="#3498db",
                            children=[html_img(id="shade-dist-img", className="img-fluid")]
                        )
                    end
                end
            end
        end,
        
        html_div(className="col-md-6") do
            html_div(className="card h-100 shadow-sm") do
                html_div(className="card-header bg-white") do
                    html_h3("Metrics Over Time", className="card-title h5 text-primary border-bottom pb-2")
                end,
                html_div(className="card-body") do
                    html_div(style=app_styles["imageContainer"]) do
                        dcc_loading(
                            id="loading-metrics",
                            type="circle",
                            color="#3498db",
                            children=[html_img(id="metrics-img", className="img-fluid")]
                        )
                    end
                end
            end
        end,
        
        html_div(className="col-md-6") do
            html_div(className="card h-100 shadow-sm") do
                html_div(className="card-header bg-white") do
                    html_h3("Rust Progression", className="card-title h5 text-primary border-bottom pb-2")
                end,
                html_div(className="card-body") do
                    html_div(style=app_styles["imageContainer"]) do
                        dcc_loading(
                            id="loading-rust-progression",
                            type="circle",
                            color="#3498db",
                            children=[html_img(id="rust-progression-img", className="img-fluid")]
                        )
                    end
                end
            end
        end
    end
end

# Main callback without loading-related outputs
callback!(
    app,
    Output("model-store", "data"),
    Output("metrics-store", "data"),
    Output("current-step-display", "children"),
    Output("farm-state-img", "src"),
    Output("shade-dist-img", "src"),
    Output("metrics-img", "src"),
    Output("rust-progression-img", "src"),
    Input("init-button", "n_clicks"),
    Input("step-button", "n_clicks"),
    State("model-store", "data"),
    State("metrics-store", "data"),
    State("steps-input", "value"),
    prevent_initial_call=true
) do init_clicks, step_clicks, model_data, metrics_data, steps_to_run
    ctx = Dash.callback_context()
    
    if isempty(ctx.triggered)
        return (
            model_data, 
            metrics_data,
            "No action taken", 
            model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14)),
            model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14)),
            model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14)),
            model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14))
        )
    end
    
    triggered = ctx.triggered[1].prop_id

    # Initialization Logic
    if triggered == "init-button.n_clicks"
        initial_model = init_spatialrust(
            seed = Int64(rand(UInt64) % typemax(Int64)),
            steps = 500
        )
        metrics_df = DataFrame(step=Int[], rust_infection=Float64[], coffee_yield=Float64[], shade_coverage=Float64[])

        io_model = IOBuffer()
        Serialization.serialize(io_model, initial_model)
        serialized_model = take!(io_model)

        io_metrics = IOBuffer()
        Serialization.serialize(io_metrics, metrics_df)
        serialized_metrics = take!(io_metrics)

        p_farm = plot_farm_state(initial_model, 0)
        p_shade = plot_shade_distribution(initial_model)
        p_metrics = plot_metrics_over_time(metrics_df)
        p_rust = plot_rust_progression(metrics_df)

        return (
            Dict("model" => base64encode(serialized_model)),
            Dict("metrics" => base64encode(serialized_metrics)),
            "Current Step: 0",
            plot_to_base64(p_farm),
            plot_to_base64(p_shade),
            plot_to_base64(p_metrics),
            plot_to_base64(p_rust)
        )

    # Stepping Logic
    elseif triggered == "step-button.n_clicks" && model_data !== nothing && metrics_data !== nothing
        serialized_model = base64decode(model_data["model"])
        model = Serialization.deserialize(IOBuffer(serialized_model))
        
        serialized_metrics = base64decode(metrics_data["metrics"])
        metrics_df = Serialization.deserialize(IOBuffer(serialized_metrics))

        try
            step_n!(model, steps_to_run)
        catch e
            println("Error during step: ", e)
            return (
                model_data,  # Keep original model
                metrics_data, # Keep original metrics
                "Error during step: $(typeof(e))",
                plot_to_base64(plot(title="Error occurred", titlefontsize=14)),
                plot_to_base64(plot(title="Error occurred", titlefontsize=14)),
                plot_to_base64(plot(title="Error occurred", titlefontsize=14)),
                plot_to_base64(plot(title="Error occurred", titlefontsize=14))
            )
        end

        current_step = abmtime(model)
        current_agents = collect(allagents(model))
        coffee_agents = filter(a -> typeof(a) == Coffee, current_agents)

        rust_inf = isempty(coffee_agents) ? 0.0 : mean(a.rusted for a in coffee_agents)
        coffee_yld = isempty(coffee_agents) ? 0.0 : sum(a.production for a in coffee_agents)
        shade_cov = mean(abmproperties(model).shade_map)
        
        push!(metrics_df, (step = current_step, rust_infection = rust_inf, coffee_yield = coffee_yld, shade_coverage = shade_cov))

        io_model = IOBuffer()
        Serialization.serialize(io_model, model)
        updated_serialized_model = take!(io_model)

        io_metrics = IOBuffer()
        Serialization.serialize(io_metrics, metrics_df)
        updated_serialized_metrics = take!(io_metrics)

        p_farm = plot_farm_state(model, current_step)
        p_shade = plot_shade_distribution(model)
        p_metrics = plot_metrics_over_time(metrics_df)
        p_rust = plot_rust_progression(metrics_df)

        return (
            Dict("model" => base64encode(updated_serialized_model)),
            Dict("metrics" => base64encode(updated_serialized_metrics)),
            "Current Step: $current_step",
            plot_to_base64(p_farm),
            plot_to_base64(p_shade),
            plot_to_base64(p_metrics),
            plot_to_base64(p_rust)
        )
    end

    # Default return if neither button was clicked
    return (
        model_data, 
        metrics_data,
        "No action taken", 
        model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14)),
        model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14)),
        model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14)),
        model_data === nothing ? "" : plot_to_base64(plot(title="Initialize model first", titlefontsize=14))
    )
end

run_server(app, "0.0.0.0", 8080, debug=true)