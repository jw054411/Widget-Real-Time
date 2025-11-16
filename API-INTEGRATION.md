# API Integration Guide

Guide for integrating with major brokerage APIs for real-time market data.

## Overview

This widget can connect to:
- **Charles Schwab API** (formerly TD Ameritrade)
- **Tastytrade API**
- **E*TRADE API**

All three support both REST and WebSocket streaming for real-time data.

## Charles Schwab API

### Getting Started

1. Register at [Schwab Developer Portal](https://developer.schwab.com/)
2. Create an app to get API keys
3. Set up OAuth2 authentication

### WebSocket Streaming

Schwab provides streaming market data via WebSocket:

**Endpoint:** `wss://streamer-api.schwab.com/`

**Authentication:** OAuth2 token required

### Update Config.swift

```swift
struct Config {
    static let websocketURL = "wss://streamer-api.schwab.com/"

    // Schwab credentials (stored in Keychain)
    static var schwabClientId: String? {
        get { KeychainHelper.shared.get(key: "schwab_client_id") }
        set {
            if let value = newValue {
                KeychainHelper.shared.save(key: "schwab_client_id", value: value)
            }
        }
    }

    static var schwabAccessToken: String? {
        get { KeychainHelper.shared.get(key: "schwab_access_token") }
        set {
            if let value = newValue {
                KeychainHelper.shared.save(key: "schwab_access_token", value: value)
            }
        }
    }
}
```

### Subscribe to Market Data

In `WebSocketManager.swift`, update the connection logic:

```swift
func didConnect() {
    print("✅ WebSocket connected")

    // Subscribe to futures (after hours)
    let futuresSubscribe = [
        "requests": [
            [
                "service": "LEVELONE_FUTURES",
                "requestid": "1",
                "command": "SUBS",
                "account": Config.schwabAccountId ?? "",
                "source": Config.schwabClientId ?? "",
                "parameters": [
                    "keys": "/ES,/NQ,/YM",  // E-mini S&P, Nasdaq, Dow
                    "fields": "0,1,2,3,4,5,6,7,8"
                ]
            ]
        ]
    ]

    // Subscribe to indices (market hours)
    let indicesSubscribe = [
        "requests": [
            [
                "service": "QUOTE",
                "requestid": "2",
                "command": "SUBS",
                "account": Config.schwabAccountId ?? "",
                "source": Config.schwabClientId ?? "",
                "parameters": [
                    "keys": "$SPX.X,$NDX.X,$DJI",  // S&P 500, Nasdaq 100, Dow Jones
                    "fields": "0,1,2,3,4,5,6,7,8,9,10,11,12,13"
                ]
            ]
        ]
    ]

    // Determine which to subscribe to based on market hours
    let subscribeMessage = isMarketOpen() ? indicesSubscribe : futuresSubscribe

    sendJSON(subscribeMessage)

    delegate?.didConnect()
}

private func isMarketOpen() -> Bool {
    let calendar = Calendar.current
    let now = Date()
    let hour = calendar.component(.hour, from: now)
    let weekday = calendar.component(.weekday, from: now)

    // Market hours: Mon-Fri, 9:30 AM - 4:00 PM ET
    // Weekday: 2-6 (Mon-Fri), Hour: 9-16 (simplified, adjust for timezone)
    return weekday >= 2 && weekday <= 6 && hour >= 9 && hour < 16
}
```

### Parse Schwab Response

Update `parseMarketData` in `WebSocketManager.swift`:

```swift
private func parseMarketData(from text: String) {
    guard let data = text.data(using: .utf8) else { return }

    do {
        let decoder = JSONDecoder()

        // Schwab sends data in their specific format
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let response = json["response"] as? [[String: Any]] {

            for item in response {
                if let service = item["service"] as? String,
                   (service == "LEVELONE_FUTURES" || service == "QUOTE"),
                   let content = item["content"] as? [[String: Any]] {

                    for quoteData in content {
                        if let marketData = parseSchwabQuote(quoteData) {
                            handleMarketData(marketData)
                        }
                    }
                }
            }
        }
    } catch {
        print("❌ JSON parsing error: \(error)")
    }
}

private func parseSchwabQuote(_ data: [String: Any]) -> MarketData? {
    guard let symbol = data["key"] as? String else { return nil }

    // Field mappings for Schwab
    let price = data["1"] as? Double ?? 0.0  // Last price
    let change = data["2"] as? Double ?? 0.0  // Net change
    let changePercent = data["3"] as? Double ?? 0.0  // Percent change
    let volume = data["8"] as? Double  // Total volume
    let high = data["4"] as? Double  // High price
    let low = data["5"] as? Double  // Low price

    return MarketData(
        symbol: cleanSymbol(symbol),
        price: price,
        change: change,
        changePercent: changePercent,
        volume: volume,
        timestamp: Date(),
        high: high,
        low: low,
        marketStatus: isMarketOpen() ? "Open" : "Closed"
    )
}

private func cleanSymbol(_ symbol: String) -> String {
    // Remove futures prefix or index suffix
    return symbol.replacingOccurrences(of: "/", with: "")
                 .replacingOccurrences(of: ".X", with: "")
                 .replacingOccurrences(of: "$", with: "")
}
```

## Tastytrade API

### Getting Started

1. Sign up at [Tastytrade Developer](https://developer.tastytrade.com/)
2. Get API credentials
3. Tastytrade uses simpler authentication

### WebSocket Streaming

**Endpoint:** `wss://streamer.tastytrade.com/`

### Update for Tastytrade

```swift
struct Config {
    static let websocketURL = "wss://streamer.tastytrade.com/"

    // Tastytrade uses session token
    static var tastytradeSessionToken: String? {
        get { KeychainHelper.shared.get(key: "tastytrade_session_token") }
        set {
            if let value = newValue {
                KeychainHelper.shared.save(key: "tastytrade_session_token", value: value)
            }
        }
    }
}
```

### Subscribe to Market Data

```swift
func didConnect() {
    print("✅ WebSocket connected to Tastytrade")

    let subscribeMessage: [String: Any] = [
        "action": "subscribe",
        "value": isMarketOpen()
            ? ["$SPX", "$NDX", "$DJI"]  // Indices during market hours
            : ["/ES", "/NQ", "/YM"],    // Futures after hours
        "channel": "quote"
    ]

    sendJSON(subscribeMessage)
}
```

### Parse Tastytrade Response

```swift
private func parseMarketData(from text: String) {
    guard let data = text.data(using: .utf8) else { return }

    do {
        let decoder = JSONDecoder()

        // Tastytrade sends simpler JSON structure
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let quotes = json["data"] as? [[String: Any]] {

            for quote in quotes {
                if let marketData = parseTastytradeQuote(quote) {
                    handleMarketData(marketData)
                }
            }
        }
    } catch {
        print("❌ JSON parsing error: \(error)")
    }
}

private func parseTastytradeQuote(_ data: [String: Any]) -> MarketData? {
    guard let symbol = data["symbol"] as? String else { return nil }

    let price = data["last"] as? Double ?? 0.0
    let change = data["change"] as? Double ?? 0.0
    let changePercent = data["change_percent"] as? Double ?? 0.0
    let volume = data["volume"] as? Double
    let high = data["high"] as? Double
    let low = data["low"] as? Double

    return MarketData(
        symbol: symbol,
        price: price,
        change: change,
        changePercent: changePercent,
        volume: volume,
        timestamp: Date(),
        high: high,
        low: low,
        marketStatus: isMarketOpen() ? "Open" : "Closed"
    )
}
```

## E*TRADE API

### Getting Started

1. Register at [E*TRADE Developer](https://developer.etrade.com/)
2. Create application for API keys
3. E*TRADE uses OAuth 1.0a

### WebSocket Streaming

**Note:** E*TRADE doesn't have native WebSocket support. You'll need to:
1. Use their REST API with polling, or
2. Set up a proxy server that converts REST to WebSocket

### Alternative: REST API with Background Refresh

```swift
// In MarketViewModel.swift
class MarketViewModel: ObservableObject {
    private var refreshTimer: Timer?

    func startPolling() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchMarketData()
        }
    }

    private func fetchMarketData() {
        let symbols = isMarketOpen() ? ["$SPX", "$NDX", "$DJI"] : ["/ES", "/NQ", "/YM"]

        // Make REST API call to E*TRADE
        let url = URL(string: "https://api.etrade.com/v1/market/quote/\(symbols.joined(separator: ","))")!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(Config.etradeAccessToken ?? "")", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle response...
        }.resume()
    }
}
```

## Recommended Symbols

### Futures (After Hours)
- `/ES` - E-mini S&P 500
- `/NQ` - E-mini Nasdaq 100
- `/YM` - E-mini Dow Jones
- `/RTY` - E-mini Russell 2000
- `/GC` - Gold futures
- `/CL` - Crude Oil futures

### Indices (Market Hours)
- `$SPX.X` or `$SPX` - S&P 500 Index
- `$NDX.X` or `$NDX` - Nasdaq 100 Index
- `$DJI` - Dow Jones Industrial Average
- `$RUT.X` - Russell 2000 Index
- `$VIX.X` - Volatility Index

## Lock Screen Widget

For lock screen widgets (iOS 16+), create a new widget target:

1. File → New → Target → Widget Extension
2. Name it `MarketLockScreenWidget`
3. Use `.accessoryCircular` or `.accessoryRectangular` families

### Lock Screen Widget Code

```swift
struct MarketLockScreenWidget: Widget {
    let kind: String = "MarketLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MarketTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Market")
        .description("Quick market data")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: MarketEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        default:
            EmptyView()
        }
    }
}

struct CircularLockScreenView: View {
    let entry: MarketEntry

    var body: some View {
        if let data = entry.marketData.first {
            VStack(spacing: 2) {
                Text(data.symbol)
                    .font(.caption2)
                    .fontWeight(.bold)

                Text(data.formattedPrice)
                    .font(.caption)
            }
        }
    }
}

struct RectangularLockScreenView: View {
    let entry: MarketEntry

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(entry.marketData.prefix(3)), id: \.symbol) { data in
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.symbol)
                        .font(.caption2)
                        .fontWeight(.bold)

                    Text(String(format: "%.0f", data.price))
                        .font(.caption)
                }
            }
        }
    }
}
```

## Authentication Flow

For production use with real broker APIs:

1. Create a login screen in your app
2. Handle OAuth flow
3. Store access token in Keychain
4. Refresh token when expired

### Example OAuth Setup

```swift
// In MarketWidget/Views/LoginView.swift
struct LoginView: View {
    @State private var isAuthenticating = false

    var body: some View {
        VStack {
            Button("Login with Schwab") {
                authenticateWithSchwab()
            }

            Button("Login with Tastytrade") {
                authenticateWithTastytrade()
            }
        }
    }

    func authenticateWithSchwab() {
        // Implement OAuth flow
        // Use ASWebAuthenticationSession for OAuth
    }
}
```

## Testing Without Real API

Use the included test servers in `Examples/`:
- `test-websocket-server.js` (Node.js)
- `test-websocket-server.py` (Python)

These simulate market data for development.

## Next Steps

1. Choose your broker API (Schwab, Tastytrade, or E*TRADE)
2. Register for API access
3. Update Config.swift with appropriate endpoints
4. Implement authentication
5. Test with mock data first
6. Connect to real API

## Rate Limits

Be aware of API rate limits:
- **Schwab**: 120 requests/minute
- **Tastytrade**: Check their docs
- **E*TRADE**: 2 requests/second

The WebSocket streaming approach avoids these limits for real-time data.
