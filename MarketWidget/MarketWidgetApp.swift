//
//  MarketWidgetApp.swift
//  MarketWidget
//
//  Main app entry point
//

import SwiftUI
import WidgetKit

@main
struct MarketWidgetApp: App {
    @StateObject private var marketViewModel = MarketViewModel()

    init() {
        // Configure app on launch
        print("🚀 Market Widget App Launching")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(marketViewModel)
                .onAppear {
                    // Connect to WebSocket when app appears
                    marketViewModel.connect()
                }
                .onDisappear {
                    // Optionally disconnect when app goes to background
                    // Commented out to keep connection alive in background
                    // marketViewModel.disconnect()
                }
        }
    }
}
