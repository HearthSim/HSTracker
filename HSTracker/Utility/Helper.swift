//
//  Helper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/16/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import RegexUtil

struct Helper {
    static func parseDeckNameTemplate(template: String, deck: Deck) -> String {
        var result = template
        let dateRegex = RegexPattern(stringLiteral: "\\{Date (.*?)\\}")
        let classRegex = RegexPattern(stringLiteral: "\\{Class\\}")
        
        let match = result.matches(dateRegex)
        if match.count > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = match[0].value
            let date = formatter.string(from: Date())
            result = result.replace(dateRegex, with: date)

        }
        
        if result.match(classRegex) {
            result = result.replace(classRegex, with: deck.playerClass.rawValue.capitalized)
            return result
        }
        return result
    }

}
