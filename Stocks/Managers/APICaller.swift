//
//  APICaller.swift
//  Stocks
//
//  Created by Ivan Pastukhov on 20.07.2021.
//

import Foundation

/// Object to manage API calls
final class APICaller {
    /// Singleton
    public static let shared = APICaller()
    
    /// Constants
    private struct Constants {
        static let apiKey = "ch16ae1r01qhadkoo0ugch16ae1r01qhadkoo0v0"
        static let baseUrl = "https://finnhub.io/api/v1/"
        static let day: Double = 60 * 60 * 24
    }
        
    // MARK: - Public
    
    /// Search for a company
    /// - Parameters:
    ///   - query: Query string (symbol or name)
    ///   - completion: Callback for result
    public func search(
        query: String,
        completion: @escaping (Result<SearchResponse, Error>) -> Void) {
        guard let safeQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        request(
            url: url(
                for: .search,
                queryParams: ["q": safeQuery]),
            expecting: SearchResponse.self,
            completion: completion)
    }
    
    /// Get news for type
    /// - Parameters:
    ///   - type: Company or top stories
    ///   - completion: Result callback
    public func news(for type: NewsViewController.DataType, completion: @escaping (Result<[NewsStory], Error>) -> Void) {
        switch type {
        case .topStories:
            let url = url(for: .topStories, queryParams: ["category": "general"])
            request(url: url, expecting: [NewsStory].self, completion: completion)
        case .company(let symbol):
            let today = Date()
            let lastWeek = today.addingTimeInterval(-(Constants.day * 7))
            let url = url(for: .companyNews,
                          queryParams: ["symbol": symbol,
                                        "from": DateFormatter.newsDateFormatter.string(from: lastWeek),
                                        "to": DateFormatter.newsDateFormatter.string(from: today)])
            
            request(url: url, expecting: [NewsStory].self, completion: completion)
        }
    }
    
    /// Get market data
    /// - Parameters:
    ///   - symbol: Given symbol
    ///   - numberOfDays: Number of days back from today
    ///   - completion: Result callback
    public func marketData(
        for symbol: String,
        numberOfDays: Double = 7,
        completion: @escaping (Result<MarketDataResponse, Error>) -> Void) {
            let today = Date().addingTimeInterval(-Constants.day * 2)
            let prior = today.addingTimeInterval(-(Constants.day * numberOfDays))
            let url = url(for: .marketData,
                          queryParams: ["symbol": symbol,
                                        "resolution": "1",
                                        "from": "\(Int(prior.timeIntervalSince1970))",
                                        "to": "\(Int(today.timeIntervalSince1970))"])
            
            request(url: url, expecting: MarketDataResponse.self, completion: completion)
        }
    
    /// Get financial metrics
    /// - Parameters:
    ///   - symbol: Symbol of company
    ///   - completion: Result callback
    public func financialMetrics(
        for symbol: String,
        completion: @escaping (Result<FinancialMetricsResponse, Error>) -> Void) {
            let url = url(for: .financials, queryParams: ["symbol": symbol, "metric": "all"])
            request(url: url, expecting: FinancialMetricsResponse.self, completion: completion)
        }
    
    // MARK: - Private
    
    ///  API endpoints
    private enum Endpoint: String {
        case search
        case topStories = "news"
        case companyNews = "company-news"
        case marketData = "stock/candle"
        case financials = "stock/metric"
    }
    
    /// API errors
    private enum APIError: Error {
        case invalidUrl
        case noData
    }
    
    /// Try to create URL for endpoint
    /// - Parameters:
    ///   - endpoint: Endpoint to create for
    ///   - queryParams: Additional query arguments
    /// - Returns: Optional URL
    private func url(
        for endpoint: Endpoint,
        queryParams: [String: String] = [:]) -> URL? {
            var urlString = Constants.baseUrl + endpoint.rawValue
            
            var queryItems = [URLQueryItem]()
            
            for (name, value) in queryParams {
                queryItems.append(URLQueryItem(name: name, value: value))
            }
            
            queryItems.append(URLQueryItem(name: "token", value: Constants.apiKey))
            
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            urlString += "?" + queryString
                    
            return URL(string: urlString)
        }
    
    /// Perform API call
    /// - Parameters:
    ///   - url: URL to hit
    ///   - expecting: Type we expected
    ///   - completion: Result callback
    private func request<T: Codable>(
        url: URL?,
        expecting: T.Type,
        completion: @escaping (Result<T, Error>) -> Void) {
            
            guard let url = url else {
                completion(.failure(APIError.invalidUrl))
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(APIError.noData))
                    }
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(expecting, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
}
