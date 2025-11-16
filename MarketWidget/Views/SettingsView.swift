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
