//
//  WotogCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/26/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class WotogCounter: OverWindowController {
    @objc dynamic var jadeVisibility = false
    @objc dynamic var jade = 0
    @objc dynamic var cthunVisibility = false
    @objc dynamic var cthunAttack = 6
    @objc dynamic var cthunHealth = 6
    @objc dynamic var spellsVisibility = false
    @objc dynamic var spellsCounter = 0
    @objc dynamic var pogoVisibility = false
    @objc dynamic var pogoCounter = 0
    @objc dynamic var galakrondVisibility = false
    @objc dynamic var galakrondCounter = 0
    @objc dynamic var libramVisibility = false
    @objc dynamic var libramCounter = 0
    @objc dynamic var abyssalVisibility = false
    @objc dynamic var abyssalCurse = 0
    @objc dynamic var excavateVisibility = false
    @objc dynamic var excavate = 0
    var excavateTier = 0
    @objc dynamic var excavateTierVisibility = false
    @objc dynamic var excavateTierLabel = ""
    @objc dynamic var spellSchoolsVisibility = false
    var _spellSchools = [SpellSchool]()
    var spellSchools: [SpellSchool] {
        get {
            return _spellSchools
        }
        set {
            if newValue == _spellSchools {
                return
            }
            self.willChangeValue(for: \.spellSchoolsLabel)
            _spellSchools = newValue
            self.didChangeValue(for: \.spellSchoolsLabel)
        }
    }
    @objc dynamic var spellSchoolsLabel: String {
        if _spellSchools.count == 0 {
            return String.localizedString("Counter_Spell_School_None", comment: "")
        }
        return _spellSchools.compactMap { x in
            x.localizedText()
        }.sorted { $0 < $1 }.joined(separator: ", ")
    }
    
    func updateExcavateTierLabel() {
        var label = ""
        switch excavateTier {
        case 0:
            label = String.localizedString("Counter_Excavate_Tier0", comment: "")
        case 1:
            label = String.localizedString("Counter_Excavate_Tier1", comment: "")
        case 2:
            label = String.localizedString("Counter_Excavate_Tier2", comment: "")
        case 3:
            label = String.localizedString("Counter_Excavate_Tier3", comment: "")
        default:
            label = "\(excavateTier + 1)"
        }
        if label != excavateTierLabel {
            excavateTierLabel = label
        }
    }
}
