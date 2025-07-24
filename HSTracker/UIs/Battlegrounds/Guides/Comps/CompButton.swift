//
//  CompButton.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/12/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CompButton: NSCollectionViewItem {
        
    @IBOutlet var background: NSImageView!
    @IBOutlet var name: NSTextField!
    
    weak var owner: CompsGuides?
    
    var viewModel: BattlegroundsCompGuideViewModel?
    
    private lazy var trackingArea: NSTrackingArea = {
        return NSTrackingArea(rect: view.bounds,
                              options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)
    }()
    
    func update(_ comp: BattlegroundsCompGuideViewModel, _ owner: CompsGuides) {
        viewModel = comp
        self.owner = owner
        
        let gradient = CAGradientLayer()
        
        gradient.colors = [ NSColor.fromHexString(hex: "292d30")!.cgColor, NSColor.clear.cgColor ]
        gradient.startPoint = NSPoint(x: 0.0, y: 0.0)
        gradient.endPoint = NSPoint(x: 0.7, y: 0.0)
        gradient.locations = [ 0.5, 1.0 ]
        gradient.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 202, height: 48))
        background.wantsLayer = true
        background.layer?.opacity = 0.2
        background.layer?.mask = gradient
        
        name.stringValue = comp.compGuide.name

        ImageUtils.art(for: comp.cardAsset, completion: { img in
            DispatchQueue.main.async {
                self.background.image = img
            }
        })
        
        if !view.trackingAreas.contains(trackingArea) {
            view.addTrackingArea(trackingArea)
        }
    }
    
    // MARK: - mouse hover
    override func mouseEntered(with event: NSEvent) {
        background.layer?.opacity = 0.6
    }

    override func mouseExited(with event: NSEvent) {
        background.layer?.opacity = 0.2
    }

    override func mouseUp(with event: NSEvent) {
        if let owner, let viewModel {
            owner.showComp(viewModel)
        }
    }
}
