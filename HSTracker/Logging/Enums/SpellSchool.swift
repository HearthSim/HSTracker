//
//  SpellSchool.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/29/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

enum SpellSchool: Int {
    case none = 0,
         arcane = 1,
         fire = 2,
         frost = 3,
         nature = 4,
         holy = 5,
         shadow = 6,
         fel = 7,
         physical_combat = 8
    
    func localizedText() -> String? {
        switch self {
        case .none:
            return nil
        case .arcane:
            return String.localizedString("Spell_School_Arcane", comment: "")
        case .fire:
            return String.localizedString("Spell_School_Fire", comment: "")
        case .frost:
            return String.localizedString("Spell_School_Frost", comment: "")
        case .nature:
            return String.localizedString("Spell_School_Nature", comment: "")
        case .holy:
            return String.localizedString("Spell_School_Holy", comment: "")
        case .shadow:
            return String.localizedString("Spell_School_Shadow", comment: "")
        case .fel:
            return String.localizedString("Spell_School_Fel", comment: "")
        case .physical_combat:
            return String.localizedString("Spell_School_Physical_Combat", comment: "")
        }
    }
}
