//
//  BattlegroundsCompositionPopularityRow.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import CoreImage

class BattlegroundsCompositionPopularityRow: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var cardImage: NSImageView!
    @IBOutlet var tribeXImage: NSImageView!
    
    @IBOutlet var nameLabel: NSTextField!
    
    @IBOutlet var popularityBar: BattlegroundsCompositionPopularityBar!
    
    @IBOutlet var popularityLabel: NSTextField!
    
    let viewModel: BattlegroundsCompositionPopularityRowViewModel
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 252, height: 24)
    }
    
    init(frame: NSRect, viewModel: BattlegroundsCompositionPopularityRowViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        commonInit()
    }
    
    override func awakeFromNib() {
        update()
    }
    
    private func commonInit() {
        NibHelper.loadNib(Self.self, self)
        
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = self.bounds
        addSubview(contentView)

        let gradient = CAGradientLayer()
        gradient.colors = [ NSColor.black.cgColor, NSColor.clear.cgColor ]
        gradient.startPoint = NSPoint(x: 0, y: 0)
        gradient.endPoint = NSPoint(x: 0.85, y: 0)
        gradient.locations = [ 0.5, 1.0 ]
        gradient.frame = cardImage.bounds
        cardImage.wantsLayer = true
        cardImage.layer?.mask = gradient
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        tribeXImage.isHidden = !viewModel.compositionUnavailableVisibility
        ImageUtils.tile(for: viewModel.cardImage, completion: { img in
            DispatchQueue.main.async {
                if let img = img?.copy() as? NSImage {
                    self.cardImage.image = img
                }
            }
        })
        cardImage.alphaValue = viewModel.opacity
        nameLabel.alphaValue = viewModel.opacity
        popularityBar.alphaValue = viewModel.opacity
        popularityLabel.alphaValue = viewModel.opacity
        nameLabel.stringValue = viewModel.name
        popularityLabel.stringValue = viewModel.popularityText
        popularityBar.highlight = viewModel.compositionAvailable
        popularityBar.progress = viewModel.popularityBarValue
    }
}
