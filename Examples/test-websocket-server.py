#!/usr/bin/env python3

"""
Test WebSocket Server for Market Widget (Python version)

This is a simple Python WebSocket server that sends mock market data
for testing your iPhone widget during development.

Requirements:
    pip install websockets

Usage:
    python test-websocket-server.py

Then update Config.swift:
    static let websocketURL = "ws://YOUR_LOCAL_IP:8080"
"""

import asyncio
import json
import random
from datetime import datetime
from typing import Set
import websockets
from websockets.server import WebSocketServerProtocol

PORT = 8080

# Mock symbols to send data for
SYMBOLS = ['AAPL', 'TSLA', 'GOOGL', 'MSFT', 'AMZN']

# Base prices for each symbol
BASE_PRICES = {
    'AAPL': 175.00,
    'TSLA': 242.00,
    'GOOGL': 140.00,
    'MSFT': 380.00,
    'AMZN': 155.00
}

# Keep track of connected clients
connected_clients: Set[WebSocketServerProtocol] = set()


def generate_market_data(symbol: str) -> dict:
    """Generate mock market data for a symbol"""
    base_price = BASE_PRICES[symbol]

    # Generate random price movement (-2% to +2%)
    price_change = (random.random() - 0.5) * (base_price * 0.04)
    current_price = base_price + price_change

    # Calculate change from base price
    change = current_price - base_price
    change_percent = (change / base_price) * 100

    return {
        'symbol': symbol,
        'price': round(current_price, 2),
        'change': round(change, 2),
        'change_percent': round(change_percent, 2),
        'volume': random.randint(10_000_000, 100_000_000),
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'high': round(base_price + random.random() * 10, 2),
        'low': round(base_price - random.random() * 10, 2),
        'market_status': 'Open' if is_market_open() else 'Closed'
    }


def is_market_open() -> bool:
    """Check if market is open (simplified - just checks time)"""
    now = datetime.now()
    hour = now.hour
    weekday = now.weekday()

    # Weekdays (0-4) 9 AM - 4 PM (simplified)
    return 0 <= weekday <= 4 and 9 <= hour < 16


async def send_market_update(websocket: WebSocketServerProtocol, symbol: str):
    """Send a market data update to a client"""
    market_data = generate_market_data(symbol)

    # Send as wrapped message (you can change format as needed)
    message = {
        'type': 'market_data',
        'payload': market_data
    }

    # Or send direct market data:
    # message = market_data

    # Or send as array:
    # message = [market_data]

    await websocket.send(json.dumps(message))

    change_sign = '+' if market_data['change_percent'] > 0 else ''
    print(f"📊 Sent update for {symbol}: ${market_data['price']} "
          f"({change_sign}{market_data['change_percent']}%)")


async def broadcast_heartbeat():
    """Send periodic heartbeat to all connected clients"""
    while True:
        await asyncio.sleep(30)  # Every 30 seconds

        if connected_clients:
            message = json.dumps({
                'type': 'heartbeat',
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            })

            websockets.broadcast(connected_clients, message)


async def send_periodic_updates(websocket: WebSocketServerProtocol):
    """Send periodic market data updates to a client"""
    try:
        while True:
            # Send update every 3 seconds
            await asyncio.sleep(3)

            # Randomly pick a symbol to update
            symbol = random.choice(SYMBOLS)
            await send_market_update(websocket, symbol)

    except websockets.exceptions.ConnectionClosed:
        pass


async def handle_client(websocket: WebSocketServerProtocol, path: str):
    """Handle a client connection"""
    client_ip = websocket.remote_address[0]
    print(f"✅ Client connected from {client_ip}")

    # Add to connected clients
    connected_clients.add(websocket)

    try:
        # Send welcome message
        await websocket.send(json.dumps({
            'type': 'connected',
            'message': 'Connected to test market data server'
        }))

        # Send initial data for all symbols
        for symbol in SYMBOLS:
            await send_market_update(websocket, symbol)

        # Start sending periodic updates
        update_task = asyncio.create_task(send_periodic_updates(websocket))

        # Handle incoming messages
        async for message in websocket:
            print(f"📨 Received: {message}")

            try:
                data = json.loads(message)

                # Handle subscribe request
                if data.get('action') == 'subscribe':
                    symbols = data.get('symbols', SYMBOLS)
                    print(f"📊 Client subscribing to: {symbols}")

                    await websocket.send(json.dumps({
                        'type': 'subscribed',
                        'symbols': symbols
                    }))

            except json.JSONDecodeError:
                print(f"❌ Invalid JSON received: {message}")

        # Wait for update task to complete
        await update_task

    except websockets.exceptions.ConnectionClosed:
        print(f"🔌 Client disconnected from {client_ip}")

    finally:
        # Remove from connected clients
        connected_clients.discard(websocket)


async def main():
    """Start the WebSocket server"""
    print(f"🚀 WebSocket server starting on port {PORT}...")

    # Start heartbeat task
    asyncio.create_task(broadcast_heartbeat())

    # Start server
    async with websockets.serve(handle_client, "0.0.0.0", PORT):
        print(f"✅ WebSocket server running on ws://localhost:{PORT}")
        print(f"📱 Update your Config.swift with: ws://YOUR_LOCAL_IP:{PORT}")
        print(f"💡 Find your local IP with: ifconfig (Mac/Linux) or ipconfig (Windows)")
        print(f"\n📊 Broadcasting market data for: {', '.join(SYMBOLS)}\n")

        # Run forever
        await asyncio.Future()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 Shutting down server...")
        print("✅ Server closed")
