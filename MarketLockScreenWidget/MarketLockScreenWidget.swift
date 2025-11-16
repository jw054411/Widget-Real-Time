//
//  MarketLockScreenWidget.swift
//  MarketLockScreenWidget
//
//  Lock screen widget for quick market data viewing
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget

struct MarketLockScreenWidget: Widget {
    let kind: String = "MarketLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MarketTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Market Data")
        .description("Real-time market data on your lock screen")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Lock Screen View Router

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: MarketEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        default:
            EmptyView()
        }
    }
}

// MARK: - Circular View (Above Clock)

struct CircularLockScreenView: View {
    let entry: MarketEntry

    private var primaryData: MarketData? {
        entry.marketData.first
    }

    var body: some View {
        if let data = primaryData {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 1) {
                    Text(data.symbol)
                        .font(.system(size: 11, weight: .bold))
                        .minimumScaleFactor(0.5)

                    Text(formatPrice(data.price))
                        .font(.system(size: 14, weight: .semibold))
                        .minimumScaleFactor(0.6)

                    HStack(spacing: 2) {
                        Image(systemName: data.isPositive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8))

                        Text(String(format: "%.1f%%", abs(data.changePercent)))
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(data.isPositive ? .green : .red)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 2) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)

                    Text("--")
                        .font(.caption2)
                }
            }
        }
    }

    private func formatPrice(_ price: Double) -> String {
        if price >= 10000 {
            return String(format: "%.0fK", price / 1000)
        } else if price >= 1000 {
            return String(format: "%.1fK", price / 1000)
        } else {
            return String(format: "%.0f", price)
        }
    }
}

// MARK: - Rectangular View (Below Clock) - 3 Tickers!

struct RectangularLockScreenView: View {
    let entry: MarketEntry

    var body: some View {
        if entry.marketData.isEmpty || entry.marketData.first?.symbol == "---" {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("No Data")
                    .font(.caption2)
            }
        } else {
            VStack(spacing: 3) {
                // Header with market status
                HStack {
                    Text(isMarketOpen() ? "INDICES" : "FUTURES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Circle()
                        .fill(Color.green)
                        .frame(width: 4, height: 4)
                }

                // Three tickers in compact format
                ForEach(Array(entry.marketData.prefix(3)), id: \.symbol) { data in
                    LockScreenTickerRow(data: data)
                }
            }
        }
    }

    private func isMarketOpen() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday >= 2 && weekday <= 6 && hour >= 9 && hour < 16
    }
}

// MARK: - Ticker Row for Rectangular Widget

struct LockScreenTickerRow: View {
    let data: MarketData

    var body: some View {
        HStack(spacing: 4) {
            // Symbol
            Text(cleanSymbol(data.symbol))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(width: 35, alignment: .leading)

            // Price
            Text(formatPrice(data.price))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Change indicator and percent
            HStack(spacing: 1) {
                Image(systemName: data.isPositive ? "▲" : "▼")
                    .font(.system(size: 7))

                Text(String(format: "%.1f", abs(data.changePercent)))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(data.isPositive ? .green : .red)
            .frame(width: 30, alignment: .trailing)
        }
    }

    private func formatPrice(_ price: Double) -> String {
        if price >= 10000 {
            return String(format: "%.0f", price)
        } else if price >= 1000 {
            return String(format: "%.0f", price)
        } else {
            return String(format: "%.2f", price)
        }
    }

    private func cleanSymbol(_ symbol: String) -> String {
        return symbol
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ".X", with: "")
    }
}

// MARK: - Inline View (Merged with Clock)

struct InlineLockScreenView: View {
    let entry: MarketEntry

    var body: some View {
        if let data = entry.marketData.first {
            HStack(spacing: 4) {
                Text(cleanSymbol(data.symbol))
                    .font(.system(size: 13, weight: .bold))

                Text(formatPrice(data.price))
                    .font(.system(size: 13, weight: .semibold))

                Image(systemName: data.isPositive ? "▲" : "▼")
                    .font(.system(size: 8))

                Text(String(format: "%.1f%%", abs(data.changePercent)))
                    .font(.system(size: 12, weight: .medium))
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Market Data")
            }
        }
    }

    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "%.0f", price)
        } else {
            return String(format: "%.2f", price)
        }
    }

    private func cleanSymbol(_ symbol: String) -> String {
        return symbol
            .replacingOccurrences(of: "/", from: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ".X", with: "")
    }
}

// MARK: - Widget Bundle Update

@main
struct AllWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MarketWidget()           // Home screen widget
        MarketLockScreenWidget() // Lock screen widget
    }
}

// MARK: - Preview

struct LockScreenWidget_Previews: PreviewProvider {
    static var sampleData = [
        MarketData(
            symbol: "ES",
            price: 4789.25,
            change: 12.50,
            changePercent: 0.26,
            volume: nil,
            timestamp: Date(),
            high: nil,
            low: nil,
            marketStatus: "Open"
        ),
        MarketData(
            symbol: "NQ",
            price: 16823.75,
            change: 45.25,
            changePercent: 0.27,
            volume: nil,
            timestamp: Date(),
            high: nil,
            low: nil,
            marketStatus: "Open"
        ),
        MarketData(
            symbol: "YM",
            price: 37545.00,
            change: -23.00,
            changePercent: -0.06,
            volume: nil,
            timestamp: Date(),
            high: nil,
            low: nil,
            marketStatus: "Open"
        )
    ]

    static var entry = MarketEntry(date: Date(), marketData: sampleData)

    static var previews: some View {
        Group {
            LockScreenWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Circular")

            LockScreenWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Rectangular - 3 Tickers")

            LockScreenWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Inline")
        }
    }
}
