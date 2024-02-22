//
//  Helper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/16/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Helper {
    static func getCurrentRegion() -> Region {
        for _ in 0..<10 {
            if let accId = MirrorHelper.getAccountId() {
                let region = getRegion(hi: accId.hi.int64Value)
                logger.debug("Region: \(region)")
                return region
            }
            Thread.sleep(forTimeInterval: 2)
        }
        return Region.unknown
    }
    
    static func getRegion(hi: Int64) -> Region {
        return Region(rawValue: Int((hi >> 32)&255)) ?? .unknown
    }
    
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
        let path = URL(fileURLWithPath: Settings.hearthstonePath).appendingPathComponent("client.config", isDirectory: false).path
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
        } catch {
        }
        FileManager.default.createFile(atPath: path, contents: targetContent.data(using: .utf8))
        return false
    }
    
    static func getWinrateDeltaColorString(delta: Double, intensity: Int) -> String {
        // Adapted from HSReplay.net
        let colorWinrate = 50 + max(-50, min(50, 5 * delta))
        let severity = abs(0.5 - colorWinrate / 100) * 2

        func  scale(_ x: Double, _ from: Double, _ to: Double) -> Double {
            return from + (to - from) * pow(x, 1.0 - Double(intensity) / 100.0)
        }
        func scaleTriple(_ x: Double, _ from: [Double], _ to: [Double]) -> [Double] {
            return [ scale(x, from[0], to[0]), scale(x, from[1], to[1]), scale(x, from[2], to[2]) ]
        }
        let positive = [ 120.0, 70.0, 40.0 ]
        let neutral = [ 90.0, 100.0, 30.0 ]
        let negative = [ 0.0, 100.0, 65.7 ]

        let hsl = delta > 0
            ? scaleTriple(severity, neutral, positive)
            : delta < 0
                ? scaleTriple(severity, neutral, negative)
                : neutral

        return hslToColorString(hue: hsl[0], saturation: hsl[1], lightness: hsl[2])
    }
    
    static func hslToColorString(hue: Double, saturation: Double, lightness: Double) -> String {
        // Adapted from https://drafts.csswg.org/css-color/#hsl-to-rgb
        var h = hue
        var s = saturation
        var l = lightness
        
        h = h.truncatingRemainder(dividingBy: 360)
        if h < 0 {
            h += 360
        }

        s /= 100
        l /= 100

        func f(_ n: Double) -> Double {
            let k = (n + h / 30).truncatingRemainder(dividingBy: 12)
            let a = s * min(l, 1 - l)
            return l - a * max(-1, min(min(k - 3, 9 - k), 1))
        }

        let r = (f(0) * 255)
        let g = (f(8) * 255)
        let b = (f(4) * 255)

        return String(format: "#%2X%2X%2X", r, g, b)
    }
}
