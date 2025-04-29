.PHONY: build run clean setup compose down logs dev test

# Setup Julia environment using Docker
setup:
	@echo "Setting up Julia environment..."
	docker run --rm -v $(PWD):/home/appuser/app -w /home/appuser/app julia:1.9.1-bullseye julia -e 'using Pkg; Pkg.Registry.update(); Pkg.activate("."); Pkg.instantiate(); Pkg.resolve()'
	@echo "Setup complete!"

# Build the Docker image
build:
	@echo "Building Docker image..."
	docker build -t spatialrust .
	@echo "Build complete!"

# Run the container
run:
	@echo "Running container..."
	docker run -p 8080:8080 \
	           -v $(PWD)/results:/home/appuser/app/results \
	           -v $(PWD)/visualizations:/home/appuser/app/visualizations \
	           spatialrust

# Clean up Docker resources
clean:
	@echo "Cleaning up..."
	docker rm -f $$(docker ps -aq --filter ancestor=spatialrust) 2>/dev/null || true
	docker rmi spatialrust 2>/dev/null || true
	rm -rf results/* visualizations/* 
	@echo "Cleanup complete!"

# Run with docker compose (includes setup)
compose:
	@echo "Starting with docker compose..."
	docker compose up --build

# Stop and remove containers
down:
	@echo "Stopping containers..."
	docker compose down

# View logs
logs:
	docker compose logs -f

# Development setup
dev:
	@echo "Setting up development environment..."
	docker run --rm -v $(PWD):/home/appuser/app -w /home/appuser/app \
	    -e JULIA_DEPOT_PATH="/home/appuser/.julia" \
	    -e JULIA_PROJECT="/home/appuser/app" \
	    -e JULIA_NUM_THREADS="auto" \
	    -e JULIA_REVISE="on" \
	    julia:1.9.1-bullseye julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate(); Pkg.precompile()'
	@echo "Development environment ready!"

# Test the application
test:
	@echo "Running tests..."
	docker run --rm -v $(PWD):/home/appuser/app -w /home/appuser/app \
	    -e JULIA_DEPOT_PATH="/home/appuser/.julia" \
	    -e JULIA_PROJECT="/home/appuser/app" \
	    julia:1.9.1-bullseye julia -e 'using Pkg; Pkg.activate("."); Pkg.test()'
	@echo "Tests completed!" 