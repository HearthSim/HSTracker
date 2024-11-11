//
//  CounterView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/24/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CounterView: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var text: NSTextField!
    @IBOutlet var image: NSImageView!
    @IBOutlet var circleView: NSView!
    
    let counter: BaseCounter
    
    override var intrinsicContentSize: NSSize {
        if counter.isDisplayValueLong {
            setFontSize()
        }
        return NSSize(width: 2*5.0 // margin
                      + 2.0 // border width
                      + 37.0 // image
                      + 10.0 // left text margin
                      + text.intrinsicContentSize.width // text size
                      + 10.0, // right text margin
                      height: 51.0)
    }
    
    private func setFontSize() {
        var fontSize = 16.0
        while fontSize > 5.0 {
            let font = NSFont(name: "ChunkFive", size: fontSize)
            text.font = font
            let ics = text.intrinsicContentSize
            if ics.height <= 37.0 {
                break
            }
            fontSize -= 1.0
        }
    }
    
    private var _image: NSImage?
    @objc dynamic var cardImage: NSImage? {
        if let image = _image {
            return image
        }
        if let cardId = counter.cardIdToShowInUI {
            ImageUtils.art(for: cardId, completion: { image in
                DispatchQueue.main.async {
                    self.willChangeValue(forKey: "cardImage")
                    self._image = image
                    self.didChangeValue(forKey: "cardImage")
                }
            })
        }
        return nil
    }
    
    @objc dynamic var counterValue: String {
        return counter.counterValue
    }
    
    @objc dynamic var isDisplayValueLong: Bool {
        return counter.isDisplayValueLong
    }
    
    init(_ counter: BaseCounter) {
        self.counter = counter
        super.init(frame: NSRect(x: 0, y: 0, width: 84.0, height: 49.0))
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        counter.propertyChanged = nil
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("CounterView", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        if counter.isDisplayValueLong {
            text.preferredMaxLayoutWidth = 100.0
            text.usesSingleLineMode = false
        }
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.rightAnchor.constraint(equalTo: rightAnchor)
        ])

        counter.propertyChanged = { _ in
            DispatchQueue.main.async {
                self.willChangeValue(forKey: "counterValue")
                self.didChangeValue(forKey: "counterValue")
                self.invalidateIntrinsicContentSize()
            }
        }
        
        updateTrackingAreas()
    }
    
    private lazy var trackingArea: NSTrackingArea = {
        return NSTrackingArea(rect: self.bounds,
                              options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let image = circleView {
            image.wantsLayer = true
            let clipPath = NSBezierPath(ovalIn: NSRect(x: 0.0, y: 0.0, width: 37.0, height: 37.0))
            let clipLayer = CAShapeLayer()
            clipLayer.frame = image.bounds
            clipLayer.path = clipPath.cgPath
            image.layer?.mask = clipLayer
        }
    }

    // MARK: - mouse hover
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }
    
    var delayedTooltip: DelayedTooltip?

    override func mouseEntered(with event: NSEvent) {
        if window != nil {
            delayedTooltip = DelayedTooltip(handler: tooltipDisplay, 0.400, nil)
        }
    }

    override func mouseExited(with event: NSEvent) {
        delayedTooltip?.cancel()
        delayedTooltip = nil
        counter.game.windowManager.show(controller: counter.game.windowManager.tooltipGridCards, show: false)
    }
    
    private func tooltipDisplay(_ userInfo: Any?) {
        guard let window else {
            return
        }
        let cardsToDisplay = counter.getCardsToDisplay().compactMap({ cardId in Cards.by(cardId: cardId) })
        if cardsToDisplay.count == 0 {
            return
        }
        let windowRect = window.frame

        let cardImages = counter.game.windowManager.tooltipGridCards
        cardImages.setTitle(counter.localizedName)
        cardImages.setCardIdsFromCards(cardsToDisplay)

        let hoverFrame = NSRect(x: 0, y: 0, width: cardImages.gridWidth, height: cardImages.gridHeight)

        var x: CGFloat
        if windowRect.origin.x < hoverFrame.size.width {
            x = windowRect.origin.x + windowRect.size.width
        } else {
            x = windowRect.origin.x - hoverFrame.size.width
        }

        let cellFrameRelativeToWindow = self.convert(self.bounds, to: nil)
        let cellFrameRelativeToScreen = window.convertToScreen(cellFrameRelativeToWindow)

        let y: CGFloat = cellFrameRelativeToScreen.origin.y

        counter.game.windowManager.show(controller: cardImages, show: true, frame: NSRect(x: x, y: y, width: hoverFrame.width, height: hoverFrame.height))
        delayedTooltip = nil
    }
}
