# Build stage
FROM golang:1.22-alpine AS builder

# Required for multi-arch builds
ARG TARGETARCH

# Install git and ca-certificates
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies (cached layer)
RUN go mod download

# Copy source code
COPY . .

# Build the application with optimizations
RUN if [ -z "$TARGETARCH" ]; then \
        CGO_ENABLED=0 GOOS=linux go build \
        -ldflags="-w -s -extldflags '-static'" \
        -a -installsuffix cgo \
        -o main .; \
    else \
        CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH go build \
        -ldflags="-w -s -extldflags '-static'" \
        -a -installsuffix cgo \
        -o main .; \
    fi

# Final stage
FROM alpine:latest

# Install ca-certificates
RUN apk --no-cache add ca-certificates

# Set working directory
WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Copy templates and static files
COPY --from=builder /app/templates ./templates
COPY --from=builder /app/static/ ./static/

# Expose port
EXPOSE 8081

# Health check (for systems that support it)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["./main", "--health-check"] || exit 1

# Run the application
ENTRYPOINT ["./main"]
