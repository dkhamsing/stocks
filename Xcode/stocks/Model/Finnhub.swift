//
//  Finnhub.swift
//  stocks
//
//  Created by Daniel on 5/27/20.
//  Copyright © 2020 dk. All rights reserved.
//

import Foundation
import UIKit

struct Finnhub {

    struct Executive: Codable {
        var age: Int?
        var compensation: Int?
        var currency: String
        var name: String
        var position: String?
        var since: String?
    }

    struct ExecutiveResponse: Codable {
        var executive: [Executive]
    }

    struct Dividend: Codable {
        var date: String
        var amount: Double
        var payDate: String
        var currency: String
    }

    struct News: Codable {
        var datetime: Int
        var headline: String
        // TODO: display        var image: URL?
        var source: String
        var summary: String
        var url: URL
    }

    struct Profile: Codable {
        var country: String
        var currency: String
        var exchange: String
        var finnhubIndustry: String
        var ipo: String
        var logo: String?
        var marketCapitalization: Double
        var name: String
        var shareOutstanding: Double
        var weburl: URL
    }

    struct Quote: Codable {
        var c: Double  // current
        var pc: Double // previous close
    }

    struct Symbol: Codable {
        var description: String
        var symbol: String
    }

}

extension Finnhub {

    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return dateFormatter
    }

    static func getDetail(_ symbol: String?, completion: @escaping (Profile?, [News]?, [Dividend]?, UIImage?, [Executive]?) -> Void) {
        guard let symbol = symbol else { return }

        let group = DispatchGroup()

        var p: Profile?
        var n: [News]?
        var d: [Dividend]?
        var i: UIImage?
        var e: [Executive]?

        if let url = profile2Url(symbol) {
            group.enter()
            url.get(completion: { (profile: Finnhub.Profile?) in
                p = profile
                group.leave()

                if
                    let urlString = profile?.logo,
                    let url = URL(string: urlString) {
                    group.enter()
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url),
                            let image = UIImage(data: data) {
                            i = image
                            group.leave()
                        }
                        else {
                            group.leave()
                        }
                    }
                }
            })
        }

        if let url = newsUrl(symbol) {
            group.enter()
            url.get { (news: [Finnhub.News]?) in
                n = news
                group.leave()
            }
        }

        if let url = dividendUrl(symbol) {
            group.enter()
            url.get { (div: [Dividend]?) in
                d = div
                group.leave()
            }
        }

        if let url = executiveUrl(symbol) {
            group.enter()
            url.get { (er: ExecutiveResponse?) in
                e = er?.executive
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(p,n,d,i,e)
        }
    }

    static func getQuote(_ symbol: String, completion: @escaping (MyQuote?) -> Void) {
        let url = quoteUrl(symbol)
        url?.get { (quote: Finnhub.Quote?) in
            guard let finnQuote = quote else {
                completion(nil)
                return
            }

            completion(finnQuote.quote)
        }
    }

    static func getSearchResults(_ query: String, completion: @escaping ([Finnhub.Symbol]?) -> Void) {
        let url = symbolUrl()
        url?.get { (results: [Finnhub.Symbol]?) in
            let lower = query.lowercased()
            let filtered = results?.compactMap { $0 }.filter { $0.description.lowercased().contains(lower) || $0.symbol.lowercased().contains(lower) }
            completion(filtered)
        }
    }

}

private extension Finnhub.Quote {

    var quote: MyQuote {
        return MyQuote(price: c, change: c - pc)
    }

}

private extension Finnhub {

    static let apiKey = "GET API KEY"

    static let host = "finnhub.io"
    static let baseUrl = "/api/v1"

    enum Endpoint: String {
        case companyNews, dividend, executive, profile2, quote, symbol

        var path: String {
            switch self {
            case .companyNews:
                return "\(baseUrl)/company-news"
            case .quote:
                return "\(baseUrl)/\(self.rawValue)"
            case .dividend, .executive, .profile2, .symbol:
                return "\(baseUrl)/stock/\(self.rawValue)"
            }
        }
    }

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

    static func url(path: String, queryItems: [URLQueryItem]) -> URL? {
        var c = baseUrlComponents
        c.path = path
        c.queryItems = queryItems

        let u = c.url

        return u
    }

    static func url(path: String, symbol: String?, numberOfDays: TimeInterval? = nil) -> URL?{
        guard let symbol = symbol else { return nil }

        let s = URLQueryItem(name: "symbol", value: symbol)

        guard let numberOfDays = numberOfDays else {
            let queryItems = [ tokenQueryItem, s]

            return url(path: path, queryItems: queryItems)
        }

        let fromDate = Date().addingTimeInterval(-numberOfDays * 24 * 60 * 60)
        let from = dateFormatter.string(from: fromDate)
        let fromQi = URLQueryItem(name: "from", value: from)

        let to = dateFormatter.string(from: Date())
        let toQi = URLQueryItem(name: "to", value: to)

        let queryItems = [ tokenQueryItem, s, fromQi, toQi ]

        return url(path: path, queryItems: queryItems)
    }

}

private extension Finnhub {
    static func dividendUrl(_ symbol: String?) -> URL? {
        return url(path: Endpoint.dividend.path, symbol: symbol, numberOfDays: 365)
    }

    static func executiveUrl(_ symbol: String) -> URL? {
        return url(path: Endpoint.executive.path, symbol: symbol)
    }

    static func newsUrl(_ symbol: String?) -> URL? {
        return url(path: Endpoint.companyNews.path, symbol: symbol, numberOfDays: 14)
    }

    static func profile2Url(_ symbol: String) -> URL? {
        return url(path: Endpoint.profile2.path, symbol: symbol)
    }

    static func quoteUrl(_ symbol: String) -> URL? {
        return url(path: Endpoint.quote.path, symbol: symbol)
    }

    static func symbolUrl(_ exchange: String = "US") -> URL? {
        var c = baseUrlComponents
        c.path = Endpoint.symbol.path

        let exchangeQi = URLQueryItem(name: "exchange", value: exchange)
        c.queryItems = [ exchangeQi,tokenQueryItem ]

        let u = c.url
        return u
    }
}
