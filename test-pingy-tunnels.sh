#!/bin/bash

# Script to test pingy tunnels for multiple servers
# This script will create tunnels for 31 servers and test their connectivity

echo "Starting pingy tunnel test for 31 servers..."

# Array to store tunnel URLs
declare -a tunnel_urls=()

# Function to create a pingy tunnel for a specific port
create_tunnel() {
    local port=$1
    local server_id=$2
    
    echo "Creating tunnel for server $server_id on port $port..."
    
    # Start pingy tunnel in background
    ssh -p 443 -R0:localhost:$port qr@a.pinggy.io > "tunnel_${server_id}.log" 2>&1 &
    local tunnel_pid=$!
    
    # Wait a moment for tunnel to establish
    sleep 3
    
    # Extract URL from log file
    local tunnel_url=$(grep -o 'https://[^[:space:]]*' "tunnel_${server_id}.log" | head -1)
    
    if [ -n "$tunnel_url" ]; then
        echo "Server $server_id tunnel created: $tunnel_url"
        tunnel_urls+=("$tunnel_url")
        
        # Test the tunnel
        echo "Testing server $server_id..."
        if curl -s -f "$tunnel_url/health" > /dev/null; then
            echo "✅ Server $server_id is accessible"
        else
            echo "❌ Server $server_id is not accessible"
        fi
    else
        echo "❌ Failed to create tunnel for server $server_id"
    fi
    
    echo "$tunnel_pid" > "tunnel_${server_id}.pid"
}

# Function to cleanup tunnels
cleanup() {
    echo "Cleaning up tunnels..."
    for i in {1..31}; do
        if [ -f "tunnel_${i}.pid" ]; then
            local pid=$(cat "tunnel_${i}.pid")
            kill $pid 2>/dev/null
            rm -f "tunnel_${i}.pid" "tunnel_${i}.log"
        fi
    done
}

# Set up cleanup on script exit
trap cleanup EXIT

# Create tunnels for 31 servers (ports 3000-3030)
for i in {1..31}; do
    port=$((3000 + i - 1))
    create_tunnel $port $i
    sleep 1  # Small delay between tunnel creations
done

echo ""
echo "=== Tunnel Summary ==="
echo "Total tunnels created: ${#tunnel_urls[@]}"
echo ""

# Test all tunnels
echo "Testing all tunnels..."
successful_tunnels=0
for i in "${!tunnel_urls[@]}"; do
    server_id=$((i + 1))
    url="${tunnel_urls[$i]}"
    
    echo -n "Server $server_id ($url): "
    if curl -s -f "$url/health" > /dev/null; then
        echo "✅ OK"
        ((successful_tunnels++))
    else
        echo "❌ FAILED"
    fi
done

echo ""
echo "=== Final Results ==="
echo "Successful tunnels: $successful_tunnels/31"
echo "Failed tunnels: $((31 - successful_tunnels))/31"

if [ $successful_tunnels -eq 31 ]; then
    echo "🎉 All 31 servers are working with pingy!"
    exit 0
else
    echo "⚠️  Some servers failed. Check the logs for details."
    exit 1
fi
