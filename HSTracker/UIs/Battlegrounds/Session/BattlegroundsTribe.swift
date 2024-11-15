//
//  BattlegroundsTribe.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/12/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTribe: NSView {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet var tribeImage: NSImageView!
    @IBOutlet var tribeLabel: NSTextField!
    @IBOutlet var tribesX: NSImageView!
    @IBOutlet var tribeBox: NSBox!
    
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
        NibHelper.loadNib(Self.self, self)

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
        if available {
            tribeBox.borderColor = NSColor.fromRgb(0x16, 0xd2, 0x20)
        } else {
            tribeBox.borderColor = NSColor.fromRgb(0xd4, 0x40, 0x40)
        }
    }
}
