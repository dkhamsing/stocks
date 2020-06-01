//
//  UpdateLabel.swift
//  stocks
//
//  Created by Daniel on 5/28/20.
//  Copyright © 2020 dk. All rights reserved.
//

import UIKit

class UpdateLabel: UILabel {

    var provider: Provider?
    var date: Date?

    private var dateFormatter = DateFormatter()
    private var relativeDateFormatter = RelativeDateTimeFormatter()

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

}

extension UpdateLabel {
    
    func update() {
        if let string = agoText {
            text = string
        }
    }

}

private extension UpdateLabel {

    var agoText: String? {
        guard let date = date else { return nil }

        var relative = relativeDateFormatter.localizedString(for: date, relativeTo: Date())

        if relative.contains("in ") {
            relative = "A moment ago"
        }

        let string = "Updated \(dateFormatter.string(from: Date()))\(Theme.separator)\(provider?.rawValue ?? "") · \(relative)"

        return string
    }

    func setup() {
        font = .preferredFont(forTextStyle: .caption1)
        textAlignment = .center
        textColor = .secondaryLabel

        dateFormatter.dateFormat = "MMM d h:mm a"
    }

}
