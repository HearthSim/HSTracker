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

    static func toPrettyNumber(n: Int) -> Int {
        let divisor = max(pow(10, (floor(log(Double(n))/log(10.0)) - 1)), 1)
        let pn = floor(Double(n) / divisor) * divisor
        return Int(pn)
    }
    
    static func ensureClientLogConfig() -> Bool {
        let targetContent = "[Log]\nFileSizeLimit.Int=-1"
        let path = "\(Settings.hearthstonePath)client.config"
        if FileManager.default.fileExists(atPath: path) {
            if let content = FileManager.default.contents(atPath: path), let utf = String(data: content, encoding: .utf8) {
                if utf == targetContent {
                    logger.info("client.config is up-to-date")
                    return true
                }
            }
        }

        // This probably need to be more lenient in the future and allow other file content
        logger.info("Updating client.config")
        do {
            try FileManager.default.removeItem(atPath: path)
        }
        catch {
        }
        FileManager.default.createFile(atPath: path, contents: targetContent.data(using: .utf8))
        return false
    }
}
