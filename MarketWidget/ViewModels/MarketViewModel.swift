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
    private var backgroundTimer: Timer?
    private let batteryOptimizer = BatteryOptimizer.shared

    init() {
        webSocketManager.delegate = self
        batteryOptimizer.delegate = self

        // Load cached data
        loadCachedData()

        // Setup background monitoring
        setupBackgroundMonitoring()
    }

    // MARK: - WebSocket Control

    func connect() {
        // Check battery optimizations
        let (allowed, reason) = batteryOptimizer.shouldConnect()

        if !allowed, let reason = reason {
            print("⚡ Connection blocked: \(reason)")
            connectionStatus = reason
            isConnected = false
            return
        }

        if Config.useMockData {
            // Use mock data mode (works offline!)
            startMockDataMode()
        } else {
            // Use real WebSocket connection
            webSocketManager.connect()
            connectionStatus = "Connecting..."

            // Start background disconnect timer if configured
            startBackgroundDisconnectTimer()
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

    // MARK: - Background Management

    private func setupBackgroundMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        print("📱 App entered background")
        if Config.backgroundDisconnectMinutes > 0 {
            startBackgroundDisconnectTimer()
        }
    }

    @objc private func appWillEnterForeground() {
        print("📱 App returning to foreground")
        backgroundTimer?.invalidate()
        backgroundTimer = nil

        // Reconnect if we should be connected
        if !isConnected && !Config.useMockData {
            connect()
        }
    }

    private func startBackgroundDisconnectTimer() {
        guard Config.backgroundDisconnectMinutes > 0 else { return }

        backgroundTimer?.invalidate()

        let interval = Config.backgroundDisconnectMinutes * 60

        backgroundTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            print("⏰ Background timeout - disconnecting to save battery")
            self?.disconnect()
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

// MARK: - BatteryOptimizerDelegate

extension MarketViewModel: BatteryOptimizerDelegate {
    func networkTypeDidChange(isWiFi: Bool) {
        print("📶 Network type changed: \(isWiFi ? "WiFi" : "Cellular")")

        // If WiFi-only mode and we switched to cellular, disconnect
        if Config.wifiOnlyMode && !isWiFi && isConnected {
            print("📵 Disconnecting - WiFi-only mode enabled")
            disconnect()
            connectionStatus = "WiFi only - on cellular"
        }
        // If we're back on WiFi and should be connected, reconnect
        else if Config.wifiOnlyMode && isWiFi && !isConnected {
            print("📶 Reconnecting - back on WiFi")
            connect()
        }
    }

    func lowPowerModeDidChange(isEnabled: Bool) {
        print("🔋 Low Power Mode: \(isEnabled ? "ON" : "OFF")")

        if Config.respectLowPowerMode {
            if isEnabled && isConnected {
                print("💤 Disconnecting - Low Power Mode enabled")
                disconnect()
                connectionStatus = "Paused (Low Power Mode)"
            } else if !isEnabled && !isConnected {
                print("⚡ Reconnecting - Low Power Mode disabled")
                connect()
            }
        }
    }
}
