//
//  BattlegroundsQuestPicking.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/15/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsQuestPicking: OverWindowController {
    
    @IBOutlet weak var itemsStack: NSStackView!
    @IBOutlet weak var overlayMessage: OverlayMessage!
    
    let viewModel = BattlegroundsQuestPickingViewModel()
    
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
        if property == "quests" || all {
            if let itemsStack = itemsStack {
                for old in itemsStack.arrangedSubviews {
                    old.removeFromSuperview()
                }
                
                if let quests = viewModel.quests {
                    for quest in quests {
                        let questView = BattlegroundsSingleQuestView(frame: NSRect(x: 0, y: 0, width: 273, height: 880), viewModel: quest)
                        itemsStack.addArrangedSubview(questView)
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
                        self.update("quests")
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
