//
//  BattlegroundsTierTriples.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/27/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsTierTriples: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var box: NSBox!
    @IBOutlet weak var tierImage: NSImageView!
    @IBOutlet weak var tripleLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var tripleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tripleImage: NSImageView!
    @IBOutlet weak var tripleBlackImage: NSImageView!
    @IBOutlet weak var qtyText: NSTextField!
    @IBOutlet weak var turnText: NSTextField!

    @IBInspectable var tier: Int = 1
    var turn = 0
    var qty = 0
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsTierTriples", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        
        update()
    }

    func update() {
        guard let rp = Bundle.main.resourcePath else {
            return
        }

        if let image = NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-\(tier).png") {
            tierImage.image = image
        }
        box.fillColor = turn > 0 ? NSColor.fromHexString(hex: "#37393C")! : NSColor.fromHexString(hex: "#282b2e")!
        tripleLeftConstraint.constant = turn > 0 ? 0 : 12
        tripleTopConstraint.constant = turn > 0 ? 2 : 7
        tierImage.alphaValue = turn > 0 ? 1 : 0.5
        tripleImage.isHidden = turn > 0 ? false : true
        tripleBlackImage.isHidden = tripleImage.isHidden
        qtyText.isHidden = tripleImage.isHidden
        turnText.isHidden = tripleImage.isHidden
        tripleBlackImage.alphaValue = qty > 0 ? 0 : 0.2
        qtyText.stringValue = turn > 0 ? "\(qty)" : ""
        turnText.stringValue = String(format: NSLocalizedString("Turn %d", comment: ""), turn)
    }
}
