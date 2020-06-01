//
//  Tiingo.swift
//  stocks
//
//  Created by Daniel on 5/26/20.
//  Copyright © 2020 dk. All rights reserved.
//

import Foundation

struct Tiingo {

    struct Fundamental: Codable {
        var marketCap: Double?
        var enterpriseVal: Double?
        var peRatio: Double?
        var pbRatio: Double?
        var trailingPEG1Y: Double?
    }

    struct Iex: Codable {
        var last: Double
        var prevClose: Double
    }

    struct Search: Codable {
        var ticker: String?
        var name: String?
    }

}

extension Tiingo {

    static func getDetail(_ symbol: String?, completion: @escaping (Tiingo.Fundamental?)-> Void) {
        let url = fundamentalsUrl(symbol)
        url?.get(completion: { (results: [Tiingo.Fundamental]?) in
            if let first = results?.first {
                completion(first)
            }
            else {
                completion(nil)
            }
        })
    }

    static func getQuote(_ symbol: String, completion: @escaping (MyQuote?) -> Void) {
        let url = iexQuoteUrl(symbol)
        url?.get { (quotes: [Tiingo.Iex]?) in
            guard let quotes = quotes,
                let iex = quotes.first else {
                    completion(nil)
                    return
            }

            completion(iex.quote)
        }
    }

    static func getSearchResults(_ query: String, completion: @escaping ([Tiingo.Search]?) -> Void) {
        let url = searchUrl(query)
        url?.get { (results: [Tiingo.Search]?) in
            completion(results)
        }
    }

}

private extension Tiingo.Iex {

    var quote: MyQuote {
        return MyQuote(price: last, change: last - prevClose)
    }

}

private extension Tiingo {

    static let apiKey = "GET API KEY"

    static let host = "api.tiingo.com"

    static var baseUrlComponents: URLComponents {
        var c = URLComponents()
        c.scheme = "https"
        c.host = host

        return c
    }

    static var tokenQueryItem: URLQueryItem {
        let queryItem = URLQueryItem(name: "token", value: apiKey)

        return queryItem
    }

    static func iexQuoteUrl(_ symbol: String) -> URL? {
        var c = baseUrlComponents
        c.path = "/iex/\(symbol)"

        c.queryItems = [ tokenQueryItem ]

        let u = c.url

        return u
    }

    static func fundamentalsUrl(_ symbol: String?) -> URL? {
        guard let symbol = symbol else { return nil }

        var c = baseUrlComponents
        c.path = "/tiingo/fundamentals/\(symbol)/daily"

        c.queryItems = [ tokenQueryItem ]

        let u = c.url

        return u
    }

    static func searchUrl(_ query: String) -> URL? {
        var c = baseUrlComponents
        c.path = "/tiingo/utilities/search"

        let sQi = URLQueryItem(name: "query", value: query)
        c.queryItems = [ tokenQueryItem, sQi ]

        let u = c.url

        return u
    }

}
