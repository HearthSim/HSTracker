//
//  Helper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/16/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Helper {
    static func parseDeckNameTemplate(template: String, deck: Deck) -> String {
        var result = template
        let dateRegex = Regex("\\{Date (.*?)\\}")
        let classRegex = Regex("\\{Class\\}")
        
        let match = dateRegex.matches(result)
        if match.count > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = match[0].value
            let date = formatter.string(from: Date())
            result = result.replace(dateRegex, with: date)

        }
        
        if classRegex.match(result) {
            result = result.replace(classRegex, with: deck.playerClass.rawValue.capitalized)
            return result
        }
        return result
    }

}
