//
//  ICardWithRelatedCards.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol ICardWithRelatedCards: ICard {
    init()
    func shouldShowForOpponent(opponent: Player) -> Bool
    func getRelatedCards(player: Player) -> [Card?]
}
