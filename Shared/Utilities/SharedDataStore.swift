//
//  SharedDataStore.swift
//  MarketWidget
//
//  Manages data sharing between app and widget via App Groups
//

import Foundation

class SharedDataStore {
    static let shared = SharedDataStore()

    private let userDefaults: UserDefaults?
    private let marketDataKey = "latest_market_data"
    private let lastUpdateKey = "last_update_timestamp"

    private init() {
        userDefaults = UserDefaults(suiteName: Config.appGroupIdentifier)
    }

    /// Save market data to shared storage
    func saveMarketData(_ data: [MarketData]) {
        guard let userDefaults = userDefaults else {
            print("❌ App Group UserDefaults not available")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: marketDataKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)

            print("✅ Saved \(data.count) market data items to shared storage")
        } catch {
            print("❌ Failed to encode market data: \(error)")
        }
    }

    /// Load market data from shared storage
    func loadMarketData() -> [MarketData]? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: marketDataKey) else {
            print("⚠️ No market data found in shared storage")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let marketData = try decoder.decode([MarketData].self, from: data)
            print("✅ Loaded \(marketData.count) market data items from shared storage")
            return marketData
        } catch {
            print("❌ Failed to decode market data: \(error)")
            return nil
        }
    }

    /// Get timestamp of last update
    var lastUpdateTime: Date? {
        userDefaults?.object(forKey: lastUpdateKey) as? Date
    }

    /// Clear all stored data
    func clearData() {
        userDefaults?.removeObject(forKey: marketDataKey)
        userDefaults?.removeObject(forKey: lastUpdateKey)
    }
}
