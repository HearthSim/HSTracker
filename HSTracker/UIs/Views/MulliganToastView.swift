//
//  MulliganToastView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/16/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class MulliganToastView: NSView {
    var shortId: String
    var dbfIds: [Int]
    var opponent: CardClass
    var hasData: Bool = false
    var hasCoin: Bool = false
    var playerStarLevel: Int = 0
    
    var clicked: (() -> Void)?
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                              options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)

    init(frame frameRect: NSRect, sid: String, ids: [Int], opponent: CardClass, coin: Bool, starLevel: Int) {
        shortId = sid
        dbfIds = ids
        self.opponent = opponent
        hasCoin = coin
        playerStarLevel = starLevel
        
        hasData = true

        super.init(frame: frameRect)
        
        let imageView = FillImageView(frame: frameRect)
        if let image = NSImage(named: "mulligan-toast-bg") {
            imageView.image = image
        }
        addSubview(imageView)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let frameView = FrameView()
        let icon = NSImageView()
        let text = NSTextField()
        let stack = NSStackView()
        let text2 = NSTextField()

        if let rp = Bundle.main.resourcePath, let image = NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/icon_white.png") {
            icon.image = image
        }

        let attributes = TextAttributes()
        attributes
            .font(NSFont(name: "Arial", size: 20))
            .foregroundColor(.white)
            .strokeColor(.white)
            .alignment(.center)

        let message = String.localizedString("What should I keep?", comment: "")
        text.attributedStringValue = NSAttributedString(string: message, attributes: attributes)
        text.isBezeled = false
        text.drawsBackground = false
        text.isEditable = false
        text.isSelectable = false
        text.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1000), for: .vertical)
        text.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1000), for: .horizontal)

        let attributes2 = TextAttributes()
        attributes2
            .font(NSFont(name: "Arial", size: 10))
            .foregroundColor(.white)
            .strokeColor(.white)
            .alignment(.center)

        let message2 = String.localizedString("HSReplay.net - Mulligan Guide", comment: "")
        text2.attributedStringValue = NSAttributedString(string: message2, attributes: attributes2)
        text2.isBezeled = false
        text2.drawsBackground = false
        text2.isEditable = false
        text2.isSelectable = false
        text2.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1000), for: .vertical)
        text2.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 1000), for: .horizontal)

        stack.orientation = .vertical
        stack.spacing = 5
        stack.distribution = .fill
        
        stack.addArrangedSubview(text)
        stack.addArrangedSubview(text2)

        addSubview(frameView)
        addSubview(icon)
        addSubview(stack)
        
        frameView.translatesAutoresizingMaskIntoConstraints = false
        icon.translatesAutoresizingMaskIntoConstraints = false
        text.translatesAutoresizingMaskIntoConstraints = false
        text2.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // background
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 280),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            // frame
            frameView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            frameView.topAnchor.constraint(equalTo: self.topAnchor),
            frameView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            frameView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            // the horizontal chain
            icon.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            icon.trailingAnchor.constraint(equalTo: stack.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            text.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            text2.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            text.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            text2.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            // vertical positionning
            icon.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 50),
            icon.widthAnchor.constraint(equalToConstant: 50),
            stack.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }
    
    override func mouseUp(with: NSEvent) {
        guard hasData else {
            return
        }
        let ids = "mulliganIds=\(dbfIds.compactMap({ x in String(x)}).joined(separator: "%2C"))"
        let opponent = "mulliganOpponent=\(self.opponent.rawValue.uppercased())"
        let playerInitiative = "mulliganPlayerInitiative=\(hasCoin ? "COIN" : "FIRST")"
        let playerStarLevel = "mulliganPlayerStarLevel=\(playerStarLevel)"
        let url = "https://hsreplay.net/decks/\(shortId)?utm_source=hstracker&utm_medium=client&utm_campaign=mulligan_toast#\(ids)&\(opponent)&\(playerInitiative)&\(playerStarLevel)"
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
