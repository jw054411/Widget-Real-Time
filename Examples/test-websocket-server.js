#!/usr/bin/env node

/**
 * Test WebSocket Server for Market Widget
 *
 * This is a simple Node.js WebSocket server that sends mock market data
 * for testing your iPhone widget during development.
 *
 * Requirements:
 *   npm install ws
 *
 * Usage:
 *   node test-websocket-server.js
 *
 * Then update Config.swift:
 *   static let websocketURL = "ws://YOUR_LOCAL_IP:8080"
 */

const WebSocket = require('ws');

const PORT = 8080;
const wss = new WebSocket.Server({ port: PORT });

// Mock symbols to send data for
const SYMBOLS = ['AAPL', 'TSLA', 'GOOGL', 'MSFT', 'AMZN'];

// Base prices for each symbol
const basePrices = {
    'AAPL': 175.00,
    'TSLA': 242.00,
    'GOOGL': 140.00,
    'MSFT': 380.00,
    'AMZN': 155.00
};

console.log(`🚀 WebSocket server starting on port ${PORT}...`);

wss.on('connection', (ws, req) => {
    const clientIP = req.socket.remoteAddress;
    console.log(`✅ Client connected from ${clientIP}`);

    // Send welcome message
    ws.send(JSON.stringify({
        type: 'connected',
        message: 'Connected to test market data server'
    }));

    // Send initial data for all symbols
    SYMBOLS.forEach(symbol => {
        sendMarketData(ws, symbol);
    });

    // Send updates every 3 seconds
    const interval = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
            // Randomly pick a symbol to update
            const symbol = SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)];
            sendMarketData(ws, symbol);
        }
    }, 3000);

    // Handle incoming messages
    ws.on('message', (message) => {
        console.log(`📨 Received: ${message}`);

        try {
            const data = JSON.parse(message);

            // Handle subscribe request
            if (data.action === 'subscribe') {
                console.log(`📊 Client subscribing to: ${data.symbols}`);
                ws.send(JSON.stringify({
                    type: 'subscribed',
                    symbols: data.symbols || SYMBOLS
                }));
            }
        } catch (error) {
            console.error('❌ Error parsing message:', error);
        }
    });

    // Handle disconnection
    ws.on('close', () => {
        console.log(`🔌 Client disconnected from ${clientIP}`);
        clearInterval(interval);
    });

    // Handle errors
    ws.on('error', (error) => {
        console.error('❌ WebSocket error:', error);
    });
});

/**
 * Generate and send mock market data
 */
function sendMarketData(ws, symbol) {
    const basePrice = basePrices[symbol];

    // Generate random price movement (-2% to +2%)
    const priceChange = (Math.random() - 0.5) * (basePrice * 0.04);
    const currentPrice = basePrice + priceChange;

    // Calculate change from base price
    const change = currentPrice - basePrice;
    const changePercent = (change / basePrice) * 100;

    const marketData = {
        symbol: symbol,
        price: parseFloat(currentPrice.toFixed(2)),
        change: parseFloat(change.toFixed(2)),
        change_percent: parseFloat(changePercent.toFixed(2)),
        volume: Math.floor(Math.random() * 100000000) + 10000000,
        timestamp: new Date().toISOString(),
        high: parseFloat((basePrice + Math.random() * 10).toFixed(2)),
        low: parseFloat((basePrice - Math.random() * 10).toFixed(2)),
        market_status: isMarketOpen() ? 'Open' : 'Closed'
    };

    // Send as wrapped message (you can change format as needed)
    const message = {
        type: 'market_data',
        payload: marketData
    };

    // Or send direct market data:
    // const message = marketData;

    // Or send as array:
    // const message = [marketData];

    if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(message));
        console.log(`📊 Sent update for ${symbol}: $${marketData.price} (${marketData.change_percent > 0 ? '+' : ''}${marketData.change_percent}%)`);
    }
}

/**
 * Check if market is open (simplified - just checks time)
 */
function isMarketOpen() {
    const now = new Date();
    const hour = now.getHours();
    const day = now.getDay();

    // Weekdays 9 AM - 4 PM (simplified)
    return day >= 1 && day <= 5 && hour >= 9 && hour < 16;
}

/**
 * Send heartbeat to keep connection alive
 */
setInterval(() => {
    wss.clients.forEach((ws) => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
                type: 'heartbeat',
                timestamp: new Date().toISOString()
            }));
        }
    });
}, 30000);  // Every 30 seconds

console.log(`✅ WebSocket server running on ws://localhost:${PORT}`);
console.log(`📱 Update your Config.swift with: ws://YOUR_LOCAL_IP:${PORT}`);
console.log(`💡 Find your local IP with: ipconfig (Windows) or ifconfig (Mac/Linux)`);
console.log(`\n📊 Broadcasting market data for: ${SYMBOLS.join(', ')}\n`);

// Handle process termination
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down server...');
    wss.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});
