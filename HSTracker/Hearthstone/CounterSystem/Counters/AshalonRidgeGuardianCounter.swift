//
//  AshalonRidgeGuardianCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class AshalonRidgeGuardianCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        CardIds.NonCollectible.Shaman.SpiritoftheMountain_AshalonRidgeGuardianToken
    }

    override var relatedCards: [String] {
        []
    }

    private var adapts: [String] = []

    override func shouldShow() -> Bool {
        game.isTraditionalHearthstoneMatch && !adapts.isEmpty
    }

    override func valueToShow() -> String {
        ""
    }

    override func getCardsToDisplay() -> [String] {
        adapts
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        guard entity.card.id == CardIds.NonCollectible.Shaman.SpiritoftheMountain_PerfectEvolutionToken else { return }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            if tag == .tag_script_data_num_1 || tag == .tag_script_data_num_2 {
                guard let card = Cards.by(dbfId: value, collectible: false) else { return }
                adapts.append(card.id)
                onCounterChanged()
            }
        }
    }
}
