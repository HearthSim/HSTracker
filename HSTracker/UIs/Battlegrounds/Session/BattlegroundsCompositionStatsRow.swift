//
//  BattlegroundsCompositionStatsRow.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompositionStatsRow: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var cardImage: NSImageView!
    @IBOutlet var nameLabel: NSTextField!
    @IBOutlet var statsBar: BattlegroundsCompositionStatsBar!
    @IBOutlet var avgPlacemetLabel: NSTextField!
    
    let viewModel: BattlegroundsCompositionStatsRowViewModel
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 240.0, height: 30.0)
    }
    
    init(viewModel: BattlegroundsCompositionStatsRowViewModel) {
        self.viewModel = viewModel
        
        super.init(frame: NSRect.zero)
        
        commonInit()
        update()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        guard Bundle.main.loadNibNamed("BattlegroundsCompositionStatsRow", owner: self, topLevelObjects: nil) else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = NSRect(x: 0, y: 0, width: 240, height: 34)
        addSubview(contentView)
        let gradient = CAGradientLayer()
        gradient.colors = [ NSColor.fromHexString(hex: "#141617")!.cgColor, NSColor.clear.cgColor ]
        gradient.startPoint = NSPoint(x: 0, y: 0)
        gradient.endPoint = NSPoint(x: 1, y: 0)
        gradient.frame = cardImage.frame
        cardImage.wantsLayer = true
        cardImage.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
        cardImage.layer?.mask = gradient
    }

    private func update() {
        guard let card = Cards.by(dbfId: viewModel.minionDbfId, collectible: false) else {
            return
        }
        ImageUtils.tile(for: card.id, completion: { image in
            DispatchQueue.main.async {
                if let image = image?.copy() as? NSImage {
                    let r = image.size
                    self.cardImage.image = image.crop(rect: CGRect(x: 80.0, y: 5, width: r.width - 80.0, height: r.height - 5.0))
                }
            }
        })

        nameLabel.stringValue = viewModel.name
        avgPlacemetLabel.stringValue = viewModel.avgPlacement
        avgPlacemetLabel.textColor = NSColor.fromHexString(hex: viewModel.avgPlacementColor) ?? NSColor.white
        
        statsBar.maxPercent = viewModel.maxBarPercentage
        statsBar.percent = viewModel.firstPlacePercent
    }
}
