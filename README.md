# Webex Bot with Pingy Tunneling

A Webex bot application that handles echo commands and mathematical expressions, now using Pingy for secure tunneling instead of localtunnel.

## Features

- **Webex Bot Integration**: Handles webhook events from Webex
- **Echo Commands**: Echoes back messages sent to the bot
- **Mathematical Expressions**: Evaluates and returns results of math expressions
- **Pingy Tunneling**: Uses Pingy for secure, reliable tunneling
- **Multi-Server Support**: Can run and test up to 31 servers simultaneously

## Prerequisites

- Node.js (>=14.0.0)
- SSH client (for Pingy tunneling)
- Webex Bot access token (set as `WEBEX_ACCESS_TOKEN` environment variable)

## Installation

```bash
npm install
```

## Usage

### Development Mode (Single Server)
```bash
npm run dev
```
This will start the bot server and create a Pingy tunnel for port 3000.

### Testing Single Server
```bash
npm run test-single
```
Tests a single server with Pingy tunneling.

### Testing Multiple Servers
```bash
npm run test-multi
```
Starts 31 servers on ports 3000-3030 and tests each with Pingy tunnels.

### Testing All Servers (Alternative)
```bash
npm run test-all
```
Uses the comprehensive test script for all 31 servers.

## API Endpoints

- `GET /` - Root endpoint with server information
- `GET /health` - Health check endpoint
- `POST /webhook` - Webex webhook endpoint
- `POST /math` - Mathematical expression evaluator

## Pingy vs Localtunnel

### Advantages of Pingy:
- **No Installation Required**: Uses SSH (pre-installed on most systems)
- **More Reliable**: Better uptime and connection stability
- **Secure**: Uses SSH encryption
- **Multiple Protocols**: Supports HTTP, TCP, and UDP
- **Custom Domains**: Pro accounts support custom domains

### Migration from Localtunnel:
The project has been migrated from localtunnel to Pingy:
- **Before**: `npx localtunnel --port 3000`
- **After**: `ssh -p 443 -R0:localhost:3000 qr@a.pinggy.io`

## Environment Variables

- `PORT`: Server port (default: 3000)
- `WEBEX_ACCESS_TOKEN`: Webex bot access token

## Testing Results

The test scripts will verify that all 31 servers are accessible through Pingy tunnels and provide detailed status reports.

## Troubleshooting

1. **SSH Connection Issues**: Ensure SSH is installed and accessible
2. **Port Conflicts**: Make sure ports 3000-3030 are available
3. **Webex Token**: Verify your Webex access token is valid
4. **Network Issues**: Check your internet connection for tunnel creation

## Scripts

- `npm start` - Start the bot server
- `npm run dev` - Development mode with Pingy tunnel
- `npm run test-single` - Test single server with Pingy
- `npm run test-multi` - Test 31 servers with Pingy
- `npm run test-all` - Comprehensive test script
