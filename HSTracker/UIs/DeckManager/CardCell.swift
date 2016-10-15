//
//  CardCell.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardCell: JNWCollectionViewCell {

    private var _card: Card?
    var showCard = true
    var isArena = false
    var cellView: CardBar?

    func setCard(card: Card) {
        _card = card
        if showCard {
            if let cellView = cellView {
                cellView.removeFromSuperview()
                self.cellView = nil
            }
            self.backgroundImage = ImageUtils.cardImage(card)
        } else {
            if let cellView = cellView {
                cellView.card = card
            } else {
                cellView = CardBar.factory()
                cellView?.frame = NSRect(x: 0, y: 0,
                                         width: CGFloat(kFrameWidth),
                                         height: CGFloat(kRowHeight))
                cellView?.card = card
                cellView?.playerType = .cardList
                self.addSubview(cellView!)
            }
        }
    }
    var card: Card? {
        return _card
    }

    func setCount(count: Int) {
        var alpha: Float = 1.0
        if !isArena {
            if count == 2 || (count == 1 && _card!.rarity == .legendary) {
                alpha = 0.5
            }
        }
        self.layer!.opacity = alpha
        self.layer!.setNeedsDisplay()
    }
}
