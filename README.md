# Real-Time Market Data Widget

A private iOS widget that displays real-time market data via WebSocket connection.

## Architecture

- **Main App**: Maintains WebSocket connection and updates shared data store
- **Widget Extension**: Reads from shared data store to display latest market data
- **Shared Framework**: Common data models and utilities
- **App Groups**: For data sharing between app and widget

## Setup

1. Open `MarketWidget.xcodeproj` in Xcode
2. Update the bundle identifier and team ID
3. Configure App Groups capability with your identifier
4. Update `Config.swift` with your WebSocket API endpoint
5. Build and run

## Configuration

Update your WebSocket endpoint in `Shared/Config.swift`:
```swift
static let websocketURL = "wss://your-api.com/market-data"
```

## Features

- Real-time WebSocket data streaming
- Support for all widget sizes (small, medium, large)
- Background updates when app is not active
- Secure credential storage in Keychain
- Auto-reconnection on connection loss
