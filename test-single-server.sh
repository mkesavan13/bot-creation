#!/bin/bash

# Simple test script for a single server with pingy
# Usage: ./test-single-server.sh [port]

PORT=${1:-3000}
echo "Testing pingy tunnel for port $PORT..."

# Start the Express server
echo "Starting Express server on port $PORT..."
node app.js &
SERVER_PID=$!

# Wait for server to start
sleep 2

# Test local server first
echo "Testing local server..."
if curl -s -f "http://localhost:$PORT/health" > /dev/null; then
    echo "✅ Local server is running"
else
    echo "❌ Local server failed to start"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

# Create pingy tunnel
echo "Creating pingy tunnel..."
ssh -p 443 -R0:localhost:$PORT qr@a.pinggy.io > tunnel.log 2>&1 &
TUNNEL_PID=$!

# Wait for tunnel to establish
sleep 5

# Extract tunnel URL
TUNNEL_URL=$(grep -o 'https://[^[:space:]]*' tunnel.log | head -1)

if [ -n "$TUNNEL_URL" ]; then
    echo "Tunnel created: $TUNNEL_URL"
    
    # Test tunnel
    echo "Testing tunnel..."
    if curl -s -f "$TUNNEL_URL/health" > /dev/null; then
        echo "✅ Tunnel is working!"
        echo "You can access your server at: $TUNNEL_URL"
    else
        echo "❌ Tunnel test failed"
    fi
else
    echo "❌ Failed to create tunnel"
fi

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    kill $SERVER_PID 2>/dev/null
    kill $TUNNEL_PID 2>/dev/null
    rm -f tunnel.log
}

# Set up cleanup on script exit
trap cleanup EXIT

echo "Press Ctrl+C to stop the test..."
wait
