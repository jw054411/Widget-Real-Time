# Lock Screen Widget Setup

Complete guide for adding market data to your iPhone lock screen.

## What You Get

The lock screen widget shows your **3 tickers** (ES, NQ, YM or SPX, NDX, DJI) right on your lock screen - no need to unlock your phone!

## Lock Screen Widget Styles

iOS offers three lock screen widget positions:

### 1. Rectangular (Below Clock) - **RECOMMENDED**
**Perfect for your 3-ticker display**

Shows all three markets at once:
```
INDICES         ●
SPX    4789   ▲ 0.5
NDX   16824   ▲ 0.3
DJI   37545   ▼ 0.1
```

### 2. Circular (Above Clock)
Shows single ticker in a circle:
```
  ┌─────┐
  │ ES  │
  │4789 │
  │▲0.5%│
  └─────┘
```

### 3. Inline (Merged with Clock)
Single line merged with the time:
```
2:30  ES 4789 ▲0.5%
```

## Setup Instructions

### Step 1: Add Lock Screen Widget Extension to Xcode

You need to create a separate widget extension for the lock screen:

1. Open your MarketWidget project in Xcode
2. **File → New → Target**
3. Select **Widget Extension**
4. Product Name: `MarketLockScreenWidget`
5. Uncheck "Include Configuration Intent"
6. Click **Finish**
7. Click **Activate** when asked about the scheme

### Step 2: Configure App Groups

The lock screen widget needs the same App Group as the main app:

1. Select **MarketLockScreenWidget** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Select the **SAME** App Group: `group.com.yourcompany.marketwidget`
   - Must match exactly with the main app!

### Step 3: Copy Source Files

Copy these files into the `MarketLockScreenWidget` folder:

**Required Files (add to BOTH app and widget targets):**
- `Shared/Config.swift`
- `Shared/Models/MarketData.swift`
- `Shared/Utilities/SharedDataStore.swift`
- `Shared/Utilities/KeychainHelper.swift`
- `Shared/Utilities/MarketHoursHelper.swift`

**Lock Screen Widget File:**
- `MarketLockScreenWidget/MarketLockScreenWidget.swift` (replace the default)
- `MarketLockScreenWidget/Info.plist` (merge with existing)

### Step 4: Update Widget Bundle

Replace the `@main` in your **original** `MarketWidgetExtension.swift` with just a struct:

```swift
// Remove the @main from MarketWidget
struct MarketWidget: Widget {
    // ... existing code ...
}
```

The `@main` is now in `MarketLockScreenWidget.swift` which bundles both widgets together.

### Step 5: Build and Run

1. Select **MarketLockScreenWidget** scheme in Xcode
2. Choose your iPhone (lock screen widgets don't work in simulator)
3. Press **⌘R** to build and run
4. The app will launch - connect to your WebSocket
5. Lock your phone

### Step 6: Add to Lock Screen

1. **Long press** on your lock screen (not home screen!)
2. Tap **Customize**
3. Tap **Lock Screen**
4. Tap the area **below the clock** (for rectangular widget)
5. Search for **"Market"**
6. Select the **rectangular widget** (shows 3 tickers)
7. Tap outside to save
8. **Done!**

### Alternative Positions

**Above the clock (circular):**
1. Long press lock screen → Customize
2. Tap one of the **circular slots above the clock**
3. Select Market → Circular widget
4. Shows 1 ticker

**Inline with clock:**
1. Long press lock screen → Customize
2. Tap the area **where the date shows**
3. Select Market → Inline widget
4. Shows 1 ticker in a single line

## What It Looks Like

### Rectangular (3 Tickers - Best Option)
```
╔═══════════════════════╗
║   3:45  Wednesday 15  ║
║                       ║
║   ┌─────────────────┐ ║
║   │ FUTURES      ● │ ║
║   │ ES   4789  ▲0.5│ ║
║   │ NQ  16824  ▲0.3│ ║
║   │ YM  37545  ▼0.1│ ║
║   └─────────────────┘ ║
║                       ║
║      [Face ID Icon]   ║
╚═══════════════════════╝
```

### During Market Hours
Widget automatically switches:
```
╔═══════════════════════╗
║   ┌─────────────────┐ ║
║   │ INDICES      ● │ ║
║   │ SPX  4789  ▲0.5│ ║
║   │ NDX 16824  ▲0.3│ ║
║   │ DJI 37545  ▼0.1│ ║
║   └─────────────────┘ ║
╚═══════════════════════╝
```

## Update Frequency

**Important:** Lock screen widgets update differently than home screen widgets:

- **When locked:** Updates every 5-15 minutes (iOS controlled)
- **When unlocked:** Updates more frequently
- **Best practice:** Open the app once to establish WebSocket connection, then the lock screen widget will receive updates

To force an update:
1. Unlock phone
2. Open the Market Widget app briefly
3. Lock phone again
4. Widget will refresh within a minute

## Customizing the Lock Screen Widget

### Change Number of Tickers

In `RectangularLockScreenView`, change:
```swift
ForEach(Array(entry.marketData.prefix(3)), id: \.symbol) { data in
    // Change 3 to show different number
}
```

### Change Font Sizes

```swift
Text(data.symbol)
    .font(.system(size: 11, weight: .bold))  // Adjust size here
```

### Change Colors

```swift
.foregroundColor(data.isPositive ? .green : .red)  // Change colors
```

### Show Different Data

Edit the symbols in `MarketHoursHelper.swift`:
```swift
func getCurrentSymbols() -> [String] {
    if isMarketOpen() {
        return ["$SPX.X", "$NDX.X", "$DJI"]  // Your indices
    } else {
        return ["/ES", "/NQ", "/YM"]  // Your futures
    }
}
```

## Troubleshooting

### Widget shows "No Data"
- Open the main app and ensure it's connected
- Check that App Group identifier matches in all targets
- Wait 1-2 minutes for data to sync
- Remove and re-add the widget

### Widget not updating
- Lock screen widgets update less frequently than home screen
- iOS throttles updates to save battery
- Keep main app running in background
- Toggle Low Power Mode off (it reduces update frequency)

### Can't find widget when customizing
- Make sure you built for a physical iPhone (not simulator)
- Ensure the widget extension target was installed
- Try restarting your iPhone
- Check that the extension is enabled in Settings

### Colors look wrong
- Lock screen widgets adapt to wallpaper
- Use high contrast wallpapers for better visibility
- Widget colors may appear tinted based on wallpaper

### Size too small/large
- Lock screen widget sizes are fixed by iOS
- You cannot resize them
- Use rectangular for maximum information (3 tickers)

## Best Practices

1. **Use rectangular widget** - Shows all 3 tickers at once
2. **Keep app running** - Better update frequency
3. **Choose contrasting wallpaper** - Improves widget readability
4. **Check during market hours** - Verify it switches from futures to indices
5. **Don't rely on instant updates** - Lock screen updates are delayed for battery

## Battery Impact

Lock screen widgets are designed to be battery-efficient:
- Updates are throttled by iOS
- No constant background processing
- WebSocket only runs when app is active
- Shared data store is very lightweight

Expected battery impact: **Less than 1% per day**

## Multiple Lock Screens

iOS lets you create multiple lock screens with different widgets:

1. Long press lock screen
2. Tap **+** to create new lock screen
3. Add Market widget to multiple screens
4. Swipe between lock screens

Example setups:
- **Lock Screen 1:** 3 futures (ES, NQ, YM)
- **Lock Screen 2:** 3 indices (SPX, NDX, DJI)
- **Lock Screen 3:** Commodities (GC, CL, NG)

## Advanced: Multiple Widget Configurations

You can show different data in different lock screen positions by modifying the timeline provider logic in `MarketLockScreenWidget.swift`.

## Questions?

- Widget not showing? Check SETUP.md
- Want different symbols? See CUSTOMIZATION.md
- API integration? Read API-INTEGRATION.md
- General questions? Check QUICK-START.md

Enjoy your real-time market data right on your lock screen! 📱📊
