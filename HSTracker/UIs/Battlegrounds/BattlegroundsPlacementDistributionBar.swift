//
//  BattlegroundsPlacementDistributionBar.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsPlacementDistributionBar: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var stackView: NSStackView!
    @IBOutlet var barRect: NSBox!
    
    @IBOutlet var barRectHeight: NSLayoutConstraint!
    
    private var _placement: Int = 1
    @IBInspectable var placement: Int {
        get {
            _placement
        }
        set {
            _placement = newValue
        }
    }
    
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
    @IBInspectable var highlight: Bool {
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
    
    private var _value: Double = 0.0
    var value: Double {
        get {
            return _value
        }
        set {
            _value = newValue
            onValueChanged()
        }
    }
    
    private var _maxValue: Double = 30.0
    var maxValue: Double {
        get {
            return _maxValue
        }
        set {
            _maxValue = newValue
            onValueChanged()
        }
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsPlacementDistributionBar", owner: self, topLevelObjects: nil)
        autoresizingMask = [ .width, .height ]
        contentView.autoresizingMask = [ .width, .height ]
        addSubview(contentView)
        contentView.frame = self.bounds
        
        update()
    }
    
    func onValueChanged() {
        let progress = value / maxValue
        barRectHeight.constant = frame.height * progress
        
        update()
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
    }
}
