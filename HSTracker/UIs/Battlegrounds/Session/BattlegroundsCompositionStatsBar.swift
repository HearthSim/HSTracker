//
//  BattlegroundsCompositionStatsBar.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompositionStatsBar: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var widthConstraint: NSLayoutConstraint!
    @IBOutlet var progressBar: NSBox!
    @IBOutlet var percentageText: NSTextField!
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 70, height: 22)
    }
    
    var gradientColorTop: NSColor {
        return NSColor.fromHexString(hex: "#CCC58DC9")!
    }
    
    var gradientColorBottom: NSColor {
        return NSColor.fromHexString(hex: "#FFC58DC9")!
    }
    
    private var _maxPercent: Double = 100.0
    var maxPercent: Double {
        get {
            return _maxPercent
        }
        set {
            _maxPercent = newValue
            onMaxPercentChanged()
        }
    }
    private var _percent: Double = 0.0
    var percent: Double {
        get {
            return _percent
        }
        set {
            _percent = newValue
            onPercentChanged()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        NibHelper.loadNib(Self.self, self)
        
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        
        update()
    }

    @MainActor
    func onPercentChanged() {
        // Ensure MaxPercent is not zero to avoid division by zero
        let safeMaxPercent = maxPercent == 0 ? 100.0 : maxPercent
        
        widthConstraint.constant = (frame.width * percent) / safeMaxPercent
        percentageText.doubleValue = percent / 100.0
    }
    
    @MainActor
    func onMaxPercentChanged() {
        // Reuse the existing OnPercentChanged logic to recalculate the progress bar
        // This ensures that changes to MaxPercent immediately affect the layout
        onPercentChanged()
    }

    func update() {
        progressBar.wantsLayer = true
        progressBar.borderColor =  NSColor.fromHexString(hex: "#28FFFFFF")!
//        progressBar.fillColor = gradientColorTop
        let result = CAGradientLayer()
        result.cornerRadius = 2.0
        result.colors = [ gradientColorTop.cgColor, gradientColorBottom.cgColor ]
        result.startPoint = CGPoint(x: 0.5, y: 0)
        result.endPoint = CGPoint(x: 0.5, y: 1)
        progressBar.layer = result
        onPercentChanged()
    }
}
