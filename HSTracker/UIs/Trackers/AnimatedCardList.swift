//
//  AnimatedCardList.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/15/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class AnimatedCardList: NSView {
    fileprivate var animatedCards: [CardBar] = []
    
    var playerType: PlayerType = .player
    
    var delegate: CardCellHover?
    
    let lock = UnfairLock()
    
    var count: Int {
        lock.around {
            return animatedCards.count
        }
    }

    @discardableResult func update(cards: [Card], reset: Bool) -> Bool {
        lock.around {
            if reset {
                animatedCards.removeAll()
            }

            var newCards = [Card]()
            for card in cards {
                if let existing = animatedCards.first(where: {
                    if let c0 = $0.card {
                        return self.areEqualForList(c0, card)
                    }
                    return false
                }) {
                    if existing.card?.count != card.count || existing.card?.highlightInHand != card.highlightInHand {
                        let highlight = existing.card?.count != card.count
                        existing.card?.count = card.count
                        existing.card?.highlightInHand = card.highlightInHand
                        existing.update(highlight: highlight)
                    } else if existing.card?.isCreated != card.isCreated {
                        existing.update(highlight: false)
                    }
                } else {
                    newCards.append(card)
                }
            }

            var toUpdate = [CardBar]()
            for c in animatedCards {
                if let card = c.card, !cards.any({ self.areEqualForList($0, card) }) {
                    toUpdate.append(c)
                }
            }
            var toRemove: [CardBar: Bool] = [:]
            for card in toUpdate {
                let newCard = newCards.first { $0.id == card.card?.id }
                toRemove[card] = newCard == nil
                if let newCard = newCard {
                    let newAnimated = CardBar.factory()
                    newAnimated.playerType = self.playerType
                    if let delegate = delegate {
                        newAnimated.setDelegate(delegate)
                    }
                    newAnimated.card = newCard

                    if let index = animatedCards.firstIndex(of: card) {
                        animatedCards.insert(newAnimated, at: index)
                        newAnimated.update(highlight: true)
                        newCards.remove(newCard)
                    }
                }
            }
            for (cardCellView, fadeOut) in toRemove {
                remove(card: cardCellView, fadeOut: fadeOut)
            }
            
            for card in newCards {
                let newCard = CardBar.factory()
                newCard.playerType = self.playerType
                if let delegate = delegate {
                    newCard.setDelegate(delegate)
                }
                newCard.card = card
                if let index = cards.firstIndex(of: card), index <= animatedCards.count {
                    animatedCards.insert(newCard, at: index)
                } else {
                    animatedCards.append(newCard)
                }
                newCard.fadeIn(highlight: !reset)
            }
            return toRemove.count > 0
        }
    }
    
    private func remove(card: CardBar, fadeOut: Bool) {
        if fadeOut {
            card.fadeOut(highlight: card.card!.count > 0)
            let when = DispatchTime.now()
                + Double(Int64(600 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
            let queue = DispatchQueue.main
            queue.asyncAfter(deadline: when) {
                self.lock.around {
                    self.animatedCards.remove(card)
                }
            }
        } else {
            animatedCards.remove(card)
        }
    }

    fileprivate func areEqualForList(_ c1: Card, _ c2: Card) -> Bool {
        return c1.id == c2.id && c1.jousted == c2.jousted && c1.isCreated == c2.isCreated
        && (!Settings.highlightDiscarded || c1.wasDiscarded == c2.wasDiscarded) && c1.deckListIndex == c2.deckListIndex
    }
    
    func updateFrames() {
        lock.around {
            var y = frame.height
            let cardHeight = frame.height / CGFloat(animatedCards.count)
            for view in subviews {
                view.removeFromSuperview()
            }

            for cell in animatedCards {
                y -= cardHeight
                cell.frame = NSRect(x: 0, y: y, width: frame.width, height: cardHeight)
                addSubview(cell)
            }
        }
    }
}
