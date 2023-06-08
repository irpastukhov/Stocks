//
//  StocksTests.swift
//  StocksTests
//
//  Created by Ivan Pastukhov on 27.07.2021.
//

@testable import Stocks

import XCTest

final class StocksTests: XCTestCase {
    
    func testCandleStickDataConversion() {
        let doubles: [Double] = Array(repeating: 12.2, count: 10)
        var timestamps: [TimeInterval] = Array (repeating: Date() . timeIntervalSince1970, count: 12)
        
        for x in 0..<12 {
            let interval = Date().addingTimeInterval(3600 * TimeInterval(x)).timeIntervalSince1970
            timestamps.append (interval)
        }
        timestamps.shuffle()
        
        let marketData = MarketDataResponse(
            open: doubles,
            close: doubles,
            high: doubles,
            low: doubles,
            status: "success",
            timestamps: timestamps)
        
        let candleSticks = marketData.candleSticks
        
        XCTAssertEqual(candleSticks.count, marketData.open.count)
        XCTAssertEqual(candleSticks.count, marketData.close.count)
        XCTAssertEqual(candleSticks.count, marketData.high.count)
        XCTAssertEqual(candleSticks.count, marketData.low.count)
        XCTAssertEqual(candleSticks.count, marketData.timestamps.count)
        
        let dates = candleSticks.map { $0.date }
        for x in 0..<dates.count - 1 {
            let current = dates[x]
            let next = dates[x + 1]
            XCTAssertTrue (current >= next)
        }
    }   

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}


    func testPerformanceExample() throws {
        measure {}
    }

}
