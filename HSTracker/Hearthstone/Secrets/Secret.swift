//
//  Secret.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Secret {

    private(set) var cardId: String
    var count: Int

    init(cardId: String, count: Int) {
        self.cardId = cardId
        self.count = count
    }

    var activeDeckIsConstructed: Bool {
        return Game.instance.activeDeck != nil && !Game.instance.activeDeck!.isArena
    }

    func adjustedCount(game: Game) -> Int {
        return (Settings.instance.autoGrayoutSecrets
            && (game.currentGameMode == .Casual || game.currentGameMode == .Ranked
                || game.currentGameMode == .Friendly || game.currentGameMode == .Practice || activeDeckIsConstructed)
            && game.opponent.revealedCards.filter { $0.entity != nil }
                .filter { $0.entity!.id < 68 && $0.entity!.cardId == self.cardId }
                .count >= 2) ? 0 : self.count
    }
}