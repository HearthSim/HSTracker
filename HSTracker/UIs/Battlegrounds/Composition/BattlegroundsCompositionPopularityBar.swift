//
//  BattlegroundsCompositionPopularityBar.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompositionPopularityBar: NSView {
    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var barRect: NSBox!
    
    var borderColor: NSColor {
        return highlight ? NSColor.fromHexString(hex: "#66FFFFFF")! : NSColor.fromHexString(hex: "#28FFFFFF")!
    }
    
    var gradientColorTop: NSColor {
        return highlight ? NSColor.fromHexString(hex: "#CCC58DC9")! : NSColor.fromHexString(hex: "#CC78577A")!
    }
    var gradientColorBottom: NSColor {
        return highlight ? NSColor.fromHexString(hex: "#FFC58DC9")! : NSColor.fromHexString(hex: "#CC78577A")!
    }
    
    private var _highlight = false
    var highlight: Bool {
        get {
            return _highlight
        }
        set {
            _highlight = newValue
            onHighlightChanged()
        }
    }
    
    func onHighlightChanged() {
        update()
    }
    
    private var _progress: Double = 0.0
    var progress: Double {
        get {
            return _progress
        }
        set {
            _progress = newValue
            onProgressChanged()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsCompositionPopularityBar", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        barRect.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        
        update()
    }

    func onProgressChanged() {
        widthConstraint.constant = frame.width * progress / 100.0
    }

    func update() {
        barRect.borderColor = borderColor
        barRect.wantsLayer = true
        let result = CAGradientLayer()
        result.cornerRadius = 2.0
        result.colors = [ gradientColorTop.cgColor, gradientColorBottom.cgColor ]
        result.startPoint = CGPoint(x: 0.5, y: 0)
        result.endPoint = CGPoint(x: 0.5, y: 1)
        barRect.layer = result
        onProgressChanged()
    }
}
