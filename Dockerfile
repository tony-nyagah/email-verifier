# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy go mod file
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o email-verifier .

# Final stage
FROM alpine:latest

WORKDIR /app

# Install CA certificates for HTTPS checks
RUN apk --no-cache add ca-certificates

# Copy binary from builder
COPY --from=builder /app/email-verifier .

# Copy templates and assets as they are required at runtime
COPY --from=builder /app/templates ./templates
COPY --from=builder /app/static ./static

# Expose port
EXPOSE 8081

# Run the application
CMD ["./email-verifier"]
