//
//  ConstructedMulliganGuide.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedMulliganGuide: OverWindowController {
    @IBOutlet var itemsStack: NSStackView!
    @IBOutlet var outerView: NSView!
    @IBOutlet var scaleView: NSView!
    @IBOutlet var visibilityToggleBox: ClickableBox!
    @IBOutlet var overlayMessage: ConstructedMulliganOverlayMessage!
    
    let viewModel = ConstructedMulliganGuideViewModel()
    
    @objc dynamic var statsVisibility: Bool {
        return viewModel.statsVisibility
    }
    
    @objc dynamic var visibilityToggleText: String {
        return viewModel.visibilityToggleText
    }
    
    @objc dynamic var visibilityToggleIcon: NSImage? {
        return NSImage(named: viewModel.visibilityToggleIcon)
    }
    
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
    override func updateFrames() {
//        self.window?.ignoresMouseEvents = false
    }
    
    override func awakeFromNib() {
        visibilityToggleBox.clicked = visibilityMouseUp
        overlayMessage.viewModel = viewModel.overlayMesageViewModel
    }
    
    func visibilityMouseUp(_ event: NSEvent) {
        let newVisibility = viewModel.statsVisibility ? false : true
        willChangeValue(forKey: "visibilityToggleText")
        willChangeValue(forKey: "visibilityToggleIcon")
        willChangeValue(forKey: "statsVisibility")
        viewModel.statsVisibility = newVisibility
        didChangeValue(forKey: "visibilityToggleText")
        didChangeValue(forKey: "visibilityToggleIcon")
        didChangeValue(forKey: "statsVisibility")
        Settings.autoShowMulliganGuide = newVisibility
    }
    
    func updateScaling() {
        guard let window, let cardStats = viewModel.cardStats, cardStats.count > 0 else {
            logger.debug("Missing either window or card stats")
            return
        }
        let bounds = NSRect(x: 0, y: 0, width: 1016, height: 480)
        logger.debug("bounds: \(bounds)")
        let scale = SizeHelper.hearthstoneWindow.height / 1080
        let sw = bounds.width * scale
        let sh = bounds.height * scale
        let dx = 6.0 * scale
        let dy = 30.0 * scale
        scaleView.frame = NSRect(x: dx + (window.frame.width - sw) / 2, y: dy + (window.frame.height - sh) / 2, width: sw, height: sh)
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
//                    var index = 0
                    for vm in cardStats {
                        let view = ConstructedMulliganSingleCardStats(frame: NSRect(x: 0, y: 0, width: 212, height: 480), viewModel: vm)
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
