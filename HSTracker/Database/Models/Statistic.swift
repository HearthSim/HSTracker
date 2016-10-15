//
//  Statistic.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Unbox
import Wrap

final class Statistic: Unboxable {
    var gameResult: GameResult = .unknow
    var hasCoin = false
    var opponentClass: CardClass = .neutral
    var opponentRank: Int?
    var opponentLegendRank: Int?
    var opponentName = ""
    var legendRank: Int?
    var playerRank = 0
    var playerMode: GameMode = .none
    var numTurns = 0
    var date: Date?
    var cards: [String: Int] = [:]
    var duration = 0
    var note: String? = ""
    var season: Int?
    var hsReplayId: String?
    var deck: Deck?

    init() {
        date = Date()
    }

    init(unboxer: Unboxer) throws {
        self.gameResult = try unboxer.unbox(key: "gameResult")
        self.hasCoin = try unboxer.unbox(key: "hasCoin")
        do {
        let cardClass: CardClass = try unboxer.unbox(key: "opponentClass")
            self.opponentClass = cardClass
        } catch {
            let opponentClass: String = try unboxer.unbox(key: "opponentClass")
            self.opponentClass = CardClass(rawValue: opponentClass.lowercased()) ?? .neutral
        }
        
        self.opponentName = try unboxer.unbox(key: "opponentName")
        self.opponentRank = try unboxer.unbox(key: "opponentRank")
        self.opponentLegendRank = try unboxer.unbox(key: "opponentLegendRank")
        self.playerRank = try unboxer.unbox(key: "playerRank")
        self.legendRank = try unboxer.unbox(key: "legendRank")
        self.playerMode = try unboxer.unbox(key: "playerMode")
        self.numTurns = try unboxer.unbox(key: "numTurns")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        self.date = try unboxer.unbox(key: "date", formatter: dateFormatter)
        if self.date == nil {
            // support old version
            self.date = Date(timeIntervalSince1970: try unboxer.unbox(key: "date"))
        }
        self.cards = try unboxer.unbox(key: "cards")
        self.duration = try unboxer.unbox(key: "duration")
        self.note = try unboxer.unbox(key: "note")
        self.season = try unboxer.unbox(key: "season")
        if let date = self.date, self.season == nil {
            self.season = (date.year - 2014) * 12 - 3 + date.month
        }
        self.hsReplayId = try unboxer.unbox(key: "hsReplayId")
    }
}

extension Statistic: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        if propertyName == "deck" {
            return nil
        }
        return propertyName
    }
}
