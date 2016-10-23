//
//  Statistic.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift

class Statistic: Object {

    private dynamic var _gameResult = GameResult.unknow.rawValue
    var gameResult: GameResult {
        get { return GameResult(rawValue: _gameResult)! }
        set { _gameResult = newValue.rawValue }
    }

    dynamic var hasCoin = false

    private dynamic var _opponentClass = CardClass.neutral.rawValue
    var opponentClass: CardClass {
        get { return CardClass(rawValue: _opponentClass)! }
        set { _opponentClass = newValue.rawValue }
    }
    var opponentRank = RealmOptional<Int>()
    var opponentLegendRank = RealmOptional<Int>()
    dynamic var opponentName = ""
    var legendRank = RealmOptional<Int>()
    dynamic var playerRank = 0

    private dynamic var _playerMode = GameMode.none.rawValue
    var playerMode: GameMode {
        get { return GameMode(rawValue: _playerMode)! }
        set { _playerMode = newValue.rawValue }
    }

    dynamic var numTurns = 0
    dynamic var date = Date()
    let cards = List<RealmCard>()
    dynamic var duration = 0
    dynamic var note = ""
    var season = RealmOptional<Int>()
    dynamic var hsReplayId: String? = nil
    
    let deck = LinkingObjects(fromType: Deck.self, property: "statistics")
}
