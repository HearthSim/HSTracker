//
//  BattlegroundsCardsGroups.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCardsGroups: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var cardsList: AnimatedCardList!
    @IBOutlet weak var box: NSBox!
    
    var _cardHeight: CGFloat = 34.0
    var cardHeight: CGFloat {
        get {
            return _cardHeight
        }
        set {
            _cardHeight = newValue
            cardsList.cardHeight = newValue
            cardsList.invalidateIntrinsicContentSize()
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: NSSize {
        let csize = cardsList.intrinsicContentSize
        return NSSize(width: csize.width, height: 30.0 + csize.height)
    }

    var clickMinionTypeCommand: ((Race) -> Void)?
    
    @objc dynamic var groupedByMinionType = false

    @objc dynamic var tier: Int = 0
    
    @objc dynamic var minionType: Int = 0
    
    @objc dynamic var title: String {
        let minionTypeName = minionType == -1 ? String.localizedString("spells", comment: "") : minionType == 0 ? String.localizedString("neutral", comment: "") : String.localizedString(Race(rawValue: minionType)?.rawValue ?? "", comment: "")
        
        if !groupedByMinionType {
            return minionTypeName
        }
        
        if minionTypeName.isEmpty {
            return String(format: String.localizedString("BattlegroundsMinions_TavernTier", comment: ""), tier)
        }
        return String(format: String.localizedString("BattlegroundsMinions_TavernTierMinionType", comment: ""), tier, minionTypeName)
    }
    
    @objc class func keyPathsForValuesAffectingTitle() -> Set<String> {
        return [ #keyPath(groupedByMinionType), #keyPath(tier), #keyPath(minionType) ]
    }
    
    @objc dynamic var titleVisibility: Bool {
        return !title.isEmpty
    }

    @objc class func keyPathsForValuesAffectingTitleVisibility() -> Set<String> {
        return [ #keyPath(groupedByMinionType), #keyPath(tier), #keyPath(minionType) ]
    }

    @objc dynamic var hovering = false
    
    @objc dynamic var btnFilterVisibility: Bool {
        return hovering && !groupedByMinionType
    }
    
    @objc class func keyPathsForValuesAffectingBtnFilterVisibility() -> Set<String> {
        return [ #keyPath(hovering) ]
    }
    
    @objc dynamic var headerBackground: String {
        return hovering && !groupedByMinionType ? "#24436c" : "#1d3657"
    }
    
    @objc class func keyPathsForValuesAffectingHeaderBackground() -> Set<String> {
        return [ #keyPath(hovering) ]
    }
    
    private var _cards = [Card]()
    @MainActor
    var cards: [Card] {
        get {
            return _cards
        }
        set {
            _cards = newValue
            cardsList.update(cards: newValue, reset: false)
        }
    }
    
    private var kvoToken: NSKeyValueObservation?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    private func commonInit() {
        guard Bundle.main.loadNibNamed("BattlegroundsCardsGroups", owner: self, topLevelObjects: nil) else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        cardsList.isBattlegrounds = true
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        kvoToken = observe(\.headerBackground, changeHandler: { _, _ in self.updateHeaderBackground() })
    }
    
    deinit {
        kvoToken?.invalidate()
    }
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                                                   owner: self,
                                                                   userInfo: nil)
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        hovering = true
        super.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        hovering = false
        super.mouseExited(with: event)
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        if !groupedByMinionType {
            clickMinionTypeCommand?(Race(rawValue: minionType) ?? .invalid)
        }
    }
    
    @MainActor
    private func updateHeaderBackground() {
        box.fillColor = NSColor.fromHexString(hex: headerBackground) ?? .black
    }
}
