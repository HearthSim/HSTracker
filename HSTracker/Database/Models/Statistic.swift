//
//  Statistic.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Unbox

final class Statistic: Unboxable {
    var gameResult: GameResult = .Unknow
    var hasCoin = false
    var opponentClass = ""
    var opponentName = ""
    var playerRank = 0
    var playerMode: GameMode = .None
    var numTurns = 0
    var date: NSDate?
    var cards: [String: Int] = [:]
    var duration = 0

    init(unboxer: Unboxer) {
        self.gameResult = unboxer.unbox("gameResult")
        self.hasCoin = unboxer.unbox("hasCoin")
        self.opponentClass = unboxer.unbox("opponentClass")
        self.opponentName = unboxer.unbox("opponentName")
        self.playerRank = unboxer.unbox("playerRank")
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
    }

    init() {
        date = NSDate()
    }
}
