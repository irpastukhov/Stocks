//
//  PersistenceManager.swift
//  Stocks
//
//  Created by Ivan Pastukhov on 20.07.2021.
//

import Foundation


/// Object to manage saved caches
final class PersistenceManager {
    /// Singleton
    static let shared = PersistenceManager()
    
    /// Reference to user defaults
    private let userDefaults: UserDefaults = .standard
    
    /// Constants
    private struct Constants {
        static let onboardedKey = "hasOnboarded"
        static let watchlistKey = "watchlist"
        
    }
    
    /// Get our watchlist
    public var watchlist: [String] {
        if !hasOnboarded {
            userDefaults.set(true, forKey: Constants.onboardedKey)
            setUpDefaults()
        }
        let watchlist = userDefaults.stringArray(forKey: Constants.watchlistKey) ?? []
        return watchlist
    }
    
    /// Check if watch list contains item
    /// - Parameter symbol: Symbol to check
    /// - Returns: Boolean
    public func watchlistContains(symbol: String) -> Bool {
        return watchlist.contains(symbol)
    }
    
    /// Add a symbol to watchlist
    /// - Parameters:
    ///   - symbol: Symbol to add
    ///   - companyName: Company name for symbol being added
    public func addToWatchlist(symbol: String, companyName: String) {
        var current = watchlist
        current.append(symbol)
        userDefaults.set(current, forKey: Constants .watchlistKey)
        userDefaults.set (companyName, forKey: symbol)
        
        NotificationCenter.default.post(Notification(name: .didAddToWatchList))
    }
    
    /// Remove item from watchlist
    /// - Parameter symbol: Symbol to remove
    public func removeFromWatchlist(symbol: String) {
        userDefaults.set(nil, forKey: symbol)
        var newList = [String]()
        for item in watchlist where item != symbol {
            newList.append(item)
        }
        userDefaults.set(newList, forKey: Constants.watchlistKey)
    }
    
    // MARK: - Private
    
    /// Check if user has been onboarded
    private var hasOnboarded: Bool {
        return userDefaults.bool(forKey: Constants.onboardedKey)
    }
    
    /// Set up default watchlist
    private func setUpDefaults() {
        let map: [String: String] = [
        "AAPL": "Apple Inc",
        "MSFT": "Microsoft Corporation",
        "SNAP": "Snap Inc.",
        "GOOG" : "Alphabet",
        "AMZN": "Amazon.com, Inc.",
        "WORK": "Slack Technologies",
        "META": "Meta Platforms Inc",
        "NVDA": "Nvidia Inc.",
        "NKE": "Nike",
        "PINS": "Pinterest Inc."
        ]
        
        let symbols = map.keys.map { $0 }
        userDefaults.set(symbols, forKey: Constants.watchlistKey)
        
        for (symbol, name) in map {
            userDefaults.set(name, forKey: symbol)
        }
    }
}
