//
//  SketchArtist.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SketchArtist: ICardWithHighlight, ISpellSchoolTutor, ICardGenerator {
    required init() {}
    
    func getCardId() -> String {
        return CardIds.Collectible.Warlock.SketchArtist
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.spellSchool == SpellSchool.shadow)
    }
    
    var tutoredSpellSchools: [Int] {
        return [SpellSchool.shadow.rawValue]
    }
    
    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.type == .spell &&
               card.spellSchool == SpellSchool.shadow &&
        card.isCardLegal(gameType: gameMode, format: format)
    }

    func isInGeneratorPool(_ card: MultiIdCard, _ gameMode: GameType, _ format: FormatType) -> Bool {
        return card.ids.any { c in isInGeneratorPool(Card(id: c), gameMode, format) }
    }    
}
