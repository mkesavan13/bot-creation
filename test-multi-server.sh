#!/bin/bash

# Multi-server pingy test script
# This script starts multiple Express servers on different ports and tests them with pingy

echo "Starting multi-server pingy test..."

# Configuration
NUM_SERVERS=31
BASE_PORT=3000
SERVER_PIDS=()
TUNNEL_PIDS=()

# Function to start a server on a specific port
start_server() {
    local port=$1
    local server_id=$2
    
    echo "Starting server $server_id on port $port..."
    
    # Create a temporary app file for this server
    cat > "app_${server_id}.js" << EOF
const express = require('express');
const app = express();
const PORT = $port;

app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        serverId: $server_id,
        port: $port,
        timestamp: new Date().toISOString()
    });
});

app.get('/', (req, res) => {
    res.json({
        message: "Server $server_id",
        port: $port,
        status: 'running'
    });
});

app.listen(PORT, () => {
    console.log(\`Server $server_id running on port \${PORT}\`);
});
EOF
    
    # Start the server
    node "app_${server_id}.js" > "server_${server_id}.log" 2>&1 &
    local server_pid=$!
    SERVER_PIDS+=($server_pid)
    
    # Wait for server to start
    sleep 1
    
    # Test local server
    if curl -s -f "http://localhost:$port/health" > /dev/null; then
        echo "✅ Server $server_id started successfully"
    else
        echo "❌ Server $server_id failed to start"
        return 1
    fi
}

# Function to create pingy tunnel for a server
create_tunnel() {
    local port=$1
    local server_id=$2
    
    echo "Creating pingy tunnel for server $server_id..."
    
    # Create tunnel
    ssh -p 443 -R0:localhost:$port qr@a.pinggy.io > "tunnel_${server_id}.log" 2>&1 &
    local tunnel_pid=$!
    TUNNEL_PIDS+=($tunnel_pid)
    
    # Wait for tunnel to establish
    sleep 3
    
    # Extract tunnel URL
    local tunnel_url=$(grep -o 'https://[^[:space:]]*' "tunnel_${server_id}.log" | head -1)
    
    if [ -n "$tunnel_url" ]; then
        echo "✅ Tunnel created for server $server_id: $tunnel_url"
        
        # Test tunnel
        if curl -s -f "$tunnel_url/health" > /dev/null; then
            echo "✅ Server $server_id tunnel is working"
            return 0
        else
            echo "❌ Server $server_id tunnel test failed"
            return 1
        fi
    else
        echo "❌ Failed to create tunnel for server $server_id"
        return 1
    fi
}

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    
    # Kill all servers
    for pid in "${SERVER_PIDS[@]}"; do
        kill $pid 2>/dev/null
    done
    
    # Kill all tunnels
    for pid in "${TUNNEL_PIDS[@]}"; do
        kill $pid 2>/dev/null
    done
    
    # Remove temporary files
    rm -f app_*.js server_*.log tunnel_*.log
}

# Set up cleanup on script exit
trap cleanup EXIT

# Start all servers
echo "Starting $NUM_SERVERS servers..."
for i in $(seq 1 $NUM_SERVERS); do
    port=$((BASE_PORT + i - 1))
    start_server $port $i
    if [ $? -ne 0 ]; then
        echo "Failed to start server $i"
        exit 1
    fi
done

echo ""
echo "All servers started. Creating pingy tunnels..."

# Create tunnels for all servers
successful_tunnels=0
for i in $(seq 1 $NUM_SERVERS); do
    port=$((BASE_PORT + i - 1))
    create_tunnel $port $i
    if [ $? -eq 0 ]; then
        ((successful_tunnels++))
    fi
    sleep 1  # Small delay between tunnel creations
done

echo ""
echo "=== Final Results ==="
echo "Total servers: $NUM_SERVERS"
echo "Successful tunnels: $successful_tunnels"
echo "Failed tunnels: $((NUM_SERVERS - successful_tunnels))"

if [ $successful_tunnels -eq $NUM_SERVERS ]; then
    echo "🎉 All $NUM_SERVERS servers are working with pingy!"
    echo ""
    echo "Press Ctrl+C to stop all servers and tunnels..."
    wait
else
    echo "⚠️  Some servers failed. Check the logs for details."
    exit 1
fi
