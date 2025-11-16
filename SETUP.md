# Setup Guide

This guide will help you set up your private market data widget for iPhone.

## Prerequisites

- Xcode 14.0 or later
- iOS 16.0 or later
- Apple Developer account (for running on physical device)
- Your private WebSocket API endpoint

## Step 1: Create Xcode Project

Since this is a template, you'll need to create a new Xcode project:

1. Open Xcode
2. Create a new **App** project
3. Set the following:
   - Product Name: `MarketWidget`
   - Team: Your development team
   - Organization Identifier: `com.yourcompany` (change this)
   - Interface: SwiftUI
   - Language: Swift
4. Save the project

## Step 2: Add Widget Extension

1. In Xcode, go to **File → New → Target**
2. Select **Widget Extension**
3. Set Product Name: `MarketWidgetExtension`
4. Uncheck "Include Configuration Intent"
5. Click Finish

## Step 3: Configure App Groups

Both the main app and widget need to share data via App Groups:

### For Main App:
1. Select the **MarketWidget** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Click **+** and create: `group.com.yourcompany.marketwidget`
   - Replace `com.yourcompany` with your actual organization identifier

### For Widget Extension:
1. Select the **MarketWidgetExtension** target
2. Repeat the same App Groups setup
3. Use the **exact same** App Group identifier

## Step 4: Copy Source Files

Copy the source files from this repository into your Xcode project:

### Shared Files (both targets):
- `Shared/Config.swift`
- `Shared/Models/MarketData.swift`
- `Shared/Utilities/KeychainHelper.swift`
- `Shared/Utilities/SharedDataStore.swift`
- `Shared/WebSocket/WebSocketManager.swift`

### Main App Files:
- `MarketWidget/MarketWidgetApp.swift`
- `MarketWidget/ViewModels/MarketViewModel.swift`
- `MarketWidget/Views/ContentView.swift`
- `MarketWidget/Views/SettingsView.swift`
- `MarketWidget/Info.plist` (merge with existing)
- `MarketWidget/MarketWidget.entitlements`

### Widget Extension Files:
- `MarketWidgetExtension/MarketWidgetExtension.swift`
- `MarketWidgetExtension/Info.plist` (merge with existing)
- `MarketWidgetExtension/MarketWidgetExtension.entitlements`

### Important: Add Files to Both Targets
For the Shared files, make sure they're added to **both** the app and widget extension targets:
1. Select each Shared file in Xcode
2. In the File Inspector (right panel), check both target boxes:
   - ☑ MarketWidget
   - ☑ MarketWidgetExtension

## Step 5: Update Configuration

Edit `Shared/Config.swift`:

```swift
// Update with your WebSocket URL
static let websocketURL = "wss://your-api.com/market-data"

// Update with your App Group identifier (must match entitlements)
static let appGroupIdentifier = "group.com.yourcompany.marketwidget"
```

Edit entitlement files if needed:
- `MarketWidget/MarketWidget.entitlements`
- `MarketWidgetExtension/MarketWidgetExtension.entitlements`

Update the App Group identifier in both files to match your configuration.

## Step 6: Update Bundle Identifiers

1. Select **MarketWidget** target → General
   - Bundle Identifier: `com.yourcompany.marketwidget`
2. Select **MarketWidgetExtension** target → General
   - Bundle Identifier: `com.yourcompany.marketwidget.extension`

## Step 7: Configure Background Modes (Optional)

To keep the WebSocket connection alive in the background:

1. Select **MarketWidget** target
2. Go to **Signing & Capabilities**
3. Add **Background Modes** capability
4. Enable:
   - ☑ Background fetch
   - ☑ Background processing

## Step 8: Build and Run

1. Select your device or simulator
2. Build and run the main app (⌘R)
3. The app will attempt to connect to your WebSocket
4. Add the widget to your home screen:
   - Long press on home screen
   - Tap **+** in top corner
   - Search for "Market Data"
   - Select widget size and add

## WebSocket Data Format

Your WebSocket should send JSON in one of these formats:

### Single Market Data:
```json
{
  "symbol": "AAPL",
  "price": 175.43,
  "change": 2.15,
  "change_percent": 1.24,
  "volume": 50123456,
  "timestamp": "2025-01-15T14:30:00Z",
  "high": 176.50,
  "low": 173.20,
  "market_status": "Open"
}
```

### Wrapped Message:
```json
{
  "type": "market_data",
  "payload": {
    "symbol": "AAPL",
    "price": 175.43,
    "change": 2.15,
    "change_percent": 1.24,
    "timestamp": "2025-01-15T14:30:00Z"
  }
}
```

### Array of Market Data:
```json
[
  {
    "symbol": "AAPL",
    "price": 175.43,
    "change": 2.15,
    "change_percent": 1.24,
    "timestamp": "2025-01-15T14:30:00Z"
  },
  {
    "symbol": "TSLA",
    "price": 242.84,
    "change": -5.23,
    "change_percent": -2.11,
    "timestamp": "2025-01-15T14:30:00Z"
  }
]
```

## Authentication

If your API requires authentication:

1. Open the app
2. Go to Settings (tap ••• in top right)
3. Enter your API key
4. Save settings
5. Restart the app

The API key is stored securely in Keychain and sent as a Bearer token:
```
Authorization: Bearer your-api-key-here
```

## Troubleshooting

### Widget shows "No Data"
- Open the main app to establish WebSocket connection
- Check that App Group identifiers match in Config.swift and entitlements
- Verify the app is receiving data (check Xcode console)

### WebSocket won't connect
- Verify your WebSocket URL in Config.swift
- Check network permissions
- Ensure your API is accessible from your device
- Check Xcode console for error messages

### App Groups not working
- Ensure both targets have the same App Group identifier
- Verify capabilities are properly configured in Xcode
- Clean build folder (⌘⇧K) and rebuild

### Widget not updating
- Widgets refresh based on timeline (default: 1 minute)
- iOS may throttle updates to save battery
- You can force reload by removing and re-adding the widget

## Development Tips

### Testing WebSocket Connection
Add a subscribe message after connection in `WebSocketManager.swift`:

```swift
func didConnect() {
    // Send subscribe message to your API
    let subscribeMsg = ["action": "subscribe", "symbols": ["AAPL", "TSLA"]]
    sendJSON(subscribeMsg)
}
```

### Viewing Logs
Run the app from Xcode and monitor the console for these messages:
- `🔌` Connection events
- `📊` Market data received
- `✅` Success messages
- `❌` Error messages

### Testing Widget
Use the widget preview in Xcode or test on device:
1. Build and run on device
2. Add widget to home screen
3. Data should appear within 1-2 minutes

## Next Steps

- Customize the UI colors and styling in the widget views
- Add more data fields specific to your market data
- Implement charts or sparklines for price history
- Add multiple symbol support with user configuration
- Set up push notifications for price alerts

## Security Notes

- This is a **private** widget for personal use
- API keys are stored in Keychain (encrypted)
- WebSocket URL is embedded in the app (not exposed)
- No external services or analytics
- All data stays on your device

## Support

For issues or questions:
1. Check the Xcode console for error messages
2. Verify your WebSocket API is working correctly
3. Review the troubleshooting section above
4. Check that all configuration steps were completed
