/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */

extension Dictionary {
    mutating func update(_ other: Dictionary) {
        for (key, value) in other {
            updateValue(value, forKey: key)
        }
    }
}

enum CardListSorting: Int {
    case cost, mulliganWr
}

extension Array where Element == Card {
    func sortCardList(_ sorting: CardListSorting = .cost) -> [Card] {
        if sorting == .cost {
            return sorted {
                if $0.cost == $1.cost {
                    if $0.name == $1.name {
                        return $0.extraInfo?.cardNameSuffix ?? "" < $0.extraInfo?.cardNameSuffix ?? ""
                    }
                    return $0.name < $1.name
                }
                return $0.cost < $1.cost
            }
        }
        return sorted {
            if $0.cardWinRates?.mulliganWinRate == $1.cardWinRates?.mulliganWinRate {
                if $0.cost == $1.cost {
                    return $0.name < $1.name
                }
                return $0.cost < $1.cost
            }
            return ($0.cardWinRates?.mulliganWinRate ?? 0.0) > ($1.cardWinRates?.mulliganWinRate ?? 0.0)
        }
    }

    func countCards() -> Int {
        return map({ $0.count }).reduce(0, +)
    }

    func isValidDeck() -> Bool {
        let count = countCards()
        return count == 30 || count == 40
    }
    
    static func addCard(_ cards: inout [Card], _ newCard: Card) {
        let existingCard = cards.first { c in c.id == newCard.id }
        
        if existingCard != nil {
            existingCard?.count += newCard.count
        } else {
            cards.append(newCard)
        }
    }
    
    func addCardRange(_ newCards: [Card]) -> [Card] {
        var cards = self
        for card in newCards {
            [Card].addCard(&cards, card)
        }
        return cards
    }
    
    func concatCardList(_ newCards: [Card]) -> [Card] {
        return addCardRange(newCards)
    }
}

extension Array {
    func group<K: Hashable>(_ fn: (Element) -> K) -> [K: [Element]] {
        return Dictionary(grouping: self, by: fn) as [K: [Element]]
    }

    func any(_ fn: (Element) -> Bool) -> Bool {
        return filter(fn).count > 0
    }

    func all(_ fn: (Element) -> Bool) -> Bool {
        return filter(fn).count == count
    }

    func take(_ count: Int) -> [Element] {
        return Array(prefix(count))
    }
    
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var alreadyAdded = Set<Iterator.Element>()
        return filter { alreadyAdded.insert($0).inserted }
    }
}

extension Array where Element: Equatable {
    mutating func remove(_ element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
    }
}
