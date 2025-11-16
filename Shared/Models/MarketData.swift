//
//  MarketData.swift
//  MarketWidget
//
//  Data models for market information
//

import Foundation

/// Represents real-time market data
struct MarketData: Codable, Equatable {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Double?
    let timestamp: Date

    /// High price for the day
    let high: Double?

    /// Low price for the day
    let low: Double?

    /// Market status (open/closed)
    let marketStatus: String?

    enum CodingKeys: String, CodingKey {
        case symbol
        case price
        case change
        case changePercent = "change_percent"
        case volume
        case timestamp
        case high
        case low
        case marketStatus = "market_status"
    }

    /// Formatted price string
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }

    /// Formatted change with sign
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@$%.2f", sign, change)
    }

    /// Formatted percent change with sign
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, changePercent)
    }

    /// Is the price moving up?
    var isPositive: Bool {
        change >= 0
    }
}

/// Container for multiple market data items
struct MarketDataResponse: Codable {
    let data: [MarketData]
    let timestamp: Date?
}

/// WebSocket message wrapper
struct WebSocketMessage: Codable {
    let type: String
    let payload: MarketData?
    let error: String?
}
