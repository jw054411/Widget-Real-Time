# Offline Testing Guide

Test your widget **completely offline** without any WebSocket server!

## The Problem

When testing with a WebSocket server on your Mac:
- ❌ Mac must be online and awake
- ❌ iPhone must be on same WiFi
- ❌ If Mac goes offline, no new data
- ❌ Can't test on the go

## The Solution: Mock Data Mode

I've built in a **mock data generator** that works **completely offline**!

## How It Works

1. Enable mock data mode in `Config.swift`
2. App generates realistic market data locally on your iPhone
3. Data updates every 3 seconds (configurable)
4. **No internet connection needed!**
5. Widget shows the mock data just like real data

## Setup

### Step 1: Enable Mock Data Mode

Edit `Shared/Config.swift`:

```swift
struct Config {
    // Set this to TRUE for offline testing
    static let useMockData = true  // ✅ Offline mode

    // Set to FALSE when ready for real data
    // static let useMockData = false  // Real WebSocket mode

    // How often mock data updates (seconds)
    static let mockDataInterval: TimeInterval = 3.0
}
```

### Step 2: Build and Run

1. Build the app in Xcode (⌘R)
2. App opens and shows "Mock Data Mode"
3. You'll see 3 tickers with updating prices
4. **Turn off WiFi** - it still works!
5. **Put Mac to sleep** - still works!
6. **Take iPhone anywhere** - still works!

### Step 3: Add Widget

1. Long press home screen
2. Add Market Data widget
3. Widget shows mock data
4. Data updates automatically

## What You'll See

### In the App

```
┌─────────────────────┐
│ Mock Data Mode    ● │ ← Green dot = "connected"
│ Updated: 2s ago     │
├─────────────────────┤
│ ES      4789.25     │
│         ▲ +0.45%    │
├─────────────────────┤
│ NQ     16823.75     │
│         ▲ +0.32%    │
├─────────────────────┤
│ YM     37545.00     │
│         ▼ -0.12%    │
└─────────────────────┘
```

### In the Widget

The widget looks **exactly the same** as with real data:

```
FUTURES         ●
ES    4789   ▲ 0.5
NQ   16824   ▲ 0.3
YM   37545   ▼ 0.1
```

### On Lock Screen

Same as real data - shows 3 tickers with live updates!

## How Mock Data Works

### Realistic Price Movement

The mock data generator:
- Starts with realistic base prices
- Adds random movement (-1% to +1%)
- Updates the base price each time (creates trends)
- Generates volume, high/low prices
- Switches between futures and indices based on time

### Example Price Movement Over Time

```
Time    ES Price    Change
3:00    4789.25    +0.45%
3:03    4792.15    +0.61%  ← Trending up
3:06    4791.50    +0.47%
3:09    4788.75    -0.06%  ← Starting to drop
3:12    4785.25    -0.48%
```

### Auto-Switching

Just like real data:
- **9:30 AM - 4:00 PM** (weekdays): Shows SPX, NDX, DJI
- **After hours / weekends**: Shows /ES, /NQ, /YM

## Customizing Mock Data

### Change Update Frequency

In `Config.swift`:
```swift
static let mockDataInterval: TimeInterval = 5.0  // Update every 5 seconds
```

### Change Base Prices

Edit `MockDataGenerator.swift`:
```swift
private var basePrices: [String: Double] = [
    "/ES": 5000.00,  // Change to whatever you want
    "/NQ": 17000.00,
    "/YM": 38000.00,
]
```

### Change Price Movement Range

In `MockDataGenerator.swift`:
```swift
// Current: -1% to +1%
let changePercent = Double.random(in: -1.0...1.0)

// More volatile: -5% to +5%
let changePercent = Double.random(in: -5.0...5.0)

// Less volatile: -0.1% to +0.1%
let changePercent = Double.random(in: -0.1...0.1)
```

### Add More Symbols

In `MockDataGenerator.swift`:
```swift
private var basePrices: [String: Double] = [
    "/ES": 4789.25,
    "/NQ": 16823.75,
    "/YM": 37545.00,
    "/GC": 2045.50,  // Add gold
    "/CL": 72.35,    // Add crude oil
]
```

Then update `MarketHoursHelper.swift`:
```swift
func getFuturesSymbols() -> [String] {
    return ["/ES", "/NQ", "/YM", "/GC", "/CL"]  // Add your symbols
}
```

## Switching Between Mock and Real Data

### Development Workflow

**Phase 1: Build the UI (Mock Data)**
```swift
static let useMockData = true
```
- Test widget layouts
- Test all sizes (small, medium, large, lock screen)
- Verify auto-switching futures/indices
- Test on airplane mode

**Phase 2: Test Local WebSocket (Mac Required)**
```swift
static let useMockData = false
static let websocketURL = "ws://192.168.1.100:8080"
```
- Run `node Examples/test-websocket-server.js`
- Test real WebSocket connection
- Test reconnection logic
- Verify data parsing

**Phase 3: Production (Real API)**
```swift
static let useMockData = false
static let websocketURL = "wss://streamer-api.schwab.com/"
```
- Connect to real broker API
- Use real market data
- Deploy to your iPhone

### Quick Toggle

For quick testing, you can toggle in code:
```swift
// MarketViewModel.swift - in connect() function
func connect() {
    // Force mock data for this session
    let useMock = true  // Change this for quick testing

    if useMock || Config.useMockData {
        startMockDataMode()
    } else {
        webSocketManager.connect()
    }
}
```

## Testing Scenarios

### Test Lock Screen Widget
1. Enable mock data
2. Build and run
3. Lock your iPhone
4. Add widget to lock screen
5. Watch it update every 3 seconds
6. **Works completely offline!**

### Test Market Hours Switching
1. Enable mock data
2. Change your iPhone time to 10:00 AM (weekday)
3. Widget shows: SPX, NDX, DJI
4. Change time to 6:00 PM
5. Widget shows: /ES, /NQ, /YM

### Test Airplane Mode
1. Enable mock data
2. Build and run
3. **Turn on Airplane Mode**
4. Widget still updates!
5. Lock screen widget still works!

### Test Widget Refresh
1. Enable mock data
2. Add widget to home screen
3. Watch it update
4. Force close the app
5. Widget shows last known data
6. Open app again
7. Widget starts updating again

## Advantages of Mock Data

✅ **No internet required**
✅ **No WebSocket server needed**
✅ **Works on airplane**
✅ **Test anywhere, anytime**
✅ **Faster development**
✅ **Predictable data**
✅ **No API costs**
✅ **No rate limits**

## Limitations

⚠️ **Not real market data** (obviously)
⚠️ **Random price movement** (not based on actual market)
⚠️ **Can't test API authentication**
⚠️ **Can't test network issues**

## When to Use Each Mode

| Mode | Use When |
|------|----------|
| **Mock Data** | Building UI, testing layouts, offline dev, presentations |
| **Local WebSocket** | Testing WebSocket logic, testing reconnection, API integration dev |
| **Real API** | Production use, real trading decisions, accurate data needed |

## Troubleshooting

### Mock data not updating
- Check `Config.useMockData` is `true`
- Verify app is running (not force closed)
- Check console for "🎭 Starting MOCK DATA mode"

### Widget shows old data
- Open the app to trigger updates
- Check widget refresh interval
- Remove and re-add widget

### Want faster/slower updates
- Change `Config.mockDataInterval`
- Minimum: 1 second
- Maximum: whatever you want

### Prices too volatile
- Adjust the range in `MockDataGenerator.swift`
- Reduce from `(-1.0...1.0)` to `(-0.5...0.5)`

## Pro Tips

1. **Use mock data for all UI development** - Much faster than waiting for real data
2. **Test with extreme prices** - Set base price to 99999 to test number formatting
3. **Test negative prices** - Set base to -100 to test how widget handles it
4. **Test zero** - Set base to 0 to test edge cases
5. **Demo mode** - Great for screenshots and presentations

## Next Steps

1. ✅ Start with mock data
2. ✅ Build and test all widget sizes
3. ✅ Test on lock screen
4. ✅ Verify market hours switching
5. ⬜ Move to local WebSocket testing
6. ⬜ Finally, connect to real API

## Summary

**Mock data mode lets you build and test your widget completely offline!**

Perfect for:
- Development
- Testing
- Presentations
- Airplane mode
- When your Mac is asleep
- When you're away from home WiFi

Just set `useMockData = true` and you're good to go! 🎭📱
