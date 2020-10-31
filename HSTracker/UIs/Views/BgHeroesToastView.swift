//
//  BgHeroesView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 04/05/2020.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class BgHeroesToastView: NSView {

    var heroes = [String]()
    var clicked: (() -> Void)?
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                              options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)

    override init(frame frameRect: NSRect) {

        super.init(frame: frameRect)
        
        let imageView = FillImageView(frame: frameRect)
        if let image = NSImage(contentsOfFile: Bundle.main.resourcePath! + "/Resources/Battlegrounds/bgs_toast_background.jpg") {
            imageView.image = image
        }
        addSubview(imageView)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let frameView = FrameView()
        let leftSpacer = NSView()
        let icon = NSImageView()
        let text = NSTextField()
        let rightSpacer = NSView()
        
        if let image = NSImage(contentsOfFile: Bundle.main.resourcePath! + "/Resources/Battlegrounds/icon_white.png") {
            icon.image = image
        }

        let attributes = TextAttributes()
        attributes
            .font(NSFont(name: "Belwe Bd BT", size: 18))
            .foregroundColor(.white)
            .strokeWidth(-1.5)
            .strokeColor(.black)
            .alignment(.center)

        let message = NSLocalizedString("Compare heroes", comment: "")
        text.attributedStringValue = NSAttributedString(string: message, attributes: attributes)
        text.isBezeled = false
        text.drawsBackground = false
        text.isEditable = false
        text.isSelectable = false
        text.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1000), for: .vertical)
        text.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1000), for: .horizontal)
        
        addSubview(frameView)
        addSubview(leftSpacer)
        addSubview(icon)
        addSubview(text)
        addSubview(rightSpacer)
        
        frameView.translatesAutoresizingMaskIntoConstraints = false
        leftSpacer.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        text.translatesAutoresizingMaskIntoConstraints = false
        rightSpacer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // background
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            // frame
            frameView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            frameView.topAnchor.constraint(equalTo: self.topAnchor),
            frameView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            frameView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            // the horizontal chain
            leftSpacer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            leftSpacer.trailingAnchor.constraint(equalTo: icon.leadingAnchor),
            icon.trailingAnchor.constraint(equalTo: text.leadingAnchor),
            text.trailingAnchor.constraint(equalTo: rightSpacer.leadingAnchor),
            rightSpacer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            // vertical positionning
            leftSpacer.topAnchor.constraint(equalTo: self.topAnchor),
            leftSpacer.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            icon.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 30),
            icon.widthAnchor.constraint(equalToConstant: 30),
            text.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            rightSpacer.topAnchor.constraint(equalTo: self.topAnchor),
            rightSpacer.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            leftSpacer.widthAnchor.constraint(equalTo: rightSpacer.widthAnchor)
        ])
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }
    
    override func mouseUp(with: NSEvent) {
        var url = "https://hsreplay.net/battlegrounds/heroes?utm_source=hstracker&utm_medium=client&utm_campaign=bgs_toast#heroes=" + heroes.joined(separator: ",")
        if let availableRaces = AppDelegate.instance().coreManager.game.availableRaces {
            if availableRaces.count > 0 {
                let races = availableRaces.compactMap({ x in Int(Race.allCases.firstIndex(of: x)! )}).sorted()
                let tmpRaces = races.compactMap({ x in String(x) }).joined(separator: ",")
                url += "&minionTypes=" + tmpRaces
            }
        }
        NSWorkspace.shared.open(URL(string: url)!)
        if let clicked = self.clicked {
            clicked()
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
