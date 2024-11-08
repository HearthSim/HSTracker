//
//  DefaultCard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/5/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
 class DefaultCard: ICardWithRelatedCards {
     required init() {
     }
     
     public func getCardId() -> String {
         return ""
     }

     public func shouldShowForOpponent(opponent: Player) -> Bool {
         return false
     }

     public func getRelatedCards(player: Player) -> [Card?] {
         return []
     }
}
