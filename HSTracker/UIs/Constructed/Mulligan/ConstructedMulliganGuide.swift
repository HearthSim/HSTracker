//
//  ConstructedMulliganGuide.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganGuide: OverWindowController {
    @IBOutlet weak var itemsStack: NSStackView!
    @IBOutlet weak var overlayMessage: OverlayMessage!
    @IBOutlet weak var outerView: NSView!
    @IBOutlet weak var scaleView: NSView!
    
    let viewModel = ConstructedMulliganGuideViewModel()
    
    private var isVisible = false
    private var deferred = false
    
    override init(window: NSWindow?) {
        super.init(window: window)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    func commonInit() {
        viewModel.propertyChanged = { name in
            DispatchQueue.main.async {
                self.update(name)
            }
        }
    }
    
    func updateScaling() {
        guard let window, let cardStats = viewModel.cardStats, cardStats.count > 0 else {
            logger.debug("Missing either window or card stats")
            return
        }
        let cnt = cardStats.count
        let bounds = NSRect(x: 0, y: 0, width: 16 + 266 * cnt + 16 * (cnt - 1), height: 480)
        logger.debug("bounds: \(bounds)")
        let scale = SizeHelper.hearthstoneWindow.height / 1080
        let sw = bounds.width * scale
        let sh = bounds.height * scale
        scaleView.frame = NSRect(x: (window.frame.width - sw) / 2, y: (window.frame.height - sh) / 2, width: sw, height: sh)
        logger.debug("scaleView frame: \(scaleView.frame)")
        scaleView.bounds = bounds
        scaleView.needsDisplay = true
    }
    
    func update(_ property: String?) {
        let all = property == nil
        
        logger.debug("\(#function) - property \(property ?? "nil")")
        if property == "cardStats" || all {
            if let itemsStack = itemsStack {
                for old in itemsStack.arrangedSubviews {
                    old.removeFromSuperview()
                }
                
                if let cardStats = viewModel.cardStats {
                    for _ in cardStats {
                        let view = ConstructedMulliganSingleCardStats(frame: NSRect(x: 0, y: 0, width: 266, height: 480))
                        itemsStack.addArrangedSubview(view)
                    }
                }
            } else {
                deferred = true
            }
        }
        
        if property == "visibility" {
            if viewModel.visibility {
                let rect = SizeHelper.hearthstoneWindow.frame
                AppDelegate.instance().coreManager.game.windowManager.show(controller: self, show: true, frame: rect, overlay: true)
                updateScaling()
                isVisible = true
                if deferred {
                    DispatchQueue.main.async {
                        self.update(nil)
                        self.updateScaling()
                    }
                }
            } else if isVisible {
                AppDelegate.instance().coreManager.game.windowManager.show(controller: self, show: false)
                isVisible = false
            }
        }
    }

}
