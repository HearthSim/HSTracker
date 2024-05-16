//
//  ConstructedMulliganGuide.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganGuidePreLobby: OverWindowController {
    @IBOutlet weak var stack1: NSStackView!
    @IBOutlet weak var stack2: NSStackView!
    @IBOutlet weak var stack3: NSStackView!
    @IBOutlet weak var outerView: NSView!
    @IBOutlet weak var scaleView: NSView!
    
    let viewModel = ConstructedMulliganGuidePreLobbyViewModel()
    
    var isVisible = false
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
    }
    
    func updateScaling() {
        guard window != nil else {
            logger.debug("Missing window")
            return
        }
        let rect = SizeHelper.constructedMulliganGuidePreLobbyFrame()
        let bounds = NSRect(x: 0, y: 0, width: rect.width/2.0, height: rect.height/2.0)
        logger.debug("bounds: \(bounds)")
        let scale = SizeHelper.hearthstoneWindow.height / 1080
        let sw = bounds.width * scale
        let sh = bounds.height * scale
        scaleView.frame = NSRect(x: 0, y: rect.height/2.0 - sh, width: sw, height: sh)
        logger.debug("scaleView frame: \(scaleView.frame)")
        scaleView.bounds = bounds
        logger.debug("scaleView bounds: \(scaleView.bounds)")
        scaleView.needsDisplay = true
    }
    
    func update(_ property: String?) {
        let all = property == nil
        
        logger.debug("\(#function) - property \(property ?? "nil")")
        if property == "pageStatusRows" || all {
            if let stack1, let stack2, let stack3 {
                for old in stack1.arrangedSubviews {
                    old.removeFromSuperview()
                }
                for old in stack2.arrangedSubviews {
                    old.removeFromSuperview()
                }
                for old in stack3.arrangedSubviews {
                    old.removeFromSuperview()
                }

                let rows = viewModel.pageStatusRows
                var rowIndex = 0
                for row in rows {
                    for status in row {
                        let view = ConstructedMulliganSingleDeckStatus(frame: NSRect(x: 0, y: 0, width: 238, height: 96), status: status)
                        switch rowIndex {
                        case 0:
                            stack1.addArrangedSubview(view)
                        case 1:
                            stack2.addArrangedSubview(view)
                        case 2:
                            stack3.addArrangedSubview(view)
                        default:
                            continue
                        }
                    }
                    rowIndex += 1
                }
//                if viewModel.visibility {
//                    let rect = SizeHelper.constructedMulliganGuidePreLobbyFrame()
//                    AppDelegate.instance().coreManager.game.windowManager.show(controller: self, show: true, frame: rect, overlay: true)
//                    updateScaling()
//                    isVisible = true
//                    if deferred {
//                        DispatchQueue.main.async {
//                            self.update(nil)
//                            self.updateScaling()
//                        }
//                    }
//                } else if isVisible {
//                    AppDelegate.instance().coreManager.game.windowManager.show(controller: self, show: false)
//                    isVisible = false
//                }
            } else {
                deferred = true
            }
        }
    }
}
