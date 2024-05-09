//
//  BattlegroundsGameView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/14/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import CoreImage

@IBDesignable
class NSImageViewScaleAspectFill: NSImageView {

    @IBInspectable
    var scaleAspectFill: Bool = false

    override func awakeFromNib() {
        // Scaling : .scaleNone mandatory
        if scaleAspectFill { self.imageScaling = .scaleNone }
    }

    override func draw(_ dirtyRect: NSRect) {

        if scaleAspectFill, let image = self.image {

            // Compute new Size
            let imageViewRatio   = image.size.height / image.size.width
            let nestedImageRatio = self.bounds.size.height / self.bounds.size.width
            var newWidth         = image.size.width
            var newHeight        = image.size.height

            if imageViewRatio > nestedImageRatio {

                newWidth = self.bounds.size.width
                newHeight = self.bounds.size.width * imageViewRatio
            } else {

                newWidth = self.bounds.size.height / imageViewRatio
                newHeight = self.bounds.size.height
            }

            image.size.width  = newWidth
            image.size.height = newHeight

        }

        // Draw AFTER resizing
        super.draw(dirtyRect)
    }
}

class BattlegroundsGameView: NSView {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet var heroImage: NSImageView!
    @IBOutlet var heroName: NSTextField!
    @IBOutlet var placementText: NSTextField!
    @IBOutlet var mmrText: NSTextField!
    @IBOutlet var crownImage: NSImageView!
    
    static let placementLow = NSColor(red: 109.0/255.0, green: 235.0/255.0, blue: 108.0/255.0, alpha: 1.0)
    static let placementHigh = NSColor(red: 236.0/255.0, green: 105.0/255.0, blue: 105.0/255.0, alpha: 1.0)
    static let mmrPositive = NSColor(red: 139.0/255.0, green: 210.0/255.0, blue: 134.0/255.0, alpha: 1.0)
    static let mmrNegative = NSColor(red: 236.0/255.0, green: 105.0/255.0, blue: 105.0/255.0, alpha: 1.0)
        
    var game: BattlegroundsLastGames.GameItem?
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 240, height: 34)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard frame.height > 0 && !frame.height.isNaN else {
            return
        }
        
        guard !event.locationInWindow.y.isNaN else {
            return
        }
        
        guard let finalBoard = game?.finalBoard else {
            return
        }
        
        var minions = [Entity]()
        for minion in finalBoard.minions {
            let entity = Entity()
            entity.cardId = minion.cardId
            for tag in minion.tags {
                if let gt = GameTag(rawValue: tag.tag) {
                    entity[gt] = tag.value
                }
            }
            minions.append(entity)
        }

        let wm = AppDelegate.instance().coreManager.game.windowManager
        let fb = wm.battlegroundsFinalBoard
        fb.setBoard(board: minions, endTime: game?.endTime)
        let window = wm.battlegroundsSession.window!
        let rect = convert(bounds, to: nil)
        let screenRect = window.convertToScreen(rect)
        let size = NSSize(width: 378, height: 125)
        var x: CGFloat = rect.maxX + 10
        if let screenFrame = self.window?.screen?.frame ?? NSScreen.main?.frame, x + size.width >= screenFrame.maxX {
            x = window.frame.minX - 10 - size.width
        }
        AppDelegate.instance().coreManager.game.windowManager.show(controller: fb, show: true, frame: NSRect(x: screenRect.minX + x, y: screenRect.minY, width: size.width, height: size.height), title: nil, overlay: true)
    }
    
    override func mouseExited(with event: NSEvent) {
        let wm = AppDelegate.instance().coreManager.game.windowManager
        wm.show(controller: wm.battlegroundsFinalBoard, show: false)
    }
    
    private func commonInit() {
        guard Bundle.main.loadNibNamed("BattlegroundsGameView", owner: self, topLevelObjects: nil) else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = NSRect(x: 0, y: 0, width: 200, height: 34)
        addSubview(contentView)
        let gradient = CAGradientLayer()
        gradient.colors = [ NSColor.fromHexString(hex: "#000000", alpha: 170.0/255.0)!.cgColor, NSColor.clear.cgColor ]
        gradient.startPoint = NSPoint(x: 0, y: 0)
        gradient.endPoint = NSPoint(x: 1, y: 0)
        gradient.frame = heroImage.frame
        heroImage.wantsLayer = true
        heroImage.layer?.mask = gradient
    }
    
    func update(game: BattlegroundsLastGames.GameItem) {
        self.game = game
        var heroCard = Cards.by(cardId: game.hero)
        if heroCard?.battlegroundsSkinParentId ?? 0 > 0 {
            heroCard = Cards.by(dbfId: heroCard!.battlegroundsSkinParentId, collectible: false)
        }
        guard let heroCard = heroCard else {
            return
        }
        guard heroName != nil else {
            return
        }
        ImageUtils.tile(for: heroCard.id, completion: { image in
            DispatchQueue.main.async {
                self.heroImage.image = image
            }
        })
        let heroShortNameMap = RemoteConfig.data?.battlegrounds_short_names?.first(where: { x in x.dbf_id == heroCard.dbfId })
        heroName.stringValue = heroShortNameMap?.short_name ?? heroCard.name
        placementText.stringValue = String.localizedString("Battlegrounds_Game_Ordinal_\(game.placement)", comment: "")
        let mmrDelta = game.ratingAfter - game.rating
        let signal = mmrDelta > 0 ? "+" : ""
        mmrText.stringValue = "\(signal)\(mmrDelta)"
        crownImage.isHidden = game.placement != 1
        var win = game.duos ?? false ? game.placement <= 2 : game.placement <= 4
        placementText.textColor = win ?  BattlegroundsGameView.placementLow : BattlegroundsGameView.placementHigh
        mmrText.textColor = mmrDelta == 0 ? NSColor.white : mmrDelta > 0 ? BattlegroundsGameView.mmrPositive : BattlegroundsGameView.mmrNegative
        
        if let superview = superview {
            superview.topAnchor.constraint(equalTo: topAnchor).isActive = true
            superview.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        }
    }
}
