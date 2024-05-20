//
//  BattlegroundsHeroPickState.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsHeroPickState {
    private(set) var pickedHeroDbfId: Int?
    private(set) var offeredHeroDbfIds: [Int]?

    private let game: Game

    init(_ game: Game) {
        self.game = game
    }

    func snapshotOfferedHeroes(_ heroes: [Entity]) -> [Int] {
        let offered = heroes.sorted(by: { (a, b) -> Bool in a.zonePosition < b.zonePosition }).compactMap { x in x.card.dbfId }
        offeredHeroDbfIds = offered
        return offered
    }

    func snapshotPickedHero() -> Int? {
        pickedHeroDbfId = game.player.hero?.card.dbfId
        return pickedHeroDbfId
    }
}
