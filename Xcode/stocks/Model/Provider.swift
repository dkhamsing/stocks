//
//  Provider.swift
//  stocks
//
//  Created by Daniel on 5/28/20.
//  Copyright © 2020 dk. All rights reserved.
//

import UIKit

enum Provider: String {

    case iex, finnhub, tiingo

    func getDetail(_ symbol: String?, completion: @escaping ([DetailSection], UIImage?) -> Void) {
        switch self {
        case .iex:
            Iex.getDetail(symbol) { company in
                guard let company = company else {
                    completion([],nil)
                    return
                }

                completion(company.sections,nil)
            }
        case .tiingo:
            Tiingo.getDetail(symbol) { fundamental in
                guard let fundamental = fundamental else {
                    completion([],nil)
                    return
                }

                let items = fundamental.items
                let section = DetailSection(items: items)
                completion([section],nil)
            }
        case .finnhub:
            Finnhub.getDetail(symbol) { profile, news, dividends, image, executives in
                var sections: [DetailSection] = []

                if let s = profile?.sections {
                    sections.append(contentsOf: s)
                }

                if let s = DetailSection.section(dividends) {
                    sections.append(s)
                }

                if let s = DetailSection.section(executives) {
                    sections.append(s)
                }

                if let s = DetailSection.section(news) {
                    sections.append(s)
                }
    
                completion(sections,image)
            }
        }
    }

    func getQuote(_ symbol: String?, completion: @escaping (MyQuote?) -> Void) {
        guard let symbol = symbol else {
            completion(nil)
            return
        }

        switch self {
        case .iex:
            Iex.getQuote(symbol) { (m) in
                completion(m)
            }
        case .tiingo:
            let validSymbol = symbol.replacingOccurrences(of: ".", with: "-")
            Tiingo.getQuote(validSymbol) { (m) in
                completion(m)
            }
        case .finnhub:
            let validSymbol = symbol.replacingOccurrences(of: "-", with: ".")
            Finnhub.getQuote(validSymbol) { (m) in
                completion(m)
            }
        }
    }

    func search(_ query: String, completion: @escaping ([AddItem]?) -> Void) {
        switch self {
        case .iex:
            Iex.getSearchResults(query) { results in
                let items = results?.compactMap { $0.item }
                completion(items)
            }
        case .tiingo:
            Tiingo.getSearchResults(query) { (results) in
                let items = results?.compactMap { $0.item }
                completion(items)
            }
        case .finnhub:
            Finnhub.getSearchResults(query) { (results) in
                let items = results?.compactMap { $0.item }
                completion(items)
            }
        }
    }

}

private extension Tiingo.Search {

    var item: AddItem {
        var a = false
        if let ticker = ticker {
            a = MyStocks().symbols.contains(ticker)
        }

        return AddItem(title: ticker, subtitle: name, alreadyInList: a)
    }

}

private extension Finnhub.Symbol {

    var item: AddItem {
        let inList = MyStocks().symbols.contains(symbol)

        return AddItem(title: symbol, subtitle: description, alreadyInList: inList)
    }

}

private extension Iex.Symbol {

    var item: AddItem {
        let inList = MyStocks().symbols.contains(symbol)

        return AddItem(title: symbol, subtitle: name, alreadyInList: inList)
    }

}

private extension Tiingo.Fundamental {

    var items: [DetailItem]? {
        var items: [DetailItem] = []

        if let value = marketCap?.largeNumberDisplay {
            let item = DetailItem(subtitle: "Market Capitalization", title: value)
            items.append(item)
        }

        if let value = enterpriseVal?.largeNumberDisplay {
            let item = DetailItem(subtitle: "Enterprise Value", title: value)
            items.append(item)
        }

        if let value = peRatio {
            let item = DetailItem(subtitle: "Price to Earnings Ratio", title: value.display)
            items.append(item)
        }

        if let value = pbRatio {
            let item = DetailItem(subtitle: "Price to Book Ratio", title: value.display)
            items.append(item)
        }

        if let value = trailingPEG1Y {
            let item = DetailItem(subtitle: "PEG ratio using the trailing 1 year EPS growth rate in the denominator", title: value.display)
            items.append(item)
        }

        return items
    }

}

private extension String {
    var wikipediaUrl: URL? {
        let baseUrl = "https://en.wikipedia.org/wiki"
        let item = self.replacingOccurrences(of: " ", with: "_")

        return URL(string: "\(baseUrl)/\(item)")
    }
}

private extension Int {

    var largeNumberDisplay: String? {
        if self < 1_000_000 {
            return self.display
        }

        let m: Double = Double(self) / 1_000_000

        return String(format: "%.2fM", m)
    }

}

private extension Double {

    var largeNumberDisplay: String? {
        if self < 1_000_000 {
            return String(self)
        }

        let m = self / 1_000_000
        if m < 1000 {
            return "\(m.currency ?? "")M"
        }

        let b = m / 1000
        if b < 1000 {
            return "\(b.currency ?? "")B"
        }

        let t = b / 1000

        return "\(t.currency ?? "")T"
    }

    var fh_largeNumberDisplay: String? {
        if self < 1000 {
            return "\(self.display ?? "")M"
        }

        let b = self / 1000
        return "\(b.display ?? "")B"
    }

}

private extension Finnhub.Profile {

    var sections: [DetailSection]? {
        var sections: [DetailSection] = []

        if let section = mainSection {
            sections.append(section)
        }

        if let section = exchangeSection {
            sections.append(section)
        }

        return sections
    }

    var marketCapDisplay: String? {
        if marketCapitalization < 1000 {
            return "\(marketCapitalization.currency ?? "")M"
        }

        let b = marketCapitalization / 1000
        if b < 1000 {
            return "\(b.currency ?? "")B"
        }

        let t = b / 1000

        return "\(t.currency ?? "")T"
    }

    var mainSection: DetailSection? {
        var items: [DetailItem] = []

        let nameItem = DetailItem(subtitle: weburl.absoluteString, title: name, url: weburl)
        items.append(nameItem)

        if let value = marketCapDisplay {
            let marketCapItem = DetailItem(subtitle: "Market Capitalization", title: value)
            items.append(marketCapItem)
        }

        let section = DetailSection(header: finnhubIndustry, items: items)

        return section
    }

    var exchangeSection: DetailSection? {
        var items: [DetailItem] = []

        if let value = ipoTimeAgo {
            let ipoItem = DetailItem(subtitle: "\(ipoDisplay ?? "") IPO", title: value)
            items.append(ipoItem)
        }

        var string: [String] = ["Shares Outstanding"]
        string.append(country)
        string.append(currency)
        let sharesItem = DetailItem(subtitle: string.joined(separator: Theme.separator), title: "\(shareOutstanding.fh_largeNumberDisplay ?? "")")
        items.append(sharesItem)

        let section = DetailSection(header: exchange, items: items)

        return section
    }

    var ipoDate: Date? {
        return Finnhub.dateFormatter.date(from: ipo)
    }

    var ipoDisplay: String? {
        guard let ipoDate = ipoDate else { return nil }
        let df = DetailViewController.displayDateFormatter

        return df.string(from: ipoDate)
    }

    var ipoTimeAgo: String? {
        guard let ipoDate = ipoDate else { return nil }

        let rdf = RelativeDateTimeFormatter()

        return rdf.localizedString(for: ipoDate, relativeTo: Date())
    }
}

private extension DetailItem {

    var isUrl: Bool? {
        guard
            let value = subtitle,
            value.contains("http") else { return false }

        return true
    }

}

private extension DetailSection {

    static func section(_ div: [Finnhub.Dividend]?) -> DetailSection? {
        guard let div = div, div.count > 0 else { return nil }

        let items = div.compactMap { $0.item }

        let section = DetailSection(header: "recent dividends", items: items)

        return section
    }

    static func section(_ execs: [Finnhub.Executive]?) -> DetailSection? {
        guard let execs = execs, execs.count > 0 else { return nil }

        let items = execs.map { $0.item }
        let limit = 5
        let top = Array(items.prefix(limit))

        // TODO: have a way to see whole list (create footer, tap footer to see?)

        let section = DetailSection(header: "executives", items: top)

        return section
    }

    static func section(_ news: [Finnhub.News]?) -> DetailSection? {
        let items = news?.compactMap { $0.item }
        guard items?.count ?? 0 > 0 else { return nil }

        let section = DetailSection(header: "news", items: items)

        return section
    }

}

private extension DetailViewController {

    static var displayDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"

        return df
    }

}

private extension Finnhub.Dividend {

    var item: DetailItem {
        let t = "\(amount.display ?? "") (\(currency))"

        let df = DetailViewController.displayDateFormatter
        var s = ""
        if let date = Finnhub.dateFormatter.date(from: payDate) {
            s = df.string(from: date)

            let rdf = RelativeDateTimeFormatter()
            s = "\(s)\(Theme.separator)\(rdf.localizedString(for: date, relativeTo: Date()))"
        }

        return DetailItem(subtitle: s, title: t)
    }

}

private extension Finnhub.Executive {

    var item: DetailItem {
        var sub: [String] = []

        if let value = positionDisplay {
            sub.append(value)
        }

        if let age = ageDisplay {
            sub.append(age)
        }

        return DetailItem(subtitle: sub.joined(separator: Theme.separator), title: nameDisplay, url: wikipedia)
    }

    var ageDisplay: String? {
        guard let age = age else { return nil }
        return "Age \(age)"
    }

    var nameDisplay: String {
        return name.trimmingCharacters(in: .whitespaces)
    }

    var positionDisplay: String? {
        guard let position = position else { return nil}

        var comp = position
        if let compensation = compensation?.largeNumberDisplay {
            if currency == "USD" {
                comp = "\(comp) ($"
            }
            comp = "\(comp)\(compensation))"
        }
        return comp
    }

    var wikipedia: URL? {
        let cleanup = nameDisplay
            .replacingOccurrences(of: "Amb. ", with: "")
            .replacingOccurrences(of: "Dr. ", with: "")
            .replacingOccurrences(of: "Mr. ", with: "")
            .replacingOccurrences(of: "Ms. ", with: "")
            .replacingOccurrences(of: "Sen. ", with: "")

        return cleanup.wikipediaUrl
    }

}

private extension Finnhub.News {

    var item: DetailItem? {
        var sub: [String] = []

        let date = Date(timeIntervalSince1970: TimeInterval(datetime))
        let rdf = RelativeDateTimeFormatter()
        let ago = rdf.localizedString(for: date, relativeTo: Date())
        sub.append(ago)

        if let value = sourceDisplay {
            sub.append(value)
        }
        sub.append(summary)

        return DetailItem(subtitle: sub.joined(separator: Theme.separator), title: headline, url: url)
    }

    var sourceDisplay: String? {
        return source
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "www.", with: "")
    }

}

private extension Iex.Company {

    var sections: [DetailSection] {
        var sections: [DetailSection] = []

        if let s = mainSection {
            sections.append(s)
        }

        if let s = addressSection {
            sections.append(s)
        }

        return sections
    }

    var addressSection: DetailSection? {
        let c = self

        var items: [DetailItem] = []

        let cityState = "\(c.city), \(c.state ?? "") (\(c.country))"
        items.append(DetailItem(subtitle: c.address, title: cityState))

        let section = DetailSection(items: items)

        return section
    }

    var mainSection: DetailSection? {
        let c = self

        var items: [DetailItem] = []

        items.append(DetailItem(subtitle: c.website.absoluteString, title: c.companyName, url: c.website))

        items.append(DetailItem(subtitle: "CEO", title: c.CEO))

        if let value = c.employees.display {
            items.append(DetailItem(subtitle: "Employees", title: value))
        }

        items.append(DetailItem(subtitle: c.description))

        let h = "\(c.exchange)\(Theme.separator)\(c.sector)"
        let section = DetailSection(header: h, items: items)

        return section
    }
}

struct Dummy {

    static let JSON = """
               {
                 "symbol": "AAPL",
                 "companyName": "Apple Inc.",
                 "exchange": "NASDAQ",
                 "industry": "Telecommunications Equipment",
                 "website": "http://www.apple.com",
                 "description": "Apple, Inc. engages in the design, manufacture, and marketing of mobile communication, media devices, personal computers, and portable digital music players. It operates through the following geographical segments: Americas, Europe, Greater China, Japan, and Rest of Asia Pacific. The Americas segment includes North and South America. The Europe segment consists of European countries, as well as India, the Middle East, and Africa. The Greater China segment comprises of China, Hong Kong, and Taiwan. The Rest of Asia Pacific segment includes Australia and Asian countries. The company was founded by Steven Paul Jobs, Ronald Gerald Wayne, and Stephen G. Wozniak on April 1, 1976 and is headquartered in Cupertino, CA.",
                 "CEO": "Timothy Donald Cook",
                 "securityName": "Apple Inc.",
                 "issueType": "cs",
                 "sector": "Electronic Technology",
                 "primarySicCode": 3663,
                 "employees": 132000,
                 "tags": [
                   "Electronic Technology",
                   "Telecommunications Equipment"
                 ],
                 "address": "One Apple Park Way",
                 "address2": null,
                 "state": "CA",
                 "city": "Cupertino",
                 "zip": "95014-2083",
                 "country": "US",
                 "phone": "1.408.974.3123"
               }
           """


    static var company: Iex.Company {
        let jsonData = JSON.data(using: .utf8)!
        let temp: Iex.Company = try! JSONDecoder().decode(Iex.Company.self, from: jsonData)

        print(temp)
        return temp
    }

}

private extension Int {

    var display: String? {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "en_US")

        let number = NSNumber(value: self)
        return f.string(from: number)
    }

}
