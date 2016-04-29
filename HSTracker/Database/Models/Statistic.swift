//
//  Statistic.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

final class Statistic: Dictable {
    var gameResult: GameResult = .Unknow
    var hasCoin = false
    var opponentClass = ""
    var opponentName = ""
    var playerRank = 0
    var playerMode: GameMode = .None
    var numTurns = 0
    var date = NSDate()
    var cards = [String: Int]()
    var duration = 0

    func toDict() -> [String: AnyObject] {
        return [
            "opponentName": opponentName,
            "opponentClass": opponentClass,
            "gameResult": gameResult.rawValue,
            "hasCoin": Int(hasCoin),
            "playerRank": playerRank,
            "playerMode": playerMode.rawValue,
            "date": date.timeIntervalSince1970,
            "numTurns": numTurns,
            "cards": cards,
            "duration": duration
        ]
    }

    static func fromDict(dict: [String: AnyObject]) -> Statistic? {
        if let opponentName = dict["opponentName"] as? String,
            opponentClass = dict["opponentClass"] as? String,
            gameResult = dict["gameResult"] as? Int {
            let statistic = Statistic()
            statistic.opponentName = opponentName
            statistic.opponentClass = opponentClass
            statistic.gameResult = GameResult(rawValue: gameResult)!

            if let hasCoin = dict["hasCoin"] as? Int {
                statistic.hasCoin = Bool(hasCoin)
            }
            if let playerRank = dict["playerRank"] as? Int {
                statistic.playerRank = playerRank
            }
            if let playerMode = dict["playerMode"] as? Int {
                statistic.playerMode = GameMode(rawValue: playerMode)!
            }
            if let date = dict["date"] as? Double {
                statistic.date = NSDate(timeIntervalSince1970: date)
            }
            if let numTurns = dict["numTurns"] as? Int {
                statistic.numTurns = numTurns
            }
            if let duration = dict["duration"] as? Int {
                statistic.duration = duration
            }
            if let cards = dict["cards"] as? [String: Int] {
                statistic.cards = cards
            }
            return statistic
        }
        return nil
    }
}
