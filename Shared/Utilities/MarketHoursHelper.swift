//
//  MarketHoursHelper.swift
//  MarketWidget
//
//  Helper for determining market hours and switching between indices/futures
//

import Foundation

class MarketHoursHelper {
    static let shared = MarketHoursHelper()

    private init() {}

    /// Check if US stock market is currently open
    func isMarketOpen() -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Convert to Eastern Time (market timezone)
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        var components = calendar.dateComponents(in: easternTimeZone, from: now)

        guard let hour = components.hour,
              let minute = components.minute,
              let weekday = components.weekday else {
            return false
        }

        // Check if it's a weekday (2 = Monday, 6 = Friday)
        guard weekday >= 2 && weekday <= 6 else {
            return false  // Weekend
        }

        // Market hours: 9:30 AM - 4:00 PM ET
        let minutesSinceMidnight = hour * 60 + minute
        let marketOpen = 9 * 60 + 30    // 9:30 AM
        let marketClose = 16 * 60       // 4:00 PM

        return minutesSinceMidnight >= marketOpen && minutesSinceMidnight < marketClose
    }

    /// Get appropriate symbols for current market state
    func getCurrentSymbols() -> [String] {
        if isMarketOpen() {
            return getIndicesSymbols()
        } else {
            return getFuturesSymbols()
        }
    }

    /// Symbols for indices (market hours)
    func getIndicesSymbols() -> [String] {
        return ["$SPX.X", "$NDX.X", "$DJI"]
    }

    /// Symbols for futures (after hours)
    func getFuturesSymbols() -> [String] {
        return ["/ES", "/NQ", "/YM"]
    }

    /// Get display name for symbol
    func getDisplayName(for symbol: String) -> String {
        switch symbol {
        // Indices
        case "$SPX.X", "$SPX", "SPX":
            return "S&P 500"
        case "$NDX.X", "$NDX", "NDX":
            return "Nasdaq"
        case "$DJI", "DJI":
            return "Dow"
        case "$RUT.X", "$RUT", "RUT":
            return "Russell"
        case "$VIX.X", "$VIX", "VIX":
            return "Volatility"

        // Futures
        case "/ES", "ES":
            return "S&P Fut"
        case "/NQ", "NQ":
            return "Nasdaq Fut"
        case "/YM", "YM":
            return "Dow Fut"
        case "/RTY", "RTY":
            return "Russell Fut"
        case "/GC", "GC":
            return "Gold"
        case "/CL", "CL":
            return "Crude Oil"

        default:
            return cleanSymbol(symbol)
        }
    }

    /// Clean symbol for display (remove prefixes/suffixes)
    func cleanSymbol(_ symbol: String) -> String {
        return symbol
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ".X", with: "")
    }

    /// Get market status description
    func getMarketStatus() -> String {
        if isMarketOpen() {
            return "Market Open"
        } else {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: Date())

            if weekday == 1 || weekday == 7 {
                return "Weekend - Futures Only"
            } else {
                return "After Hours - Futures Only"
            }
        }
    }

    /// Check if today is a market holiday
    func isMarketHoliday() -> Bool {
        // Add US market holidays here
        let holidays = getMarketHolidays()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return holidays.contains { calendar.isDate($0, inSameDayAs: today) }
    }

    /// Get list of market holidays for current year
    private func getMarketHolidays() -> [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        var holidays: [Date] = []

        // Helper to create date
        func makeDate(month: Int, day: Int) -> Date? {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            return calendar.date(from: components)
        }

        // US Market Holidays (approximate - verify each year)
        if let newYears = makeDate(month: 1, day: 1) { holidays.append(newYears) }
        if let mlkDay = makeDate(month: 1, day: 15) { holidays.append(mlkDay) }      // 3rd Monday
        if let presidentsDay = makeDate(month: 2, day: 19) { holidays.append(presidentsDay) }  // 3rd Monday
        if let goodFriday = makeDate(month: 3, day: 29) { holidays.append(goodFriday) }  // Varies
        if let memorialDay = makeDate(month: 5, day: 27) { holidays.append(memorialDay) }  // Last Monday
        if let juneteenth = makeDate(month: 6, day: 19) { holidays.append(juneteenth) }
        if let july4th = makeDate(month: 7, day: 4) { holidays.append(july4th) }
        if let laborDay = makeDate(month: 9, day: 2) { holidays.append(laborDay) }  // 1st Monday
        if let thanksgiving = makeDate(month: 11, day: 28) { holidays.append(thanksgiving) }  // 4th Thursday
        if let christmas = makeDate(month: 12, day: 25) { holidays.append(christmas) }

        return holidays
    }

    /// Get next market open time
    func getNextMarketOpen() -> Date? {
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        var components = calendar.dateComponents(in: easternTimeZone, from: Date())

        // Set to 9:30 AM ET
        components.hour = 9
        components.minute = 30
        components.second = 0

        guard var nextOpen = calendar.date(from: components) else {
            return nil
        }

        // If market already opened today, move to next day
        if nextOpen < Date() {
            nextOpen = calendar.date(byAdding: .day, value: 1, to: nextOpen)!
        }

        // Skip weekends
        let weekday = calendar.component(.weekday, from: nextOpen)
        if weekday == 7 {  // Saturday
            nextOpen = calendar.date(byAdding: .day, value: 2, to: nextOpen)!
        } else if weekday == 1 {  // Sunday
            nextOpen = calendar.date(byAdding: .day, value: 1, to: nextOpen)!
        }

        return nextOpen
    }
}
