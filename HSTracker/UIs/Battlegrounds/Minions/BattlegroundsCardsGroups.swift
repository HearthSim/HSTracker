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
    
    @objc dynamic var title = ""
    private var _cards = [Card]()
    var cards: [Card] {
        get {
            return _cards
        }
        set {
            _cards = newValue
            cardsList.update(cards: newValue, reset: false)
        }
    }

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
        contentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true    }
}
