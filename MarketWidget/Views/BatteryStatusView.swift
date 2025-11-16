//
//  BatteryStatusView.swift
//  MarketWidget
//
//  Shows battery optimization status and current battery level
//

import SwiftUI

struct BatteryStatusView: View {
    @StateObject private var optimizer = BatteryOptimizer.shared
    @State private var batteryLevel: Float = 0
    @State private var isCharging: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Battery Level
            HStack {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryColor)

                Text(optimizer.batteryLevelString)
                    .font(.body)

                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }

                Spacer()

                if optimizer.isLowPowerModeEnabled {
                    Text("Low Power Mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            // Network Status
            HStack {
                Image(systemName: optimizer.isOnWiFi ? "wifi" : "antenna.radiowaves.left.and.right")
                    .foregroundColor(optimizer.isOnWiFi ? .blue : .green)

                Text(optimizer.isOnWiFi ? "WiFi" : "Cellular")
                    .font(.body)

                Spacer()
            }

            Divider()

            // Optimization Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Battery Optimizations")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(optimizer.getOptimizationStatus())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Low Battery Warning
            if optimizer.shouldShowLowBatteryWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("Low battery - consider using WiFi-only mode or reducing update frequency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            updateBatteryInfo()

            // Update every 30 seconds
            Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                updateBatteryInfo()
            }
        }
    }

    private func updateBatteryInfo() {
        batteryLevel = optimizer.batteryLevel
        isCharging = optimizer.isCharging
    }

    private var batteryIcon: String {
        if isCharging {
            return "battery.100.bolt"
        }

        if batteryLevel < 0 {
            return "battery.0"
        } else if batteryLevel <= 0.20 {
            return "battery.25"
        } else if batteryLevel <= 0.50 {
            return "battery.50"
        } else if batteryLevel <= 0.75 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }

    private var batteryColor: Color {
        if isCharging {
            return .green
        }

        if batteryLevel < 0.20 {
            return .red
        } else if batteryLevel < 0.50 {
            return .orange
        } else {
            return .green
        }
    }
}

struct BatteryStatusView_Previews: PreviewProvider {
    static var previews: some View {
        BatteryStatusView()
    }
}
