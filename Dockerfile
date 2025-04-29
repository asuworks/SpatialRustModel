# Use a specific version of the Julia image as the base image
FROM julia:1.9.1-bullseye
# Install system dependencies potentially needed by Plots backends (e.g., GR)
# Run as root before switching user
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    # Add other potential dependencies here if needed by your chosen Plots backend (e.g., libqt5widgets5 for PyPlot)
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a new user named 'appuser' with a home directory
RUN useradd --create-home --shell /bin/bash appuser --uid 1001 || echo "User appuser already exists or failed to create"

# Create a directory for the application in the appuser's home directory
RUN mkdir -p /home/appuser/app

# Set the working directory to the app directory
WORKDIR /home/appuser/app

# Change the ownership of the app directory
RUN chown -R appuser:appuser /home/appuser/app

# Switch to the appuser user for running subsequent commands
USER appuser

# Set environment variables
ENV JULIA_DEPOT_PATH="/home/appuser/.julia"
ENV JULIA_PROJECT="/home/appuser/app"
ENV JULIA_NUM_THREADS="auto"
ENV JULIA_REVISE="off"
ENV EARLYBIND="true"

# --- COPY ALL PROJECT FILES FIRST ---
# Copy dependency files AND source code before running Pkg commands
COPY --chown=appuser:appuser Project.toml ./
COPY --chown=appuser:appuser src ./src
COPY --chown=appuser:appuser app.jl ./
# --- ---------------------------- ---

# Now update registry, instantiate, build, and precompile
# Pkg should now find src/SpatialRust.jl correctly
RUN julia --project --optimize=3 -e "using Pkg; Pkg.Registry.update(); Pkg.instantiate(); Pkg.build(); Pkg.precompile()"

# Inform Docker that the container listens on port 8080 at runtime
EXPOSE 8080

# Define the command to run the Dash app when the container starts
CMD ["julia", "--project", "--optimize=3", "app.jl"]