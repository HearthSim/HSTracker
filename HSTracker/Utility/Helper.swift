//
//  Helper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/16/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

struct Helper {
    enum ColorStringMode {
        case DEFAULT, BATTLEGROUNDS
    }
    
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
    
    static func adjustSaturation(_ originalSaturation: Double, _ multiplier: Double) -> Double {
        let adjustedSaturation = originalSaturation * multiplier
        return min(adjustedSaturation, 100) // Ensure saturation does not exceed 100%
    }
    
    static func getColorString(delta: Double, intensity: Int) -> String {
        return getColorString(mode: ColorStringMode.DEFAULT, delta: delta, intensity: intensity)
    }
    
    static func getColorString(mode: ColorStringMode, delta: Double, intensity: Int, saturationMultiplier: Double = 1.0) -> String {
        // Adapted from HSReplay.net
        let colorWinrate = 50 + max(-50, min(50, 5 * delta))
        let severity = abs(0.5 - colorWinrate / 100) * 2
        
        func  scale(_ x: Double, _ from: Double, _ to: Double) -> Double {
            return from + (to - from) * pow(x, 1.0 - Double(intensity) / 100.0)
        }
        func scaleTriple(_ x: Double, _ from: [Double], _ to: [Double]) -> [Double] {
            return [
                scale(x, from[0], to[0]),
                scale(x, from[1], to[1]),
                scale(x, from[2], to[2])
            ]
        }
        var positive = [ Double ]()
        var neutral = [ Double ]()
        var negative = [ Double ]()
        switch mode {
        case .DEFAULT:
            positive = [ 120.0, adjustSaturation(70.0, saturationMultiplier), 40.0 ]
            neutral = [ 90.0, adjustSaturation(100.0, saturationMultiplier), 30.0 ]
            negative = [ 0.0, adjustSaturation(100.0, saturationMultiplier), 65.7 ]
        case .BATTLEGROUNDS:
            positive = [ 120.0, adjustSaturation(32.0, saturationMultiplier), 44.0 ]
            neutral = [ 60.0, adjustSaturation(32.0, saturationMultiplier), 44.0 ]
            negative = [ 0.0, adjustSaturation(32.0, saturationMultiplier), 44.0 ]
        }
        
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
        
        return String(format: "#%2X%2X%2X", Int(r), Int(g), Int(b))
    }
    
    static func resolveZilliax3000(_ cards: [Card], _ sideboards: [Sideboard]) -> [Card] {
        return cards.map { card in
            var result = card
            let cardId = card.id
            if cardId == CardIds.Collectible.Neutral.ZilliaxDeluxe3000 {
                if let sideboard = sideboards.first(where: { sb in sb.ownerCardId == cardId }), sideboard.cards.count > 0 {
                    let cosmetic = sideboard.cards.first { module in !module.zilliaxCustomizableFunctionalModule }
                    let modules = sideboard.cards.filter { module in module.zilliaxCustomizableFunctionalModule }
                    // Clone Zilliax with new cost, attack and health
                    result = cosmetic?.copy() ?? card.copy()
                    result.attack = modules.reduce(0, { $0 + $1.attack })
                    result.health = modules.reduce(0, { $0 + $1.health })
                    result.cost = modules.reduce(0, { $0 + $1.cost })
                }
            }
            return result
        }
    }
    
    static func urlEncode(_ str: String) -> String {
        var allowedQueryParamAndKey = CharacterSet.urlQueryAllowed
        allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$, ")
        return str.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey) ?? str
    }
    
    static func buildHsReplayNetUrl(_ path: String, _ campaign: String, _ queryParams: [String]?  = nil, _ fragmentParams: [String]? = nil) -> String {
        var url = "https://hsreplay.net"
        if !path.starts(with: "/") {
            url += "/"
        }
        url += path
        if url.last != "/" {
            url += "/"
        }
        return url + Helper.getHsReplayNetUrlParams(campaign, queryParams, fragmentParams)
    }
    
    static func getHsReplayNetUrlParams(_ campaign: String, _ queryParams: [String]? = nil, _ fragmentParams: [String]? = nil) -> String {
        var query = [
            "utm_source=hdt",
            "utm_medium=client"
        ]
        if !campaign.isBlank {
            query.append("utm_campaign=\(campaign)")
        }
        if let queryParams {
            query.append(contentsOf: queryParams)
        }
        var urlParams = "?" + query.joined(separator: "&")
        if let fragments = fragmentParams, fragments.count > 0 {
            urlParams += "#\(fragments.joined(separator: "&"))"
        }
        return urlParams
    }
    
    static func openBattlegroundsHeroPicker(heroIds: [Int], duos: Bool, anomalyDbfId: Int?, parameters: [String: String]?) {
        let queryParams = parameters?.compactMap { kv in "\(Helper.urlEncode(kv.key))=\(Helper.urlEncode(kv.value))"} ?? [String]()
        var fragmentParams = [ "heroes=\(heroIds.compactMap({ x in String(x)}).joined(separator: ","))" ]
        if let anomalyDbfId {
            fragmentParams.append("anomalyDbfId=\(anomalyDbfId)")
        }
        if let availableRaces = AppDelegate.instance().coreManager.game.availableRaces, availableRaces.count > 0 {
            let availableRacesAsList = availableRaces.compactMap { x in Int(Race.allCases.firstIndex(of: x)!) }.sorted(by: { (a, b) -> Bool in a < b }).compactMap { x in String(x) }
            fragmentParams.append("minionTypes=\(Helper.urlEncode(availableRacesAsList.joined(separator: ",")))")
        }
        let url = Helper.buildHsReplayNetUrl(duos ? "/battlegrounds/duos/heroes/" : "/battlegrounds/heroes/", "bgs_toast", queryParams, fragmentParams)
        NSWorkspace.shared.open(URL(string: url)!)
    }

    static func openBattlegroundsTimewarpPage(_ boardCards: [MirrorBoardCard]) {
        let cardIds = boardCards
            .compactMap { card in card.cardId }
            .filter { id in id.count > 0 }
            .unique()

        if cardIds.count == 0 {
            return
        }

        let timewarpCards = cardIds
            .compactMap { Cards.any(byId: $0) }

        let dbfIds = timewarpCards
            .compactMap { card in card.dbfId }

        let isMajorTimewarp = timewarpCards.any { card in card.techLevel == 5 }

        var fragmentParams = [
            "view=advanced",
            "searchTerm=\(dbfIds.compactMap { String($0) }.joined(separator: ","))"
        ]

        if isMajorTimewarp
        {
            fragmentParams.append("timewarp=major")
        }

        let url = Helper.buildHsReplayNetUrl("/battlegrounds/timewarp/", "bgs_timewarp_toast", nil, fragmentParams)
        NSWorkspace.shared.open(URL(string: url)!)
    }
}
