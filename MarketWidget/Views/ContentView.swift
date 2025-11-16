//
//  ContentView.swift
//  MarketWidget
//
//  Main view for the app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MarketViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Connection Status Bar
                ConnectionStatusBar(
                    isConnected: viewModel.isConnected,
                    status: viewModel.connectionStatus,
                    lastUpdate: viewModel.formattedLastUpdate
                )

                // Market Data List
                if viewModel.marketData.isEmpty {
                    EmptyStateView()
                } else {
                    List(viewModel.marketData, id: \.symbol) { data in
                        MarketDataRow(data: data)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Market Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: viewModel.connect) {
                            Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .disabled(viewModel.isConnected)

                        Button(action: viewModel.disconnect) {
                            Label("Disconnect", systemImage: "xmark.circle")
                        }
                        .disabled(!viewModel.isConnected)

                        Button(action: viewModel.reconnect) {
                            Label("Reconnect", systemImage: "arrow.clockwise")
                        }

                        Divider()

                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    let isConnected: Bool
    let status: String
    let lastUpdate: String

    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)

            Text(status)
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            Text("Updated: \(lastUpdate)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// MARK: - Market Data Row

struct MarketDataRow: View {
    let data: MarketData

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Symbol
            VStack(alignment: .leading, spacing: 4) {
                Text(data.symbol)
                    .font(.headline)
                    .fontWeight(.bold)

                if let status = data.marketStatus {
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Price and Change
            VStack(alignment: .trailing, spacing: 4) {
                Text(data.formattedPrice)
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    Image(systemName: data.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)

                    Text(data.formattedChangePercent)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(data.isPositive ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Market Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Connect to your WebSocket API to start receiving real-time market data")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MarketViewModel())
    }
}
