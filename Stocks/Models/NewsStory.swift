//
//  NewsStory.swift
//  Stocks
//
//  Created by Ivan Pastukhov on 22.07.2021.
//

import Foundation

/// Represent news story
struct NewsStory: Codable {
    let category: String
    let datetime: TimeInterval
    let headline: String
    let image: String
    let related: String
    let source: String
    let summary: String
    let url: String
}
