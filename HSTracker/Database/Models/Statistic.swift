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
    var gameResult: GameResult = .Unknow
    var hasCoin = false
    var opponentClass: CardClass = .NEUTRAL
    var opponentRank: Int?
    var opponentLegendRank: Int?
    var opponentName = ""
    var legendRank: Int?
    var playerRank = 0
    var playerMode: GameMode = .None
    var numTurns = 0
    var date: NSDate?
    var cards: [String: Int] = [:]
    var duration = 0
    var note: String? = ""
    var season: Int?
    var hsReplayId: String?
    var deck: Deck?

    init() {
        date = NSDate()
    }

    init(unboxer: Unboxer) {
        self.gameResult = unboxer.unbox("gameResult")
        self.hasCoin = unboxer.unbox("hasCoin")
        if let cardClass: CardClass? = unboxer.unbox("opponentClass"),
            opponentClass = cardClass {
            self.opponentClass = opponentClass
        } else {
            let opponentClass: String = unboxer.unbox("opponentClass")
            self.opponentClass = CardClass(rawValue: opponentClass.uppercaseString) ?? .NEUTRAL
        }
        
        self.opponentName = unboxer.unbox("opponentName")
        self.opponentRank = unboxer.unbox("opponentRank")
        self.opponentLegendRank = unboxer.unbox("opponentLegendRank")
        self.playerRank = unboxer.unbox("playerRank")
        self.legendRank = unboxer.unbox("legendRank")
        self.playerMode = unboxer.unbox("playerMode")
        self.numTurns = unboxer.unbox("numTurns")
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        self.date = unboxer.unbox("date", formatter: dateFormatter)
        if self.date == nil {
            // support old version
            self.date = NSDate(timeIntervalSince1970: unboxer.unbox("date"))
        }
        self.cards = unboxer.unbox("cards")
        self.duration = unboxer.unbox("duration")
        self.note = unboxer.unbox("note")
        self.season = unboxer.unbox("season")
        if let date = self.date where self.season == nil {
            self.season = (date.year - 2014) * 12 - 3 + date.month
        }
        self.hsReplayId = unboxer.unbox("hsReplayId")
    }
}

extension Statistic: WrapCustomizable {
    func keyForWrappingPropertyNamed(propertyName: String) -> String? {
        if propertyName == "deck" {
            return nil
        }
        return propertyName
    }
}
