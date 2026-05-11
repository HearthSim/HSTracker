//
//  AnimalCompanionGenerator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class AnimalCompanionGenerator {

    func getRelatedCards(player: Player) -> [Card?] {
        let game = AppDelegate.instance().coreManager.game
        // Ensure we are looking at the local player
        guard player.id == game.player.id else {
            return []
        }

        // Find the AnimalCompanionCounter in the player's counter list
        let animalCompanionCounter = game.counterManager.playerCounters.first { $0 is AnimalCompanionCounter }
        
        // Cast and map the companion IDs to Card objects
        if let acCounter = animalCompanionCounter as? AnimalCompanionCounter {
            return acCounter.companions.map { Card(id: $0) }
        }

        return []
    }
}
