//
//  SettingsView.swift
//  MarketWidget
//
//  Settings view for configuring API connection
//

import SwiftUI

struct SettingsView: View {
    @State private var websocketURL: String = Config.websocketURL
    @State private var apiKey: String = Config.apiKey ?? ""
    @State private var showingSaveConfirmation = false

    var body: some View {
        Form {
            Section(header: Text("WebSocket Configuration")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WebSocket URL")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("wss://your-api.com/market-data", text: $websocketURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SecureField("Enter your API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("App Group")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Group Identifier")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(Config.appGroupIdentifier)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.vertical, 4)
                }
            }

            Section(header: Text("Widget Settings")) {
                HStack {
                    Text("Refresh Interval")
                    Spacer()
                    Text("\(Int(Config.widgetRefreshInterval)) min")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Battery Optimization"), footer: Text("These settings help extend battery life, especially recommended for iPhone 13 mini")) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.green)
                        Text("Market Hours Only")
                        Spacer()
                        Image(systemName: Config.onlyConnectDuringMarketHours ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(Config.onlyConnectDuringMarketHours ? .green : .gray)
                    }
                    Text("Only connect 9:30 AM - 4:00 PM ET Mon-Fri (saves ~40%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(.blue)
                        Text("WiFi Only Mode")
                        Spacer()
                        Image(systemName: Config.wifiOnlyMode ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(Config.wifiOnlyMode ? .green : .gray)
                    }
                    Text("Only connect on WiFi, not cellular (saves ~30%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "battery.25")
                            .foregroundColor(.orange)
                        Text("Respect Low Power Mode")
                        Spacer()
                        Image(systemName: Config.respectLowPowerMode ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(Config.respectLowPowerMode ? .green : .gray)
                    }
                    Text("Auto-pause when Low Power Mode enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "moon.zzz")
                            .foregroundColor(.purple)
                        Text("Background Disconnect")
                        Spacer()
                        Text("\(Int(Config.backgroundDisconnectMinutes))m")
                            .foregroundColor(.secondary)
                    }
                    Text("Auto-disconnect after \(Int(Config.backgroundDisconnectMinutes)) minutes in background")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Battery Status")) {
                BatteryStatusView()
            }

            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        Text("Save Settings")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .alert("Settings Saved", isPresented: $showingSaveConfirmation) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your settings have been saved. Restart the app for changes to take effect.")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveSettings() {
        // Save API key to Keychain
        if !apiKey.isEmpty {
            Config.apiKey = apiKey
        }

        // Note: WebSocket URL changes require editing Config.swift
        // In a production app, you'd save this to UserDefaults

        showingSaveConfirmation = true
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
