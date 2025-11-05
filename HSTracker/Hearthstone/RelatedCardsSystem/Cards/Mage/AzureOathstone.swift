//
//  AzureOathstone.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class AzureOathstone: ResurrectionCard {
    override func getCardId() -> String {
        CardIds.NonCollectible.Mage.AzureQueenSindragosa_AzureOathstoneToken
    }

    required init() {
        super.init()
    }

    override func filterCard(card: Card) -> Bool {
        return card.isDragon()
    }

    override func resurrectsMultipleCards() -> Bool {
        true
    }
}
