//
//  MockDataGenerator.swift
//  MarketWidget
//
//  Generates mock market data for offline testing
//

import Foundation

class MockDataGenerator {
    static let shared = MockDataGenerator()

    private var baseprices: [String: Double] = [
        // Futures
        "/ES": 4789.25,
        "/NQ": 16823.75,
        "/YM": 37545.00,

        // Indices
        "$SPX.X": 4792.50,
        "$NDX.X": 16830.25,
        "$DJI": 37551.00
    ]

    private init() {}

    /// Generate mock data for current market state (futures or indices)
    func generateCurrentMarketData() -> [MarketData] {
        let symbols = MarketHoursHelper.shared.getCurrentSymbols()
        return symbols.map { generateMockData(for: $0) }
    }

    /// Generate mock data for a specific symbol
    func generateMockData(for symbol: String) -> MarketData {
        let basePrice = basePrices[symbol] ?? 100.0

        // Random price movement (-1% to +1%)
        let changePercent = Double.random(in: -1.0...1.0)
        let change = basePrice * (changePercent / 100.0)
        let currentPrice = basePrice + change

        // Update base price for next time (creates realistic movement)
        basePrices[symbol] = currentPrice

        return MarketData(
            symbol: symbol,
            price: currentPrice,
            change: change,
            changePercent: changePercent,
            volume: Double.random(in: 10_000_000...100_000_000),
            timestamp: Date(),
            high: currentPrice + abs(change) * 2,
            low: currentPrice - abs(change) * 2,
            marketStatus: MarketHoursHelper.shared.isMarketOpen() ? "Open" : "Closed"
        )
    }

    /// Start generating mock data periodically
    func startMockDataGeneration(interval: TimeInterval = 3.0, callback: @escaping ([MarketData]) -> Void) {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let mockData = self.generateCurrentMarketData()
            callback(mockData)
        }
    }
}
