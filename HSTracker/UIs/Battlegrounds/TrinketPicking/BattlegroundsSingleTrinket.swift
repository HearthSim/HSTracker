//
//  BattlegroundsSingleTrinket.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/26/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsSingleTrinket: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var avgPlacementLabel: NSTextField!
    
    @IBOutlet var tierLabel: NSTextField!
    
    @IBOutlet var pickRateLabel: NSTextField!
        
    let viewModel: StatsHeaderViewModel
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 277, height: 430)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    init(frame frameRect: NSRect, viewModel: StatsHeaderViewModel) {
        self.viewModel = viewModel
        super.init(frame: frameRect)
        commonInit()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let transform = AffineTransform(translationByX: 12.5, byY: 330.0)
        
        // tier
        var path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 39))
        path.close()
        path.move(to: NSPoint(x: 0, y: 100))
        path.close()
        path.move(to: NSPoint(x: 95, y: 96))
        path.curve(to: NSPoint(x: 99, y: 100), controlPoint1: NSPoint(x: 95, y: 98.2), controlPoint2: NSPoint(x: 96.8, y: 100))
        path.line(to: NSPoint(x: 144, y: 100))
        path.curve(to: NSPoint(x: 148, y: 96), controlPoint1: NSPoint(x: 146.2, y: 100), controlPoint2: NSPoint(x: 148, y: 98.2))
        path.line(to: NSPoint(x: 148, y: 51))
        path.curve(to: NSPoint(x: 144, y: 47), controlPoint1: NSPoint(x: 148, y: 48.8), controlPoint2: NSPoint(x: 146.2, y: 47))
        path.line(to: NSPoint(x: 99, y: 47))
        path.curve(to: NSPoint(x: 95, y: 51), controlPoint1: NSPoint(x: 96.8, y: 47), controlPoint2: NSPoint(x: 95, y: 48.8))
        path.line(to: NSPoint(x: 95, y: 96))
        path.close()
        path.transform(using: transform)
        
        if let gradient = viewModel.tierGradient as? CAGradientLayer {
            // swiftlint:disable force_cast
            if let grad = NSGradient(colors: gradient.colors?.compactMap({ x in NSColor(cgColor: x as! CGColor ) }) ?? [NSColor.green]) {
                grad.draw(in: path, angle: 0.0)
            } else {
                NSColor.green.set()
                path.fill()
            }
            // swiftlint:enable force_cast
        } else {
            NSColor.green.set()
            path.fill()
        }
        
        path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 39))
        path.close()
        path.move(to: NSPoint(x: 0, y: 100))
        path.close()
        path.move(to: NSPoint(x: 99, y: 99.5))
        path.line(to: NSPoint(x: 144, y: 99.5))
        path.curve(to: NSPoint(x: 147.5, y: 96), controlPoint1: NSPoint(x: 145.9, y: 99.5), controlPoint2: NSPoint(x: 147.5, y: 97.9))
        path.line(to: NSPoint(x: 147.5, y: 51))
        path.curve(to: NSPoint(x: 144, y: 47.5), controlPoint1: NSPoint(x: 147.5, y: 49.1), controlPoint2: NSPoint(x: 145.9, y: 47.5))
        path.line(to: NSPoint(x: 99, y: 47.5))
        path.curve(to: NSPoint(x: 95.5, y: 51), controlPoint1: NSPoint(x: 97.1, y: 47.5), controlPoint2: NSPoint(x: 95.5, y: 49.1))
        path.line(to: NSPoint(x: 95.5, y: 96))
        path.curve(to: NSPoint(x: 99, y: 99.5), controlPoint1: NSPoint(x: 95.5, y: 97.9), controlPoint2: NSPoint(x: 97.1, y: 99.5))
        path.close()
        path.transform(using: transform)
        
        NSColor.clear.setFill()
        NSColor.fromHexString(hex: "#361637")?.set()
        path.stroke()

        // left
        path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 0))
        path.close()
        path.move(to: NSPoint(x: 0, y: 61))
        path.close()
        path.move(to: NSPoint(x: 58.1, y: 0.5))
        path.line(to: NSPoint(x: 4, y: 0.5))
        path.curve(to: NSPoint(x: 0.5, y: 4), controlPoint1: NSPoint(x: 2.1, y: 0.5), controlPoint2: NSPoint(x: 0.5, y: 2.1))
        path.line(to: NSPoint(x: 0.5, y: 57))
        path.curve(to: NSPoint(x: 4, y: 60.5), controlPoint1: NSPoint(x: 0.5, y: 58.9), controlPoint2: NSPoint(x: 2.1, y: 60.5))
        path.line(to: NSPoint(x: 85, y: 60.5))
        path.curve(to: NSPoint(x: 88.5, y: 57), controlPoint1: NSPoint(x: 86.9, y: 60.5), controlPoint2: NSPoint(x: 88.5, y: 58.9))
        path.line(to: NSPoint(x: 88.5, y: 23.4))
        path.curve(to: NSPoint(x: 85, y: 17), controlPoint1: NSPoint(x: 88.5, y: 20.8), controlPoint2: NSPoint(x: 87.2, y: 18.4))
        path.curve(to: NSPoint(x: 62.5, y: 1.9), controlPoint1: NSPoint(x: 73.5, y: 9.6), controlPoint2: NSPoint(x: 65.9, y: 4.3))
        path.curve(to: NSPoint(x: 58.1, y: 0.5), controlPoint1: NSPoint(x: 61.2, y: 1), controlPoint2: NSPoint(x: 59.6, y: 0.5))
        path.close()
        path.transform(using: transform)

        NSColor.fromHexString(hex: "FF141617")?.set()
        path.fill()
        
        path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 0))
        path.close()
        path.move(to: NSPoint(x: 0, y: 61))
        path.close()
        path.move(to: NSPoint(x: 0, y: 57))
        path.curve(to: NSPoint(x: 4, y: 61), controlPoint1: NSPoint(x: 0, y: 59.2), controlPoint2: NSPoint(x: 1.8, y: 61))
        path.line(to: NSPoint(x: 85, y: 61))
        path.curve(to: NSPoint(x: 89, y: 57), controlPoint1: NSPoint(x: 87.2, y: 61), controlPoint2: NSPoint(x: 89, y: 59.2))
        path.line(to: NSPoint(x: 89, y: 39))
        path.line(to: NSPoint(x: 0, y: 39))
        path.line(to: NSPoint(x: 0, y: 57))
        path.close()
        path.transform(using: transform)

        NSColor.fromHexString(hex: "#361637")?.set()
        path.fill()
        
        path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 0))
        path.close()
        path.move(to: NSPoint(x: 0, y: 61))
        path.close()
        path.move(to: NSPoint(x: 58.1, y: 0.5))
        path.line(to: NSPoint(x: 4, y: 0.5))
        path.curve(to: NSPoint(x: 0.5, y: 4), controlPoint1: NSPoint(x: 2.1, y: 0.5), controlPoint2: NSPoint(x: 0.5, y: 2.1))
        path.line(to: NSPoint(x: 0.5, y: 57))
        path.curve(to: NSPoint(x: 4, y: 60.5), controlPoint1: NSPoint(x: 0.5, y: 58.9), controlPoint2: NSPoint(x: 2.1, y: 60.5))
        path.line(to: NSPoint(x: 85, y: 60.5))
        path.curve(to: NSPoint(x: 88.5, y: 57), controlPoint1: NSPoint(x: 86.9, y: 60.5), controlPoint2: NSPoint(x: 88.5, y: 58.9))
        path.line(to: NSPoint(x: 88.5, y: 23.4))
        path.curve(to: NSPoint(x: 85, y: 17), controlPoint1: NSPoint(x: 88.5, y: 20.8), controlPoint2: NSPoint(x: 87.2, y: 18.4))
        path.curve(to: NSPoint(x: 62.5, y: 1.9), controlPoint1: NSPoint(x: 73.5, y: 9.6), controlPoint2: NSPoint(x: 65.9, y: 4.3))
        path.curve(to: NSPoint(x: 58.1, y: 0.5), controlPoint1: NSPoint(x: 61.2, y: 1), controlPoint2: NSPoint(x: 59.6, y: 0.5))
        path.close()
        path.transform(using: transform)

        NSColor.clear.setFill()
        NSColor.fromHexString(hex: "#361637")?.set()
        path.stroke()
        
        // right
        path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 0))
        path.close()
        path.move(to: NSPoint(x: 0, y: 61))
        path.close()
        path.move(to: NSPoint(x: 187.1, y: 0.5))
        path.line(to: NSPoint(x: 239, y: 0.5))
        path.curve(to: NSPoint(x: 242.5, y: 4), controlPoint1: NSPoint(x: 240.9, y: 0.5), controlPoint2: NSPoint(x: 242.5, y: 2.1))
        path.line(to: NSPoint(x: 242.5, y: 57))
        path.curve(to: NSPoint(x: 239, y: 60.5), controlPoint1: NSPoint(x: 242.5, y: 58.9), controlPoint2: NSPoint(x: 240.9, y: 60.5))
        path.line(to: NSPoint(x: 158, y: 60.5))
        path.curve(to: NSPoint(x: 154.5, y: 57), controlPoint1: NSPoint(x: 156.1, y: 60.5), controlPoint2: NSPoint(x: 154.5, y: 58.9))
        path.line(to: NSPoint(x: 154.5, y: 25.4))
        path.curve(to: NSPoint(x: 157.9, y: 19), controlPoint1: NSPoint(x: 154.5, y: 22.8), controlPoint2: NSPoint(x: 155.8, y: 20.4))
        path.curve(to: NSPoint(x: 182.5, y: 2), controlPoint1: NSPoint(x: 170, y: 11.2), controlPoint2: NSPoint(x: 178.6, y: 4.9))
        path.curve(to: NSPoint(x: 187.1, y: 0.5), controlPoint1: NSPoint(x: 183.8, y: 1), controlPoint2: NSPoint(x: 185.4, y: 0.5))
        path.close()
        path.transform(using: transform)

        NSColor.fromHexString(hex: "FF141617")?.set()
        path.fill()
        
        path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 0))
        path.close()
        path.move(to: NSPoint(x: 0, y: 61))
        path.close()
        path.move(to: NSPoint(x: 154, y: 57))
        path.curve(to: NSPoint(x: 158, y: 61), controlPoint1: NSPoint(x: 154, y: 59.2), controlPoint2: NSPoint(x: 155.8, y: 61))
        path.line(to: NSPoint(x: 239, y: 61))
        path.curve(to: NSPoint(x: 243, y: 57), controlPoint1: NSPoint(x: 241.2, y: 61), controlPoint2: NSPoint(x: 243, y: 59.2))
        path.line(to: NSPoint(x: 243, y: 39))
        path.line(to: NSPoint(x: 154, y: 39))
        path.line(to: NSPoint(x: 154, y: 57))
        path.close()
        path.transform(using: transform)

        NSColor.fromHexString(hex: "#361637")?.set()
        path.fill()

        path = NSBezierPath()
        path.move(to: NSPoint(x: 243, y: 0))
        path.close()
        path.move(to: NSPoint(x: 0, y: 61))
        path.close()
        path.move(to: NSPoint(x: 187.1, y: 0.5))
        path.line(to: NSPoint(x: 239, y: 0.5))
        path.curve(to: NSPoint(x: 242.5, y: 4), controlPoint1: NSPoint(x: 240.9, y: 0.5), controlPoint2: NSPoint(x: 242.5, y: 2.1))
        path.line(to: NSPoint(x: 242.5, y: 57))
        path.curve(to: NSPoint(x: 239, y: 60.5), controlPoint1: NSPoint(x: 242.5, y: 58.9), controlPoint2: NSPoint(x: 240.9, y: 60.5))
        path.line(to: NSPoint(x: 158, y: 60.5))
        path.curve(to: NSPoint(x: 154.5, y: 57), controlPoint1: NSPoint(x: 156.1, y: 60.5), controlPoint2: NSPoint(x: 154.5, y: 58.9))
        path.line(to: NSPoint(x: 154.5, y: 25.4))
        path.curve(to: NSPoint(x: 157.9, y: 19), controlPoint1: NSPoint(x: 154.5, y: 22.8), controlPoint2: NSPoint(x: 155.8, y: 20.4))
        path.curve(to: NSPoint(x: 182.5, y: 2), controlPoint1: NSPoint(x: 170, y: 11.2), controlPoint2: NSPoint(x: 178.6, y: 4.9))
        path.curve(to: NSPoint(x: 187.1, y: 0.5), controlPoint1: NSPoint(x: 183.8, y: 1), controlPoint2: NSPoint(x: 185.4, y: 0.5))
        path.close()
        path.transform(using: transform)

        NSColor.clear.setFill()
        NSColor.fromHexString(hex: "#361637")?.set()
        path.stroke()
    }
    
    private func commonInit() {
        NibHelper.loadNib(Self.self, self)
        
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        avgPlacementLabel.chunkFive()
        pickRateLabel.chunkFive()
        tierLabel.chunkFive()
        
        addSubview(contentView)
        contentView.frame = self.bounds
                
        update()
    }
    
    func update() {
        avgPlacementLabel.textColor = NSColor.fromHexString(hex: viewModel.avgPlacementColor) ?? NSColor.white
        if let avg = viewModel.avgPlacement {
            avgPlacementLabel.doubleValue = avg
        } else {
            avgPlacementLabel.stringValue = "—" // em dash
        }
        
        tierLabel.stringValue = viewModel.tierChar
        
        if let pickRate = viewModel.pickRate {
            pickRateLabel.doubleValue = pickRate / 100.0
        } else {
            pickRateLabel.stringValue = "—" // em dash
        }
    }
}
