//
//  MarketViewModel.swift
//  MarketWidget
//
//  ViewModel for managing market data and WebSocket connection
//

import Foundation
import SwiftUI
import WidgetKit

class MarketViewModel: ObservableObject {
    @Published var marketData: [MarketData] = []
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var lastUpdate: Date?

    private let webSocketManager = WebSocketManager.shared
    private var mockDataTimer: Timer?

    init() {
        webSocketManager.delegate = self

        // Load cached data
        loadCachedData()
    }

    // MARK: - WebSocket Control

    func connect() {
        if Config.useMockData {
            // Use mock data mode (works offline!)
            startMockDataMode()
        } else {
            // Use real WebSocket connection
            webSocketManager.connect()
            connectionStatus = "Connecting..."
        }
    }

    func disconnect() {
        if Config.useMockData {
            stopMockDataMode()
        } else {
            webSocketManager.disconnect()
        }
        connectionStatus = "Disconnected"
        isConnected = false
    }

    func reconnect() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connect()
        }
    }

    // MARK: - Mock Data Mode

    private func startMockDataMode() {
        print("🎭 Starting MOCK DATA mode (offline testing)")
        connectionStatus = "Mock Data Mode"
        isConnected = true

        // Generate initial mock data
        let mockData = MockDataGenerator.shared.generateCurrentMarketData()
        mockData.forEach { updateMarketData(with: $0) }

        // Start periodic updates
        mockDataTimer = Timer.scheduledTimer(withTimeInterval: Config.mockDataInterval, repeats: true) { [weak self] _ in
            let newMockData = MockDataGenerator.shared.generateCurrentMarketData()
            newMockData.forEach { self?.updateMarketData(with: $0) }
        }
    }

    private func stopMockDataMode() {
        print("🎭 Stopping mock data mode")
        mockDataTimer?.invalidate()
        mockDataTimer = nil
    }

    // MARK: - Data Management

    private func loadCachedData() {
        if let cached = SharedDataStore.shared.loadMarketData() {
            DispatchQueue.main.async {
                self.marketData = cached
                self.lastUpdate = SharedDataStore.shared.lastUpdateTime
            }
        }
    }

    private func updateMarketData(with newData: MarketData) {
        DispatchQueue.main.async {
            if let index = self.marketData.firstIndex(where: { $0.symbol == newData.symbol }) {
                self.marketData[index] = newData
            } else {
                self.marketData.append(newData)
            }

            self.lastUpdate = Date()

            // Reload widgets to reflect new data
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Helper Methods

    var statusColor: Color {
        isConnected ? .green : .red
    }

    var formattedLastUpdate: String {
        guard let lastUpdate = lastUpdate else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
}

// MARK: - WebSocketManagerDelegate

extension MarketViewModel: WebSocketManagerDelegate {
    func didReceiveMarketData(_ data: MarketData) {
        print("📊 ViewModel received market data: \(data.symbol)")
        updateMarketData(with: data)
    }

    func didReceiveError(_ error: Error) {
        print("❌ ViewModel received error: \(error)")

        DispatchQueue.main.async {
            self.connectionStatus = "Error: \(error.localizedDescription)"
        }
    }

    func didConnect() {
        print("✅ ViewModel: WebSocket connected")

        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = "Connected"
        }
    }

    func didDisconnect() {
        print("🔌 ViewModel: WebSocket disconnected")

        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
        }
    }
}
