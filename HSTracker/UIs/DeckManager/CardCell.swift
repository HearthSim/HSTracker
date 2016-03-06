//
//  CardCell.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import JNWCollectionView

class CardCell : JNWCollectionViewCell {

    private var _card: Card?

    func setCard(card: Card) {
        _card = card
        self.backgroundImage = ImageCache.cardImage(card)
    }
    var card: Card? {
        return _card
    }

    func setCount(count: Int) {
        var alpha: Float = 1.0
        if count == 2 || (count == 1 && _card!.rarity == .Legendary) {
            alpha = 0.5
        }
        self.layer!.opacity = alpha
        self.layer!.setNeedsDisplay()
    }
}