//
//  Iex.swift
//  stocks
//
//  Created by Daniel on 5/29/20.
//  Copyright © 2020 dk. All rights reserved.
//

import Foundation

// TODO: support https://sandbox.iexapis.com/stable/stock/market/batch?symbols=aapl&types=company,balance-sheet&token=Tsk_309349a480bc4f4e922f63c57b69e3de
struct Iex {

    struct Company: Codable {
        var companyName: String
        var exchange: String
        var website: URL
        var description: String
        var CEO: String
        var sector: String
        var employees: Int
        var address: String
        var address2: String?
        var state: String?
        var city: String
        var country: String
    }

    struct Quote: Codable {
        var close: Double
        var previousClose: Double
    }

    struct Symbol: Codable {
        var name: String
        var symbol: String
    }
    
}

extension Iex {

    static func getDetail(_ symbol: String?, completion: @escaping (Company?) -> Void) {
        guard let symbol = symbol else {
            completion(nil)
            return
        }
        
        let url = Iex.companyUrl(symbol)
        url?.get { (company: Company?) in
            completion(company)
        }
    }

    static func getQuote(_ symbol: String, completion: @escaping (MyQuote?) -> Void) {
        let url = Iex.quoteUrl(symbol)
        url?.get { (quote: Iex.Quote?) in
            completion(quote?.quote)
        }
    }

    static func getSearchResults(_ query: String, completion: @escaping ([Symbol]?) -> Void) {
        let url = Iex.symbolsUrl
        url?.get { (results: [Symbol]?) in
            let lower = query.lowercased()
            let filtered = results?.compactMap { $0 }.filter {
                $0.name.lowercased().contains(lower) || $0.symbol.lowercased().contains(lower) }
            completion(filtered)
        }
    }

}

extension Iex.Quote {

    var quote: MyQuote {
        return MyQuote(price: close, change: close - previousClose)
    }

}

private extension Iex {

    static let env: Environment = .sandbox

    static var baseUrlComponents: URLComponents {
        var c = URLComponents()
        c.scheme = "https"
        c.host = env.host

        return c
    }

    static func companyUrl(_ symbol: String) -> URL? {
        var c = baseUrlComponents
        c.path = "\(env.pathPrefix)/stock/\(symbol)/company"
        c.queryItems = [ tokenQueryItem ]

        let u = c.url

        return u
    }

    static func quoteUrl(_ symbol: String) -> URL? {
        var c = baseUrlComponents
        c.path = "\(env.pathPrefix)/stock/\(symbol)/quote"
        c.queryItems = [ tokenQueryItem ]

        let u = c.url

        return u
    }

    static var symbolsUrl: URL? {
        var c = baseUrlComponents
        c.path = "\(env.pathPrefix)/ref-data/symbols"
        c.queryItems = [ tokenQueryItem ]

        let u = c.url

        return u
    }

    static var tokenQueryItem: URLQueryItem {
        let queryItem = URLQueryItem(name: "token", value: env.apiKey)

        return queryItem
    }

}

private enum Environment {

    case sandbox, production

    var apiKey: String {
        switch self {
        case .sandbox:
            return "GET API KEY"

        case .production:
            return "GET API KEY"
        }
    }

    var host: String {
        switch self {
        case .sandbox:
            return "sandbox.iexapis.com"
        case .production:
            return "cloud.iexapis.com"
        }
    }

    var pathPrefix: String {
        switch self {
        case .sandbox:
            return "/stable"
        case .production:
            return "/v1"
        }
    }

}
