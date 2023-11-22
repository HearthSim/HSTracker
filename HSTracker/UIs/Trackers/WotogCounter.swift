//
//  WotogCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/26/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class WotogCounter: OverWindowController {
    @IBOutlet var abyssalView: NSView!
    @IBOutlet var excavateView: NSView!
    
    @objc dynamic var abyssalVisibility = false
    @objc dynamic var abyssalCurse = ""
    @objc dynamic var excavateVisibility = false
    @objc dynamic var excavate = ""
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
