# Quick Start Guide

Get your real-time market widget up and running in 10 minutes.

## Your Use Case

- Show **3 tickers** in a compact widget
- Display **futures** during off-hours (/ES, /NQ, /YM)
- Display **indices** during market hours (SPX, NDX, DJI)
- Real-time updates via WebSocket
- Works on **lock screen** and home screen

## Step 1: Choose Your Broker API

Pick the broker you have an account with:

### Option A: Charles Schwab (Recommended)
- ✅ Best streaming data
- ✅ Free for account holders
- ✅ Supports futures and indices
- [Register here](https://developer.schwab.com/)

### Option B: Tastytrade
- ✅ Simpler API
- ✅ Good for futures trading
- ✅ Fast streaming
- [Register here](https://developer.tastytrade.com/)

### Option C: E*TRADE
- ⚠️ No WebSocket (requires polling)
- ✅ Good REST API
- [Register here](https://developer.etrade.com/)

## Step 2: Test with Mock Data First

Before connecting to real APIs, test with the included mock server:

```bash
# Install Node.js if you don't have it
# Then run:
cd Examples/
node test-websocket-server.js
```

Find your computer's local IP:
```bash
# On Mac/Linux:
ifconfig | grep "inet "

# On Windows:
ipconfig
```

## Step 3: Configure the App

Edit `Shared/Config.swift`:

```swift
struct Config {
    // For testing with mock server:
    static let websocketURL = "ws://YOUR_LOCAL_IP:8080"

    // For production (Schwab example):
    // static let websocketURL = "wss://streamer-api.schwab.com/"

    static let appGroupIdentifier = "group.com.YOURNAME.marketwidget"
}
```

## Step 4: Create Xcode Project

1. Open Xcode
2. Create new App project
3. Product Name: `MarketWidget`
4. Organization Identifier: Use your Apple ID (e.g., `com.johnsmith`)
5. Click Create

## Step 5: Add Widget Extension

1. In Xcode: File → New → Target
2. Choose "Widget Extension"
3. Name: `MarketWidgetExtension`
4. Uncheck "Include Configuration Intent"
5. Click Finish

## Step 6: Set Up App Groups

### Main App:
1. Select "MarketWidget" target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "App Groups"
5. Click "+" and create: `group.com.YOURNAME.marketwidget`

### Widget Extension:
1. Select "MarketWidgetExtension" target
2. Repeat same App Groups setup
3. Use SAME group identifier

## Step 7: Copy Source Files

Drag all these folders into your Xcode project:
- `Shared/` folder
- `MarketWidget/` folder (merge with existing)
- `MarketWidgetExtension/` folder (merge with existing)

**Important:** When adding `Shared/` files, check BOTH targets:
- ☑ MarketWidget
- ☑ MarketWidgetExtension

## Step 8: Build and Run

1. Select your iPhone (or simulator)
2. Press ⌘R to build and run
3. App should launch and show "Disconnected"
4. If using mock server, it should connect automatically
5. Widget will show "No Data" until app connects

## Step 9: Add Widget to Home Screen

1. Long press on home screen
2. Tap "+" in top left corner
3. Search for "Market Data"
4. Choose widget size:
   - **Small** - 1 ticker, compact
   - **Medium** - 2 tickers side-by-side
   - **Large** - 5 tickers vertical list
5. Tap "Add Widget"

## Step 10: Add to Lock Screen (iOS 16+)

1. Long press on lock screen
2. Tap "Customize"
3. Tap area below the clock
4. Search for "Market"
5. Add rectangular widget (shows 3 tickers)

## Optimized 3-Ticker Widget

I've created an optimized version for exactly 3 tickers. Create this file:

`MarketWidgetExtension/CompactThreeTickerWidget.swift`:

```swift
import WidgetKit
import SwiftUI

struct CompactThreeTickerView: View {
    let entry: MarketEntry

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(isMarketOpen() ? "INDICES" : "FUTURES")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()

                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Three Tickers
            VStack(spacing: 6) {
                ForEach(Array(entry.marketData.prefix(3)), id: \.symbol) { data in
                    CompactTickerRow(data: data)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }

    private func isMarketOpen() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday >= 2 && weekday <= 6 && hour >= 9 && hour < 16
    }
}

struct CompactTickerRow: View {
    let data: MarketData

    var body: some View {
        HStack(spacing: 8) {
            // Symbol
            Text(data.symbol)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 50, alignment: .leading)

            // Price
            Text(String(format: "%.0f", data.price))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Change
            HStack(spacing: 2) {
                Image(systemName: data.isPositive ? "▲" : "▼")
                    .font(.system(size: 8))

                Text(String(format: "%.2f", abs(data.changePercent)))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
            .foregroundColor(data.isPositive ? .green : .red)
            .frame(width: 50, alignment: .trailing)
        }
    }
}
```

Then update `MarketWidgetExtension.swift` to use this view for medium widgets:

```swift
case .systemMedium:
    CompactThreeTickerView(entry: entry)
```

## What You'll See

### During Market Hours (9:30 AM - 4:00 PM ET, Mon-Fri):
```
INDICES     ●

SPX    4,789   ▲ 0.45
NDX   16,823   ▲ 0.82
DJI   37,545   ▼ 0.12
```

### After Hours / Weekends:
```
FUTURES     ●

ES     4,792   ▲ 0.23
NQ    16,830   ▲ 0.51
YM    37,551   ▼ 0.08
```

## Customizing Symbols

Edit `WebSocketManager.swift` in the `didConnect()` function:

```swift
func didConnect() {
    let symbols: [String]

    if isMarketOpen() {
        // Market hours - show indices
        symbols = ["$SPX", "$NDX", "$DJI"]
    } else {
        // After hours - show futures
        symbols = ["/ES", "/NQ", "/YM"]
    }

    // Subscribe to symbols...
}
```

## Troubleshooting

### Widget shows "No Data"
1. Open the main app
2. Check that it says "Connected" at the top
3. Wait 30 seconds for data to flow
4. Remove and re-add widget

### Can't connect to WebSocket
1. Check your WiFi/cellular connection
2. Verify WebSocket URL in Config.swift
3. Check Xcode console for error messages
4. Make sure mock server is running (if testing locally)

### App crashes when opening
1. Clean build folder: ⌘⇧K
2. Delete app from device
3. Rebuild and reinstall

### Widget not updating
1. iOS throttles widget updates to save battery
2. Maximum update frequency is ~15 minutes in practice
3. For more frequent updates, keep app open in background

## Moving to Production

Once testing works:

1. Stop mock server
2. Register with your chosen broker API
3. Get API credentials
4. Update `Config.swift` with production WebSocket URL
5. Implement authentication (see API-INTEGRATION.md)
6. Test with real data
7. Deploy to your iPhone

## Performance Tips

- Widget updates are limited by iOS to preserve battery
- Keep the app running in background for more frequent updates
- Use Low Power Mode sparingly (reduces update frequency)
- Lock screen widgets update more frequently than home screen

## Security Reminders

- Never commit API keys to git
- Use Keychain for all credentials
- This app is for personal use only
- Don't share your API keys with anyone

## Next Steps

1. ✅ Get mock data working
2. ✅ Test all three widget sizes
3. ✅ Add to lock screen
4. ⬜ Register for broker API access
5. ⬜ Implement OAuth authentication
6. ⬜ Connect to real market data
7. ⬜ Customize colors and fonts
8. ⬜ Add price alerts (optional)

## Questions?

- Check SETUP.md for detailed instructions
- See API-INTEGRATION.md for broker-specific guides
- Review CUSTOMIZATION.md for appearance changes
- Read inline code comments for technical details

## Estimated Timeline

- **Mock data setup**: 10 minutes
- **Xcode project setup**: 15 minutes
- **Testing and tweaking**: 30 minutes
- **Broker API registration**: 1-2 days (approval time)
- **Production deployment**: 30 minutes

Total: ~1 hour + API approval wait time

Let's get your real-time market data flowing! 📊📱
