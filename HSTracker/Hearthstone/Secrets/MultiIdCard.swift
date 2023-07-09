//
//  MultiIdCard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/28/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class MultiIdCard: Hashable, Equatable {
    var ids: [String]
    
    private var cards_: [Card]?
    
    var cards: [Card] {
        if let c = cards_ {
            return c
        }
        let c = ids.compactMap({ x in Cards.by(cardId: x)})
        cards_ = c
        return c
    }
    
    var isWild: Bool { cards.any({ x in !CardSet.classicSets().contains(x.set ?? .invalid)})}
    var isClassic: Bool { cards.any({ x in CardSet.classicSets().contains(x.set ?? .invalid)})}
    var isStandard: Bool { cards.any({ x in !CardSet.wildSets().contains(x.set ?? .invalid) && !CardSet.classicSets().contains(x.set ?? .invalid)})}
    var isTwist: Bool { cards.any({ x in CardSet.twistSets().contains(x.set ?? .invalid)})}
    
    func hasSet(set: CardSet) -> Bool {
        return cards.any { x in x.set == set }
    }
    
    init(_ ids: String...) {
        self.ids = ids
    }
    
    init(_ id: String) {
        self.ids = [id]
    }
    
    init(_ ids: [String]) {
        self.ids = ids
    }
    
    func getCardForFormat(format: Format) -> Card? {
        switch format {
        case .wild:
            return getCardForFormat(format: .ft_wild)
        case .standard:
            return getCardForFormat(format: .ft_standard)
        case .classic:
            return getCardForFormat(format: .ft_classic)
        case .twist:
            return getCardForFormat(format: .ft_twist)
        default:
            return nil
        }
    }
    
    func getCardForFormat(format: FormatType) -> Card {
        switch format {
        case .ft_wild:
            return cards.first { x in !CardSet.classicSets().contains(x.set ?? .invalid) } ?? cards[0]
        case .ft_classic:
            return cards.first { x in CardSet.classicSets().contains(x.set ?? .invalid) } ?? cards[0]
        case .ft_standard:
            return cards.first { x in !CardSet.wildSets().contains(x.set ?? .invalid) && !CardSet.classicSets().contains(x.set ?? .invalid) } ?? cards[0]
        case .ft_twist:
            return cards.first { x in CardSet.twistSets().contains(x.set ?? .invalid) } ?? cards[0]
        case .ft_unknown:
            return cards[0]
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ids)
    }

    static func == (lhs: MultiIdCard, rhs: MultiIdCard) -> Bool {
        return lhs.ids == rhs.ids
    }
    
    static func == (lhs: MultiIdCard, rhs: String) -> Bool {
        return lhs.ids.contains(rhs)
    }

    static func != (lhs: MultiIdCard, rhs: String) -> Bool {
        return !(lhs == rhs)
    }
}

class QuantifiedMultiIdCard: MultiIdCard {
    var count: Int
    
    init(baseCard: MultiIdCard, count: Int) {
        self.count = count
        super.init(baseCard.ids)
    }
}
