//
//  Secret.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift

class Secret {

    private(set) var cardId: String
    var count: Int

    init(cardId: String, count: Int) {
        self.cardId = cardId
        self.count = count
    }

    var activeDeckIsConstructed: Bool {
        guard let deck = Game.instance.currentDeck else { return false }

        return !deck.isArena
    }

    func adjustedCount(game: Game) -> Int {
        return ((game.currentGameMode == .casual || game.currentGameMode == .ranked
                || game.currentGameMode == .friendly || game.currentGameMode == .practice
                || activeDeckIsConstructed)
            && game.opponent.revealedEntities.filter { $0.id < 68 && $0.cardId == self.cardId }
                .count >= 2) ? 0 : self.count
    }
}
