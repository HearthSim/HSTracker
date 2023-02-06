//
//  BattlegroundsHeroPicking.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/19/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsHeroPicking: OverWindowController {
    
    @IBOutlet weak var itemsStack: NSStackView!
    @IBOutlet weak var overlayMessage: OverlayMessage!
    @IBOutlet weak var outerView: NSView!
    @IBOutlet weak var scaleView: NSView!
    
    let viewModel = BattlegroundsHeroPickingViewModel()
    
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
    
    override func awakeFromNib() {
        overlayMessage.viewModel = viewModel.message
    }
    
    func update(_ property: String?) {
        let all = property == nil
        
        logger.debug("\(#function) - property \(property ?? "nil")")
        if property == "heroStats" || all {
            if let itemsStack = itemsStack {
                for old in itemsStack.arrangedSubviews {
                    old.removeFromSuperview()
                }
                
                if let heroes = viewModel.heroStats {
                    for hero in heroes {
                        let heroView = BattlegroundsSingleHeroStats(frame: NSRect(x: 0, y: 0, width: 266, height: 480), viewModel: hero)
                        itemsStack.addArrangedSubview(heroView)
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
                isVisible = true
                if deferred {
                    DispatchQueue.main.async {
                        self.update("heroStats")
                        self.deferred = false
                    }
                }
            } else if isVisible {
                AppDelegate.instance().coreManager.game.windowManager.show(controller: self, show: false)
                isVisible = false
            }
        }
    }

}
