//
//  BattlegroundsTierTriples.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/27/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsQuestView: NSView {
    @IBOutlet var contentView: NSView!
    @IBOutlet var box: NSBox!
    @IBOutlet var questImage: NSImageView!
    @IBOutlet var questExclamationImage: NSImageView!
    @IBOutlet var turnText: NSTextField!
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 83, height: 108)
    }

    var turn = 0
    var dbfid = 0

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
        
        if let art = questImage {
            art.wantsLayer = true
            let rect = art.bounds
            let clipPath = NSBezierPath(ovalIn: NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height))
            let clipLayer = CAShapeLayer()
            clipLayer.frame = art.bounds
            clipLayer.path = clipPath.cgPath
            art.layer?.mask = clipLayer
        }
        
        update()
    }

    func update() {
        questImage.isHidden = dbfid > 0 ? false : true
        turnText.isHidden = turn == 0
        questImage.alphaValue = turn > 0 ? 1 : 0.5
        questExclamationImage.image = turn > 0 ? NSImage(named: "bacon_quest_exclamation") : NSImage(named: "bacon_quest_locked")
        turnText.stringValue = String(format: String.localizedString("Turn %d", comment: ""), turn)
        if let card = Cards.by(dbfId: dbfid, collectible: false) {
            if let artImg = ImageUtils.cachedArt(cardId: card.id) {
                questImage.image = artImg
            } else {
                ImageUtils.art(for: card.id, completion: { x in
                    if let img = x {
                        DispatchQueue.main.async {
                            self.questImage.image = img
                        }
                    }
                })
            }
        }

    }
}
