# Email Verifier Makefile
# Requires Go 1.22+

# Variables
APP_NAME = email-verifier
BINARY_NAME = main
PORT = 8080

# Go parameters
GOCMD = go
GOBUILD = $(GOCMD) build
GOCLEAN = $(GOCMD) clean
GOTEST = $(GOCMD) test
GOGET = $(GOCMD) get
GOMOD = $(GOCMD) mod
GOFMT = $(GOCMD) fmt

# Docker parameters
DOCKER_IMAGE = $(APP_NAME):latest
DOCKER_COMPOSE = docker-compose

.PHONY: all build clean test run deps fmt vet docker-build docker-run docker-stop help

# Default target
all: clean deps test build

# Build the application
build:
	@echo "Building $(APP_NAME)..."
	$(GOBUILD) -o $(BINARY_NAME) -v .

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
	rm -f coverage.out

# Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

# Run tests with coverage report
test-coverage: test
	@echo "Generating coverage report..."
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Run benchmarks
benchmark:
	@echo "Running benchmarks..."
	$(GOTEST) -bench=. -benchmem ./...

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy

# Format code
fmt:
	@echo "Formatting code..."
	$(GOFMT) ./...

# Run go vet
vet:
	@echo "Running go vet..."
	$(GOCMD) vet ./...

# Run the application
run: build
	@echo "Starting $(APP_NAME) on port $(PORT)..."
	./$(BINARY_NAME)

# Run in development mode with live reload (requires air)
dev:
	@if command -v air > /dev/null; then \
		echo "Starting development server with live reload..."; \
		air; \
	else \
		echo "Air not found. Install with: go install github.com/cosmtrek/air@latest"; \
		echo "Running without live reload..."; \
		$(MAKE) run; \
	fi

# Install development tools
install-tools:
	@echo "Installing development tools..."
	$(GOGET) -u github.com/cosmtrek/air@latest
	$(GOGET) -u golang.org/x/tools/cmd/goimports@latest

# Lint code (requires golangci-lint)
lint:
	@if command -v golangci-lint > /dev/null; then \
		echo "Running linter..."; \
		golangci-lint run; \
	else \
		echo "golangci-lint not found. Install from https://golangci-lint.run/usage/install/"; \
	fi

# Security scan (requires gosec)
security:
	@if command -v gosec > /dev/null; then \
		echo "Running security scan..."; \
		gosec ./...; \
	else \
		echo "gosec not found. Install with: go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest"; \
	fi

# Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE) .

# Run with Docker
docker-run: docker-build
	@echo "Running with Docker..."
	docker run -p $(PORT):$(PORT) --rm --name $(APP_NAME)-container $(DOCKER_IMAGE)

# Run with Docker Compose
docker-compose-up:
	@echo "Starting with Docker Compose..."
	$(DOCKER_COMPOSE) up --build

# Stop Docker Compose
docker-compose-down:
	@echo "Stopping Docker Compose..."
	$(DOCKER_COMPOSE) down

# Production build
build-prod:
	@echo "Building for production..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -ldflags="-w -s" -o $(BINARY_NAME) .

# Cross-platform builds
build-windows:
	@echo "Building for Windows..."
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 $(GOBUILD) -o $(BINARY_NAME).exe .

build-mac:
	@echo "Building for macOS..."
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 $(GOBUILD) -o $(BINARY_NAME)-mac .

build-all: build-prod build-windows build-mac
	@echo "All builds completed"

# Create release
release: clean test build-all
	@echo "Creating release..."
	mkdir -p dist
	cp $(BINARY_NAME) dist/$(APP_NAME)-linux-amd64
	cp $(BINARY_NAME).exe dist/$(APP_NAME)-windows-amd64.exe
	cp $(BINARY_NAME)-mac dist/$(APP_NAME)-darwin-amd64
	cp -r templates dist/
	cp -r static dist/
	cp README.md dist/
	@echo "Release created in dist/"

# Load test (requires vegeta)
load-test:
	@if command -v vegeta > /dev/null; then \
		echo "Running load test..."; \
		echo "POST http://localhost:$(PORT)/api/verify" | vegeta attack -body='{"email":"test@example.com"}' -header="Content-Type: application/json" -rate=10 -duration=30s | vegeta report; \
	else \
		echo "vegeta not found. Install from https://github.com/tsenart/vegeta"; \
	fi

# Health check
health:
	@echo "Checking application health..."
	@curl -f http://localhost:$(PORT)/ > /dev/null 2>&1 && echo "✅ Application is healthy" || echo "❌ Application is not responding"

# Database migration (placeholder for future use)
migrate:
	@echo "No migrations needed for this application"

# Backup (placeholder for future use)
backup:
	@echo "No backup needed for this stateless application"

# Show help
help:
	@echo "Available targets:"
	@echo "  build          - Build the application"
	@echo "  clean          - Clean build artifacts"
	@echo "  test           - Run tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  benchmark      - Run benchmarks"
	@echo "  run            - Build and run the application"
	@echo "  dev            - Run in development mode with live reload"
	@echo "  deps           - Download dependencies"
	@echo "  fmt            - Format code"
	@echo "  vet            - Run go vet"
	@echo "  lint           - Run linter (requires golangci-lint)"
	@echo "  security       - Run security scan (requires gosec)"
	@echo "  docker-build   - Build Docker image"
	@echo "  docker-run     - Run with Docker"
	@echo "  docker-compose-up   - Start with Docker Compose"
	@echo "  docker-compose-down - Stop Docker Compose"
	@echo "  build-prod     - Build for production"
	@echo "  build-all      - Build for all platforms"
	@echo "  release        - Create release package"
	@echo "  load-test      - Run load test (requires vegeta)"
	@echo "  health         - Check application health"
	@echo "  install-tools  - Install development tools"
	@echo "  help           - Show this help message"
