//
//  Statistic.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Statistic {
    var gameResult: GameResult = .Unknow
    var hasCoin: Bool = false
    var opponentClass: String = ""
    var opponentName: String = ""
    var playerRank: Int = 0
    var playerMode: GameMode = .None
    var date = NSDate()

    func toDict() -> [String: AnyObject] {
        return [
            "opponentName": self.opponentName,
            "opponentClass": self.opponentClass,
            "gameResult": self.gameResult.rawValue,
            "hasCoin": Int(self.hasCoin),
            "playerRank": self.playerRank,
            "playerMode": self.playerMode.rawValue,
            "date": date.timeIntervalSince1970
        ]
    }

    static func fromDict(dict: [String: AnyObject]) -> Statistic? {
        if let opponentName = dict["opponentName"] as? String,
            let opponentClass = dict["opponentClass"] as? String,
            let gameResult = dict["gameResult"] as? Int,
            let hasCoin = dict["hasCoin"] as? Int,
            let playerRank = dict["playerRank"] as? Int,
            let playerMode = dict["playerMode"] as? Int,
            let date = dict["date"] as? Double {
                let statistic = Statistic()
                statistic.opponentName = opponentName
                statistic.opponentClass = opponentClass
                statistic.gameResult = GameResult(rawValue: gameResult)!
                statistic.hasCoin = Bool(hasCoin)
                statistic.playerRank = playerRank
                statistic.playerMode = GameMode(rawValue: playerMode)!
                statistic.date = NSDate(timeIntervalSince1970: date)
                return statistic
        }
        return nil
    }
}