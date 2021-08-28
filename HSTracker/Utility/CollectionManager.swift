//
//  CollectionManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 8/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class CollectionManager {
    static let `default` = CollectionManager()

    func collection() -> [String: [Bool: Int]] {
        // get collection first
		guard let collection = MirrorHelper.getCollection() else {
			logger.error("Can't get card collection")
			return [:]
		}
        var cards: [String: [Bool: Int]] = [:]
        for card in collection.cards {
            if cards[card.cardId] == nil {
                cards[card.cardId] = [:]
            }
            if cards[card.cardId]?[card.premium] == nil {
                cards[card.cardId]?[card.premium] = card.count as? Int ?? 0
            } else {
                if let count = cards[card.cardId]?[card.premium] {
                    let newCount = count + (card.count as? Int ?? 0)
                    cards[card.cardId]?[card.premium] = newCount
                }
            }
        }

        return cards
    }

    func checkMissingCards(missingCards: [Card]) -> String? {
        guard !missingCards.isEmpty else { return nil }

        var message = NSLocalizedString("The followings cards were missing : ", comment: "")
        var cards: [String: Int] = [:]
        for card in missingCards {
            if cards[card.name] == nil {
                cards[card.name] = 1
            } else {
                cards[card.name] = cards[card.name]! + 1
            }
        }
        message += cards.map({ "\($0.0) x \($0.1)" }).joined(separator: ", ")

        return message
    }

}
