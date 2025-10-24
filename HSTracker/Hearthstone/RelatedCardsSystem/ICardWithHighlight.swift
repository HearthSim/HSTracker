//
//  ICardWithHighlight.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol ICardWithHighlight: ICard {
    init()
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor
}

protocol ISpellSchoolTutor: ICardWithHighlight {
    var tutoredSpellSchools: [Int] { get }
}
