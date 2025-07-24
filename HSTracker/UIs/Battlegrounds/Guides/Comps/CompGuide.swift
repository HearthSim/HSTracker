//
//  CompGuide.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class MyTextView: NSTextView {
    
    override func clicked(onLink link: Any, at charIndex: Int) {
        if let card = link as? Card, let window, let layoutManager, let textContainer {
            let windowRect = window.frame
            
            let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 388)
            
            var x: CGFloat
            // decide if the popup window should on the left or right side of the tracker
            if windowRect.origin.x < hoverFrame.size.width {
                x = windowRect.origin.x + windowRect.size.width
            } else {
                x = windowRect.origin.x - hoverFrame.size.width
            }
            
            let cellFrameRelativeToWindow = convert(layoutManager.boundingRect(forGlyphRange: NSRange(location: charIndex, length: 1), in: textContainer), to: nil)
            let cellFrameRelativeToScreen = window.convertToScreen(cellFrameRelativeToWindow)
            
            let y: CGFloat = cellFrameRelativeToScreen.origin.y - hoverFrame.height / 2.0
            
            let frame = [x, y, hoverFrame.width, hoverFrame.height]
            
            let userinfo = [
                "card": card,
                "frame": frame,
                "useFrame": true,
                "battlegrounds": true
            ] as [String: Any]
            
            NotificationCenter.default
                .post(name: Notification.Name(rawValue: Events.show_floating_card),
                      object: nil,
                      userInfo: userinfo)
        }
    }
}

class CompGuide: NSView {
    @IBOutlet var contentView: NSView!
    @IBOutlet var backArrow: NSView!
    @IBOutlet var allCompsLabel: NSTextField!
    @IBOutlet var compImage: NSImageView!
    @IBOutlet var compName: NSTextField!
    @IBOutlet var tierBox: NSStackView!
    @IBOutlet var compTierLabel: NSTextField!
    @IBOutlet var difficultyBox: NSBox!
    @IBOutlet var difficultyText: NSTextField!
    @IBOutlet var howToPlay: NSTextView!
    @IBOutlet var howToPlayHeight: NSLayoutConstraint!
    
    var owner: CompsGuides?
    
    var hovering = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    func commonInit() {
        NibHelper.loadNib(Self.self, self)
        
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentView.frame = self.bounds
    }
    
    var textStorage: NSTextStorage!
    
    override func awakeFromNib() {
        let trackingArea = NSTrackingArea(rect: backArrow.bounds,
                                          options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)

        backArrow.addTrackingArea(trackingArea)
        
        let lm = NSLayoutManager()
        let tc = NSTextContainer()
        tc.containerSize = NSSize(width: howToPlay.bounds.size.width, height: 10000000.0)
        tc.heightTracksTextView = true
        lm.addTextContainer(tc)
        let ts = NSTextStorage()
        ts.addLayoutManager(lm)
        
        tc.lineFragmentPadding = 0.0
        tc.lineBreakMode = NSLineBreakMode.byWordWrapping

        howToPlay.isRichText = true
        howToPlay.textContainer = tc
        howToPlay.isVerticallyResizable = true
        howToPlay.drawsBackground = false
        howToPlay.isSelectable = false
        howToPlay.isEditable = false
        howToPlay.textColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
        
        textStorage = ts
        
//        collectionView.register(NSNib(nibNamed: "BattlegroundsMinionViewItem", bundle: nil), forItemWithIdentifier: bgMinionViewItem)
//        collectionView.dataSource = self
    }
    
    func update(_ viewModel: BattlegroundsCompGuideViewModel, _ owner: CompsGuides) {
        self.owner = owner
        
        compName.stringValue = viewModel.compGuide.name
        compTierLabel.stringValue = viewModel.tierText
        tierBox.wantsLayer = true
        tierBox.layer = viewModel.tierColor
        
        difficultyBox.fillColor = NSColor.fromHexString(hex: viewModel.difficultyColor) ?? .black
        difficultyText.stringValue = viewModel.difficultyText
        
        if let ts = howToPlay.textStorage, let layoutManager = howToPlay.layoutManager, let textContainer = howToPlay.textContainer {
            let attributes = [NSAttributedString.Key.foregroundColor: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)]
            let boldFont = NSFont(descriptor: howToPlay.font!.fontDescriptor.withSymbolicTraits(.bold), size: howToPlay.font!.pointSize)!
            ts.beginEditing()
            ts.deleteCharacters(in: NSRange(location: 0, length: ts.length))
            ts.endEditing()
            for run in viewModel.howToPlay {
                if let referencedCardRun = run as? ReferencedCardRun {
                    let boldAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), NSAttributedString.Key.font: boldFont, .link: referencedCardRun.card as Any ]

                    ts.append(NSAttributedString(string: referencedCardRun.string, attributes: boldAttributes))
                } else {
                    ts.append(NSAttributedString(string: run.string, attributes: attributes))
                }
            }
            
            layoutManager.ensureLayout(for: textContainer)
            howToPlayHeight.constant = layoutManager.usedRect(for: textContainer).height
        }
    }
    
    // MARK: - Mouse
    override func mouseEntered(with event: NSEvent) {
        if event.userData == nil {
            hovering = true
            allCompsLabel.textColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        } else {
            logger.debug("Mouse entered TV")
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        guard
                let lm = howToPlay.layoutManager,
                let tc = howToPlay.textContainer
            else { return }

            let localMousePosition = convert(event.locationInWindow, from: nil)
            var partial = CGFloat(1.0)
            let glyphIndex = lm.glyphIndex(for: localMousePosition, in: tc, fractionOfDistanceThroughGlyph: &partial)

            print(glyphIndex)
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.userData == nil {
            hovering = false
            allCompsLabel.textColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if hovering {
            owner?.back()
        }
    }
    
    // MARK: - Collection View
    let bgMinionViewItem = NSUserInterfaceItemIdentifier(rawValue: "bgMinionViewItem")
}
