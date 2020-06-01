//
//  Item.swift
//  stocks
//
//  Created by Daniel on 5/28/20.
//  Copyright © 2020 dk. All rights reserved.
//

import Foundation

struct Item: Codable {

    var symbol: String?
    var quote: MyQuote?

}

extension Item: Equatable {

    static func ==(lhs: Item, rhs: Item) -> Bool {
        return lhs.symbol == rhs.symbol
    }

}
