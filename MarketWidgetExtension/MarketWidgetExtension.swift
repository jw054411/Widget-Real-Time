//
//  MarketWidgetExtension.swift
//  MarketWidgetExtension
//
//  Widget extension for displaying market data on home screen
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct MarketEntry: TimelineEntry {
    let date: Date
    let marketData: [MarketData]
}

// MARK: - Timeline Provider

struct MarketTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MarketEntry {
        MarketEntry(
            date: Date(),
            marketData: [sampleMarketData()]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MarketEntry) -> Void) {
        let entry = MarketEntry(
            date: Date(),
            marketData: loadMarketData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MarketEntry>) -> Void) {
        let currentDate = Date()
        let marketData = loadMarketData()

        let entry = MarketEntry(
            date: currentDate,
            marketData: marketData
        )

        // Refresh timeline every minute
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: Int(Config.widgetRefreshInterval),
            to: currentDate
        )!

        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextUpdate)
        )

        completion(timeline)
    }

    // MARK: - Helper Methods

    private func loadMarketData() -> [MarketData] {
        SharedDataStore.shared.loadMarketData() ?? [sampleMarketData()]
    }

    private func sampleMarketData() -> MarketData {
        MarketData(
            symbol: "---",
            price: 0.0,
            change: 0.0,
            changePercent: 0.0,
            volume: nil,
            timestamp: Date(),
            high: nil,
            low: nil,
            marketStatus: "Waiting for data..."
        )
    }
}

// MARK: - Widget Views

struct MarketWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: MarketEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: MarketEntry

    private var primaryData: MarketData? {
        entry.marketData.first
    }

    var body: some View {
        if let data = primaryData {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(data.symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Spacer()

                    Circle()
                        .fill(data.isPositive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }

                Spacer()

                // Price
                Text(data.formattedPrice)
                    .font(.title)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                // Change
                HStack(spacing: 4) {
                    Image(systemName: data.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)

                    Text(data.formattedChangePercent)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(data.isPositive ? .green : .red)

                // Timestamp
                Text(formatTime(data.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        } else {
            NoDataView()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: MarketEntry

    var body: some View {
        if entry.marketData.isEmpty || entry.marketData.first?.symbol == "---" {
            NoDataView()
        } else {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Market Data")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatTime(entry.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                // Data Grid
                HStack(spacing: 12) {
                    ForEach(Array(entry.marketData.prefix(2)), id: \.symbol) { data in
                        MarketDataCard(data: data)
                    }
                }
                .padding()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: MarketEntry

    var body: some View {
        if entry.marketData.isEmpty || entry.marketData.first?.symbol == "---" {
            NoDataView()
        } else {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Market Data")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Spacer()

                    Text(formatTime(entry.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                Divider()
                    .padding(.vertical, 8)

                // Data List
                VStack(spacing: 12) {
                    ForEach(Array(entry.marketData.prefix(5)), id: \.symbol) { data in
                        MarketDataRow(data: data)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Market Data Card (for Medium Widget)

struct MarketDataCard: View {
    let data: MarketData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.symbol)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Text(data.formattedPrice)
                .font(.title3)
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)

            HStack(spacing: 3) {
                Image(systemName: data.isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)

                Text(data.formattedChangePercent)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(data.isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Market Data Row (for Large Widget)

struct MarketDataRow: View {
    let data: MarketData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.symbol)
                    .font(.subheadline)
                    .fontWeight(.bold)

                if let status = data.marketStatus {
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(data.formattedPrice)
                    .font(.callout)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Image(systemName: data.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)

                    Text(data.formattedChangePercent)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(data.isPositive ? .green : .red)
            }
        }
    }
}

// MARK: - No Data View

struct NoDataView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("No Data")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("Open the app to connect")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Configuration

@main
struct MarketWidgetBundle: WidgetBundle {
    var body: some Widget {
        MarketWidget()
    }
}

struct MarketWidget: Widget {
    let kind: String = "MarketWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MarketTimelineProvider()) { entry in
            MarketWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Market Data")
        .description("Real-time market data from your private API")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

struct MarketWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = [
            MarketData(
                symbol: "AAPL",
                price: 175.43,
                change: 2.15,
                changePercent: 1.24,
                volume: 50123456,
                timestamp: Date(),
                high: 176.50,
                low: 173.20,
                marketStatus: "Open"
            ),
            MarketData(
                symbol: "TSLA",
                price: 242.84,
                change: -5.23,
                changePercent: -2.11,
                volume: 95234567,
                timestamp: Date(),
                high: 248.90,
                low: 241.00,
                marketStatus: "Open"
            )
        ]

        let entry = MarketEntry(date: Date(), marketData: sampleData)

        Group {
            MarketWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            MarketWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            MarketWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
