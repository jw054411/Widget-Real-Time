//
//  Config.swift
//  MarketWidget
//
//  Configuration for WebSocket and shared settings
//

import Foundation

struct Config {
    // MARK: - WebSocket Configuration

    /// Your private WebSocket API endpoint
    /// Example: "wss://your-api.com/market-data"
    static let websocketURL = "wss://your-api.com/market-data"

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
}
