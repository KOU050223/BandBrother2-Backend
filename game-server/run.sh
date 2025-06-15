#!/bin/bash

# Load environment variables
export $(cat .env | xargs)

# Build and run the Go server
echo "Building Go server..."
go build -o bin/server ./cmd/server

echo "Starting WebSocket server on port $WS_PORT..."
./bin/server
