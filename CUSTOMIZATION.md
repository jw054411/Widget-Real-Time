# Customization Guide

This guide shows you how to customize the widget for your specific needs.

## Changing Widget Appearance

### Colors

Edit the widget views to change colors:

**MarketWidgetExtension/MarketWidgetExtension.swift**

```swift
// Change positive/negative colors
.foregroundColor(data.isPositive ? .green : .red)  // Change .green and .red

// Change background colors
.background(Color(.systemGray6))  // Change to your preferred color

// Add gradient backgrounds
.background(
    LinearGradient(
        gradient: Gradient(colors: [.blue, .purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
```

### Fonts and Sizing

```swift
// In any widget view, modify fonts:
Text(data.formattedPrice)
    .font(.system(size: 24, weight: .bold, design: .rounded))  // Custom font
    .foregroundColor(.primary)
```

### Widget Layout

Modify the layout in each widget size view:
- `SmallWidgetView` - Single item view
- `MediumWidgetView` - 2-item horizontal layout
- `LargeWidgetView` - 5-item vertical list

## Adding New Data Fields

### 1. Update MarketData Model

**Shared/Models/MarketData.swift**

```swift
struct MarketData: Codable, Equatable {
    // ... existing fields ...

    // Add your new fields:
    let bidPrice: Double?
    let askPrice: Double?
    let marketCap: Double?

    enum CodingKeys: String, CodingKey {
        // ... existing cases ...
        case bidPrice = "bid_price"
        case askPrice = "ask_price"
        case marketCap = "market_cap"
    }

    // Add formatted helpers:
    var formattedMarketCap: String {
        guard let cap = marketCap else { return "N/A" }
        return "$\(cap / 1_000_000_000, specifier: "%.2f")B"
    }
}
```

### 2. Display New Fields in Widget

**MarketWidgetExtension/MarketWidgetExtension.swift**

```swift
struct SmallWidgetView: View {
    // ... existing code ...

    var body: some View {
        VStack {
            // ... existing fields ...

            // Add your new field:
            if let marketCap = data.marketCap {
                Text(data.formattedMarketCap)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## Filtering Symbols

### Show Specific Symbols Only

**Shared/Utilities/SharedDataStore.swift**

```swift
class SharedDataStore {
    // Add a filter list
    static let allowedSymbols = ["AAPL", "TSLA", "GOOGL"]

    func saveMarketData(_ data: [MarketData]) {
        // Filter before saving
        let filtered = data.filter { allowedSymbols.contains($0.symbol) }

        // ... save filtered data ...
    }
}
```

### User-Configurable Symbol List

Add a settings option in **MarketWidget/Views/SettingsView.swift**:

```swift
struct SettingsView: View {
    @AppStorage("watchlist") private var watchlistString = "AAPL,TSLA,GOOGL"

    var body: some View {
        Form {
            Section(header: Text("Watchlist")) {
                TextField("Symbols (comma-separated)", text: $watchlistString)
            }
        }
    }
}
```

## WebSocket Message Customization

### Sending Subscribe Messages

**Shared/WebSocket/WebSocketManager.swift**

```swift
func didConnect() {
    print("✅ WebSocket connected")

    // Send custom subscribe message
    let subscribeMessage = [
        "action": "subscribe",
        "symbols": ["AAPL", "TSLA", "GOOGL"],
        "dataTypes": ["quote", "trade"]
    ]

    sendJSON(subscribeMessage)

    delegate?.didConnect()
}
```

### Handling Different Message Types

```swift
private func parseMarketData(from text: String) {
    // Add custom message type handling
    if text.contains("\"type\":\"heartbeat\"") {
        print("💓 Heartbeat received")
        return
    }

    if text.contains("\"type\":\"error\"") {
        handleError(text)
        return
    }

    // ... existing parsing logic ...
}

private func handleError(_ message: String) {
    print("❌ Server error: \(message)")
    delegate?.didReceiveError(
        NSError(domain: "API", code: -1, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    )
}
```

## Update Frequency

### Change Widget Refresh Rate

**Shared/Config.swift**

```swift
// Change from 1 minute to 30 seconds
static let widgetRefreshInterval: TimeInterval = 0.5  // 30 seconds

// Or 5 minutes
static let widgetRefreshInterval: TimeInterval = 5  // 5 minutes
```

**Note:** iOS may throttle updates regardless of your setting to preserve battery.

### Force Widget Updates

In **MarketWidget/ViewModels/MarketViewModel.swift**:

```swift
private func updateMarketData(with newData: MarketData) {
    // ... existing code ...

    // Force immediate widget reload
    WidgetCenter.shared.reloadAllTimelines()
}
```

## Adding Charts/Sparklines

### Using SF Symbols for Mini Charts

```swift
struct SmallWidgetView: View {
    var body: some View {
        VStack {
            // ... existing code ...

            // Simple trend indicator
            HStack(spacing: 2) {
                ForEach(0..<5) { _ in
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                }
            }
        }
    }
}
```

### Using SwiftUI Charts (iOS 16+)

Add to your view:

```swift
import Charts

struct PriceChart: View {
    let priceHistory: [Double]

    var body: some View {
        Chart {
            ForEach(Array(priceHistory.enumerated()), id: \.offset) { index, price in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Price", price)
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 40)
    }
}
```

## Supporting Multiple Data Sources

### Add Data Source Configuration

**Shared/Config.swift**

```swift
enum DataSource: String {
    case stocks = "wss://stocks-api.com/ws"
    case crypto = "wss://crypto-api.com/ws"
    case forex = "wss://forex-api.com/ws"
}

struct Config {
    static var currentDataSource: DataSource = .stocks

    static var websocketURL: String {
        currentDataSource.rawValue
    }
}
```

### Data Source Switcher in Settings

```swift
struct SettingsView: View {
    @AppStorage("dataSource") private var dataSource = "stocks"

    var body: some View {
        Form {
            Section(header: Text("Data Source")) {
                Picker("Source", selection: $dataSource) {
                    Text("Stocks").tag("stocks")
                    Text("Crypto").tag("crypto")
                    Text("Forex").tag("forex")
                }
            }
        }
    }
}
```

## Notifications

### Price Alerts

Add to **MarketWidget/ViewModels/MarketViewModel.swift**:

```swift
import UserNotifications

func didReceiveMarketData(_ data: MarketData) {
    // ... existing code ...

    // Check for price alerts
    checkPriceAlert(for: data)
}

private func checkPriceAlert(for data: MarketData) {
    let alertPrice = 180.0  // Example threshold

    if data.symbol == "AAPL" && data.price > alertPrice {
        sendNotification(
            title: "Price Alert",
            body: "\(data.symbol) is now \(data.formattedPrice)"
        )
    }
}

private func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
    )

    UNUserNotificationCenter.current().add(request)
}
```

## Dark Mode Support

Widgets automatically support dark mode, but you can customize:

```swift
struct SmallWidgetView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            // Custom colors based on color scheme
            Text(data.symbol)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}
```

## Persistence and Caching

### Add Historical Data Storage

Create a new file **Shared/Utilities/HistoricalDataStore.swift**:

```swift
class HistoricalDataStore {
    static let shared = HistoricalDataStore()

    private var priceHistory: [String: [Double]] = [:]

    func addPrice(symbol: String, price: Double) {
        var history = priceHistory[symbol] ?? []
        history.append(price)

        // Keep last 50 prices
        if history.count > 50 {
            history.removeFirst()
        }

        priceHistory[symbol] = history
    }

    func getHistory(for symbol: String) -> [Double] {
        priceHistory[symbol] ?? []
    }
}
```

## Testing

### Mock Data for Development

```swift
extension MarketData {
    static func mock(symbol: String = "AAPL", price: Double = 175.0) -> MarketData {
        MarketData(
            symbol: symbol,
            price: price,
            change: Double.random(in: -10...10),
            changePercent: Double.random(in: -5...5),
            volume: 50_000_000,
            timestamp: Date(),
            high: price + 5,
            low: price - 5,
            marketStatus: "Open"
        )
    }
}
```

Use in previews:

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MarketViewModel()
        viewModel.marketData = [
            .mock(symbol: "AAPL", price: 175.43),
            .mock(symbol: "TSLA", price: 242.84),
            .mock(symbol: "GOOGL", price: 140.25)
        ]

        return ContentView()
            .environmentObject(viewModel)
    }
}
```

## Performance Optimization

### Limit Update Frequency

```swift
class MarketViewModel: ObservableObject {
    private var lastUpdateTime: Date = .distantPast
    private let minimumUpdateInterval: TimeInterval = 1.0  // 1 second

    func didReceiveMarketData(_ data: MarketData) {
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) >= minimumUpdateInterval else {
            return  // Skip update if too frequent
        }

        lastUpdateTime = now
        updateMarketData(with: data)
    }
}
```

### Batch Updates

```swift
private var pendingUpdates: [MarketData] = []
private var updateTimer: Timer?

func didReceiveMarketData(_ data: MarketData) {
    pendingUpdates.append(data)

    // Batch update every 2 seconds
    updateTimer?.invalidate()
    updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
        self?.processPendingUpdates()
    }
}

private func processPendingUpdates() {
    pendingUpdates.forEach { updateMarketData(with: $0) }
    pendingUpdates.removeAll()
}
```

## Questions?

If you need help with a specific customization:
1. Check the inline code comments in the source files
2. Review Apple's WidgetKit documentation
3. Test changes using Xcode previews first
4. Use print statements to debug data flow
