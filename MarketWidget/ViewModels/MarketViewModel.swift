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

    init() {
        webSocketManager.delegate = self

        // Load cached data
        loadCachedData()
    }

    // MARK: - WebSocket Control

    func connect() {
        webSocketManager.connect()
        connectionStatus = "Connecting..."
    }

    func disconnect() {
        webSocketManager.disconnect()
        connectionStatus = "Disconnected"
        isConnected = false
    }

    func reconnect() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.connect()
        }
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
