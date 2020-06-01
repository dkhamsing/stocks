//
//  MyStocksViewController.swift
//  stocks
//
//  Created by Daniel on 5/28/20.
//  Copyright © 2020 dk. All rights reserved.
//

import UIKit

class MyStocksViewController: UIViewController {

    // UI
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addButton: UIButton!
    private let refreshControl = UIRefreshControl()
    private var updateLabel = UpdateLabel()

    @IBAction func addButtonTapped(_ sender: Any) {
        addStock()
    }

    // Data
    fileprivate var dataSource: [Section] = []
    private var sort: Sort = .percent
    private let provider: Provider = .finnhub

    var footerView: UpdateLabel {
        let label = UpdateLabel()

        var f = view.bounds
        f.size.height = 15
        label.frame = f

        updateLabel = label
        updateLabel.provider = provider

        return label
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        setup()
        loadList()
        updateNavBar()
        updateStockData()
    }

}

private extension MyStocksViewController {

    func loadList() {
        let list = MyStocks().load()

        let count = list.count

        tableView.isHidden = count == 0
        addButton.isHidden = count != 0

        guard count > 0 else { return }

        dataSource = makeDataSource(items: list, sort: sort)
        tableView.reloadData()
    }

    func setup() {
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(updateStockData), for: .valueChanged)

        let interval: TimeInterval = 60
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (_:Timer)->Void in
            self.updateLabel.update()
        }
    }

    func updateNavBar(_ isEditing: Bool = false) {
        if isEditing {
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(editStocks))

            navigationItem.rightBarButtonItems = [doneButton]
        }
        else {
            let image = UIImage(systemName: "plus")
            let addButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(addStock))

            let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editStocks))

            navigationItem.rightBarButtonItems = dataSource.first?.items?.count ?? 0 == 0 ?
                [addButton] : [editButton, addButton]
        }
    }

}

private extension MyStocksViewController {

    @objc
    func addStock() {
        let s = AddStockViewController()
        s.modalPresentationStyle = .formSheet
        s.provider = provider
        s.delegate = self

        let n = UINavigationController(rootViewController: s)
        n.navigationBar.prefersLargeTitles = true
        n.navigationBar.largeTitleTextAttributes = Theme.attributes

        present(n, animated: true, completion: nil)
    }

    @objc
    func editStocks() {
        let isEditing = !tableView.isEditing
        updateNavBar(isEditing)
        tableView.setEditing(isEditing, animated: true)
    }

//    @objc
//    func fetchStockDatawip() {
//        guard let list = dataSource.first?.items else { return }
//
//
//        let symbols = list.compactMap { $0.symbol }
//        print(symbols)
//
//        let urls = symbols.map { Finnhub.quoteUrl($0) }
//
//        URL.get(urls) { o in
//            print(o)
//
//            var items: [Item] = []
//
//            for data in o {
//                let decoder = JSONDecoder()
//                if let decoded = try? decoder.decode(Finnhub.Quote.self, from: data) {
//                    print(decoded)
//
//                    let item = Item(symbol: "", quote: decoded.quote)
//                    items.append(item)
//
//                }
//            }
//
//
//
//            // update my saved stocks
//                       var s = MyStocks()
//                       s.save(items)
//
//                       // update ui
//                       self.refreshControl.endRefreshing()
//                       self.dataSource = self.makeDataSource(items: items, sort: self.sort)
//                       self.loadList()
//
//                       let foot = self.footerView
//                       foot.date = Date()
//                       foot.update()
//                       self.tableView.tableFooterView = foot
//
//
//        }
//
//    }

    @objc
    func updateStockData() {
        // TODO: while fetching stock data, prevent list changes (delete)
        fetchStockData { (items) in
            // update my saved stocks
            var s = MyStocks()
            s.save(items)

            // update ui
            self.refreshControl.endRefreshing()
            self.dataSource = self.makeDataSource(items: items, sort: self.sort)
            self.loadList()

            if self.tableView.tableFooterView == nil {
                self.tableView.tableFooterView = self.footerView
            }

            self.updateLabel.date = Date()
            self.updateLabel.update()
        }

    }

    func fetchStockData(completion: @escaping ([Item]) -> Void) {
        guard let list = dataSource.first?.items else { return }

        var stocksData: [String:MyQuote] = [:]
        let group = DispatchGroup()
        for item in list {
            group.enter()
            self.provider.getQuote(item.symbol) { (m) in
                if let symbol = item.symbol {
                    stocksData[symbol] = m
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            var items: [Item] = []

            for item in list {
                if let symbol = item.symbol {
                    let value = stocksData[symbol]
                    let item = Item(symbol: symbol, quote: value)
                    items.append(item)
                }
            }

            completion(items)
        }
    }

    @objc
    func sortList() {
        switch sort {
        case .symbol:
            sort = .change
        case .change:
            sort = .percent
        case .percent:
            sort = .price
        case .price:
            sort = .symbol
        }

        loadList()
    }

}

private extension MyStocksViewController {

    func makeDataSource(items: [Item], sort: Sort) -> [Section] {
        // sort items
        let sorted = sortItems(items, sort: sort)

        // save list
        var s = MyStocks()
        s.save(sorted)

        // make data source
        let section = Section(header: sort.header, items: sorted)

        return [section]
    }

    func sortItems(_ items: [Item], sort: Sort) -> [Item] {
        var sorted: [Item] = []

        switch sort {
        case .symbol:
            sorted = items.sorted { $0.symbol ?? "" < $1.symbol ?? "" }
        case .change:
            sorted = items.sorted { $0.quote?.change ?? 0 > $1.quote?.change ?? 0 }
        case .percent:
            sorted = items.sorted { $0.quote?.percent ?? 0 > $1.quote?.percent ?? 0 }
        case .price:
            sorted = items.sorted { $0.quote?.price ?? 0 > $1.quote?.price ?? 0 }
        }

        return sorted
    }

}

extension MyStocksViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let frame = view.bounds
        let view = UIView(frame: frame)

        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
        ])

        let s = dataSource[section]
        let title = "   \(s.header ?? "")   "
        button.setTitle(title, for: .normal)

        button.backgroundColor = Theme.color
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(sortList), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        button.layer.cornerRadius = 13
        button.layer.masksToBounds = true

        return view
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let s = dataSource[section]
        return s.header
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // step 1 of 2: update data
            var s = MyStocks()
            var list = s.load()
            list.remove(at: indexPath.row)
            s.save(list)

            // step 2 of 2: update ui
            dataSource = makeDataSource(items: list, sort: sort)
            loadList()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let s = dataSource[indexPath.section]
        guard let item = s.items?[indexPath.row] else { return }

        let d = DetailViewController()
        d.provider = provider
        d.item = item
        d.modalPresentationStyle = .formSheet

        let n = UINavigationController(rootViewController: d)
        n.navigationBar.prefersLargeTitles = true
        n.navigationBar.largeTitleTextAttributes = Theme.attributes
        present(n, animated: true, completion: nil)
    }

}

extension MyStocksViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = dataSource[section]
        return s.items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "id")

        let s = dataSource[indexPath.section]
        if let item = s.items?[indexPath.row] {
            cell.textLabel?.text = item.symbol

            switch sort {
            case .change:
                cell.detailTextLabel?.attributedText = item.changeAttributedValue
            case .price:
                cell.detailTextLabel?.attributedText = item.priceAttributedValue
            case .percent:
                cell.detailTextLabel?.attributedText = item.percentAttributedValue
            case .symbol:
                cell.detailTextLabel?.attributedText = item.attributedValue
            }


        }

        return cell
    }

}

extension MyStocksViewController: SelectStock {

    func didSelect(_ stock: String?) {
        guard let stock = stock else { return }

        var s = MyStocks()
        var list = s.load()

        let item = Item(symbol: stock)

        guard list.contains(item) == false else { return }

        list.append(item)
        s.save(list)

        loadList()
        updateNavBar()
        updateStockData()
    }

}

struct MyStocks {

    var symbols: [String] {
        return list.compactMap { $0.symbol }
    }

    fileprivate var dataSource: [Section] {
        var sections: [Section] = []

        let section = Section(items: list)
        sections.append(section)

        return sections
    }

    fileprivate func load() -> [Item] {
        return list
    }

    fileprivate mutating func save(_ items: [Item]) {
        self.list = items
    }

    private var list: [Item] = UserDefaultsConfig.list {
        didSet {
            UserDefaultsConfig.list = list
        }
    }

}

private struct UserDefaultsConfig {

    @UserDefault("list", defaultValue: [])
    fileprivate static var list: [Item]

}

private struct Section {

    var header: String?
    var items: [Item]?

}

private extension Item {

    var attributedValue: NSAttributedString? {
        return quote?.value
    }

    var changeAttributedValue: NSAttributedString? {
        return quote?.changeValue
    }

    var percentAttributedValue: NSAttributedString? {
        return quote?.percentValue
    }

    var priceAttributedValue: NSAttributedString? {
        return quote?.priceAttributedValue
    }

}

private enum Sort {

    case change, percent, price, symbol

    var header: String {
        switch self {
        case .symbol:
            return "Alphabetical"
        case .percent:
            return "Percent Change"
        case .price:
            return "Current Price"
        case .change:
            return "Price Change"
        }
    }

}
