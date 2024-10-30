//
//  CounterView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/24/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CounterView: NSView {
    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var text: NSTextField!
    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var circleView: NSView!
    
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

    override func mouseEntered(with event: NSEvent) {
        if let cardId = counter.cardIdToShowInUI, let card = Cards.by(cardId: cardId) {
            let windowRect = self.window!.frame

            let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 388)

            var x: CGFloat
            if windowRect.origin.x < hoverFrame.size.width {
                x = windowRect.origin.x + windowRect.size.width
            } else {
                x = windowRect.origin.x - hoverFrame.size.width
            }

            let cellFrameRelativeToWindow = self.convert(self.bounds, to: nil)
            let cellFrameRelativeToScreen = self.window?.convertToScreen(cellFrameRelativeToWindow)

            let y: CGFloat = cellFrameRelativeToScreen!.origin.y
            
            let frame: [CGFloat] = [x, y - hoverFrame.height / 2.0, hoverFrame.width, hoverFrame.height]
            NotificationCenter.default
                .post(name: Notification.Name(rawValue: Events.show_floating_card),
                                      object: nil,
                                      userInfo: [
                                        "card": card,
                                        "frame": frame,
                                        "useFrame": true
                    ])
        }
    }

    override func mouseExited(with event: NSEvent) {
        guard let cardId = counter.cardIdToShowInUI, let card = Cards.by(cardId: cardId) else {
            return
        }
        
        let userinfo = [
            "card": card
        ] as [String: Any]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hide_floating_card),
                                        object: nil,
                                        userInfo: userinfo)
    }

}
