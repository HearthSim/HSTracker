//
//  MulliganState.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class MulliganState {
    var offeredCards = [Entity]()
    var keptCards = [Entity]()
    var finalCardsInHand = [Entity]()
    
    let game: Game
    
    init(game: Game) {
        self.game = game
    }
    
    func snapshotMulligan() {
        offeredCards = game.player.playerEntities.filter { x in
            x.isInHand && x.info.created }.sorted(by: { (a, b) -> Bool in
                a.zonePosition < b.zonePosition })
    }
    
    func snapshotMulliganChoices(choice: Choice) {
        keptCards = choice.chosenEntities
    }
    
    func snapshotOpeningHand() {
        finalCardsInHand = game.player.playerEntities.filter { x in x.isInHand && x.info.created }.sorted(by: { (a, b) -> Bool in
            a.zonePosition < b.zonePosition
        })
    }
}
