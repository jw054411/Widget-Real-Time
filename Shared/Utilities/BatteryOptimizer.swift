//
//  BatteryOptimizer.swift
//  MarketWidget
//
//  Battery optimization utilities for iPhone 13 mini and other devices
//

import Foundation
import UIKit
import Network

class BatteryOptimizer {
    static let shared = BatteryOptimizer()

    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.marketwidget.network")

    private(set) var isOnWiFi = true
    private(set) var isLowPowerModeEnabled = false

    weak var delegate: BatteryOptimizerDelegate?

    private init() {
        setupNetworkMonitoring()
        setupLowPowerModeMonitoring()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let wasOnWiFi = self?.isOnWiFi ?? true
            self?.isOnWiFi = path.usesInterfaceType(.wifi)

            if wasOnWiFi != self?.isOnWiFi {
                print("📶 Network changed: \(self?.isOnWiFi == true ? "WiFi" : "Cellular")")
                DispatchQueue.main.async {
                    self?.delegate?.networkTypeDidChange(isWiFi: self?.isOnWiFi ?? false)
                }
            }
        }

        networkMonitor.start(queue: monitorQueue)
    }

    // MARK: - Low Power Mode Monitoring

    private func setupLowPowerModeMonitoring() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeChanged),
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }

    @objc private func lowPowerModeChanged() {
        let wasEnabled = isLowPowerModeEnabled
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

        if wasEnabled != isLowPowerModeEnabled {
            print("🔋 Low Power Mode: \(isLowPowerModeEnabled ? "ON" : "OFF")")
            DispatchQueue.main.async {
                self.delegate?.lowPowerModeDidChange(isEnabled: self.isLowPowerModeEnabled)
            }
        }
    }

    // MARK: - Battery Optimization Checks

    /// Check if we should connect based on all battery optimization settings
    func shouldConnect() -> (allowed: Bool, reason: String?) {
        // Check Low Power Mode
        if Config.respectLowPowerMode && isLowPowerModeEnabled {
            return (false, "Low Power Mode is enabled")
        }

        // Check WiFi-only mode
        if Config.wifiOnlyMode && !isOnWiFi {
            return (false, "WiFi-only mode enabled, currently on cellular")
        }

        // Check market hours
        if Config.onlyConnectDuringMarketHours && !MarketHoursHelper.shared.isMarketOpen() {
            return (false, "Market is closed")
        }

        return (true, nil)
    }

    /// Get battery level (0.0 to 1.0)
    var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    /// Get battery state
    var batteryState: UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState
    }

    /// Is device charging?
    var isCharging: Bool {
        let state = batteryState
        return state == .charging || state == .full
    }

    /// Get battery level as percentage string
    var batteryLevelString: String {
        let level = batteryLevel
        if level < 0 {
            return "Unknown"
        }
        return String(format: "%.0f%%", level * 100)
    }

    /// Should we show low battery warning?
    var shouldShowLowBatteryWarning: Bool {
        let level = batteryLevel
        return level > 0 && level < 0.20 && !isCharging
    }

    /// Get optimization status summary
    func getOptimizationStatus() -> String {
        var status: [String] = []

        if Config.onlyConnectDuringMarketHours {
            status.append("Market hours only")
        }

        if Config.wifiOnlyMode {
            status.append("WiFi only")
        }

        if Config.respectLowPowerMode {
            status.append("Respect low power mode")
        }

        if Config.backgroundDisconnectMinutes > 0 {
            status.append("Auto-disconnect: \(Int(Config.backgroundDisconnectMinutes))m")
        }

        return status.isEmpty ? "No optimizations" : status.joined(separator: " • ")
    }

    deinit {
        networkMonitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Delegate Protocol

protocol BatteryOptimizerDelegate: AnyObject {
    func networkTypeDidChange(isWiFi: Bool)
    func lowPowerModeDidChange(isEnabled: Bool)
}
