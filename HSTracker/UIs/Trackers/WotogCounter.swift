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
    
    func updateExcavateTierLabel() {
        var label = ""
        switch excavateTier {
        case 0:
            label =  NSLocalizedString("Counter_Excavate_Tier0", comment: "")
        case 1:
            label =  NSLocalizedString("Counter_Excavate_Tier1", comment: "")
        case 2:
            label =  NSLocalizedString("Counter_Excavate_Tier2", comment: "")
        case 3:
            label =  NSLocalizedString("Counter_Excavate_Tier3", comment: "")
        default:
            label = "\(excavateTier + 1)"
        }
        if label != excavateTierLabel {
            excavateTierLabel = label
        }
    }
}
