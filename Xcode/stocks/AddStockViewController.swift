//
//  AddStockViewController.swift
//  stocks
//
//  Created by Daniel on 5/26/20.
//  Copyright © 2020 dk. All rights reserved.
//

import UIKit

protocol SelectStock {
    func didSelect(_ stock: String?)
}

class AddStockViewController: UIViewController {

    var delegate: SelectStock?

    var provider: Provider?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var dataSource: [AddSection] = []

    private var query: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        config()
        loadPopularStocks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
}

private extension AddStockViewController {

    func config() {
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
    }

    func loadPopularStocks() {
        let popularSymbols: [String] =
            [
                "AAPL",
                "TSLA",
                "DIS",
                "MSFT",
                "SNAP",
                "UBER",
                "TWTR",
                "AMD",
                "FB",
                "LK",
                "AMZN",
                "SHOP"
        ]
        dataSource = popularSymbols.dataSource
        tableView.reloadData()
    }

    func setup() {
        title = "Add a Stock"

        view.backgroundColor = .systemGray5

        tableView.dataSource = self
        tableView.delegate = self

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = search

        let button = Theme.closeButton
        button.target = self
        button.action = #selector(close)
        navigationItem.rightBarButtonItem = button
    }

}

extension AddStockViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard
            let text = searchController.searchBar.text,
            text.count > 0 else { return }

        query = text

        /// Credits: https://stackoverflow.com/questions/24330056/how-to-throttle-search-based-on-typing-speed-in-ios-uisearchbar
        /// to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(loadSearch), object: nil)
        perform(#selector(loadSearch), with: nil, afterDelay: 0.5)
    }

}

private extension AddStockViewController {

    @objc
    func loadSearch() {
        print("load search with \(query)")

        provider?.search(query, completion: { (items) in
            let section = AddSection(header: "Search", items: items)
            self.dataSource = [section]
            self.tableView.reloadData()
        })
    }
    
    @objc
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension AddStockViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let s = dataSource[section]
        return s.header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        var s = dataSource[indexPath.section]
        var items = s.items
        if var item = items?[indexPath.row] {
            guard item.alreadyInList == false else { return }
            
            print("selected \(item)")

            self.delegate?.didSelect(item.title)

            // update ui
            item.alreadyInList = item.alreadyInList ? false : true
            items = s.items
            items?[indexPath.row] = item

            s.items = items
            dataSource = [s]
            tableView.reloadData()
        }
    }

}

extension AddStockViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = dataSource[section]
        return s.items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        let s = dataSource[indexPath.section]
        if let item = s.items?[indexPath.row] {
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = item.subtitle

            cell.accessoryType = item.alreadyInList ? .checkmark : .none
        }

        return cell
    }

}

private extension Sequence where Iterator.Element == String {

    var dataSource: [AddSection] {
        var sections: [AddSection] = []

        let items = self.map { $0.item }
        let section = AddSection(header: "Popular Stocks", items: items)
        sections.append(section)

        return sections
    }

}

private extension String {

    var item: AddItem {
        let a = MyStocks().symbols.contains(self)

        return AddItem(title: self, alreadyInList: a)
    }

}

private struct AddSection {

    var header: String?
    var items: [AddItem]?

}

struct AddItem {

    var title: String?
    var subtitle: String?

    var alreadyInList: Bool

}
