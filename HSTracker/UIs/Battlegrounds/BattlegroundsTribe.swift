//
//  BattlegroundsTribe.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/12/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTribe: NSView {
    
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var tribeImage: NSImageView!
    @IBOutlet weak var tribeLabel: NSTextField!
    @IBOutlet weak var tribesX: NSImageView!
    private var race = Race.invalid
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsTribe", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.isHidden = true
    }
    
    func setRace(newRace: Race, _ available: Bool) {
        if newRace != race {
            race = newRace
            if race == .invalid {
                contentView.isHidden = true
                tribeImage.image = nil
                tribeLabel.stringValue = "?"
            } else {
                contentView.isHidden = false
                tribeImage.image = NSImage(named: "tribe_\(race)")
                tribeLabel.stringValue = String.localizedString("\(race)", comment: "tribe")
                tribeLabel.fitTextToBounds()
            }
        }
        tribesX.isHidden = available
    }
}
