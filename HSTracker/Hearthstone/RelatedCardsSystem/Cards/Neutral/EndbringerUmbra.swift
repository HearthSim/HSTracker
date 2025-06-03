//
//  EndbringerUmbra.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/3/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class EndbringerUmbra: ResurrectionCard {
    override func getCardId() -> String {
        CardIds.Collectible.Neutral.EndbringerUmbra
    }

    override func filterCard(card: Card) -> Bool {
        card.hasDeathrattle()
    }

    override func resurrectsMultipleCards() -> Bool {
        true
    }
}
