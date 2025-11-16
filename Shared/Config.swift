//
//  Config.swift
//  MarketWidget
//
//  Configuration for WebSocket and shared settings
//

import Foundation

struct Config {
    // MARK: - Development Mode

    /// Set to true to use mock data instead of WebSocket
    /// Perfect for offline testing!
    static let useMockData = true  // Change to false when using real API

    /// Mock data update interval (seconds)
    static let mockDataInterval: TimeInterval = 3.0

    // MARK: - Battery Optimization Settings

    /// Only connect during market hours (9:30 AM - 4:00 PM ET, Mon-Fri)
    /// Recommended: true (saves ~40% battery)
    static let onlyConnectDuringMarketHours = true

    /// Only connect on WiFi (not cellular)
    /// Recommended: true for iPhone 13 mini (saves ~30% battery)
    static let wifiOnlyMode = false  // Set true to enable

    /// Auto-disconnect when Low Power Mode is enabled
    /// Recommended: true
    static let respectLowPowerMode = true

    /// Auto-disconnect after this many minutes in background
    /// Recommended: 15 minutes (iOS kills background apps around 30 min anyway)
    /// Set to 0 to disable
    static let backgroundDisconnectMinutes: Double = 15

    // MARK: - WebSocket Configuration

    /// Your private WebSocket API endpoint
    /// For local testing: "ws://YOUR_MAC_IP:8080"
    /// For Schwab: "wss://streamer-api.schwab.com/"
    /// For Tastytrade: "wss://streamer.tastytrade.com/"
    static let websocketURL = "ws://192.168.1.100:8080"  // Update with your Mac's IP

    /// Optional: API key if your endpoint requires authentication
    /// This will be stored securely in Keychain
    static var apiKey: String? {
        get { KeychainHelper.shared.get(key: "market_api_key") }
        set {
            if let value = newValue {
                KeychainHelper.shared.save(key: "market_api_key", value: value)
            } else {
                KeychainHelper.shared.delete(key: "market_api_key")
            }
        }
    }

    // MARK: - App Groups

    /// App Group identifier for sharing data between app and widget
    /// Format: "group.com.yourcompany.marketwidget"
    static let appGroupIdentifier = "group.com.yourcompany.marketwidget"

    // MARK: - Widget Configuration

    /// How often the widget should refresh (in minutes)
    static let widgetRefreshInterval: TimeInterval = 1 // 1 minute

    /// Maximum reconnection attempts for WebSocket
    static let maxReconnectAttempts = 5

    /// Delay between reconnection attempts (in seconds)
    static let reconnectDelay: TimeInterval = 3

    /// WebSocket heartbeat interval (in seconds)
    /// Higher = less battery usage, but may disconnect on some servers
    static let heartbeatInterval: TimeInterval = 60
}
