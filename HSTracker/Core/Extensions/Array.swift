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
            self.updateValue(value, forKey: key)
        }
    }
}

extension Array where Element: Card {
    func sortCardList() -> [Card] {
        return sorted {
            if $0.cost == $1.cost {
                return $0.name < $1.name
            }
            return $0.cost < $1.cost
        }
    }

    func countCards() -> Int {
        return map({ $0.count }).reduce(0, +)
    }

    func isValidDeck() -> Bool {
        return countCards() == 30
    }
}

extension Array {
    func group<K: Hashable>(_ fn: (Element) -> K) -> [K: [Element]] {
        return Dictionary(grouping: self, by: fn) as [K: [Element]]
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var alreadyAdded = Set<Iterator.Element>()
        return self.filter { alreadyAdded.insert($0).inserted }
    }
}

extension Array where Element: Equatable {
    mutating func remove(_ element: Element) {
        if let index = index(of: element) {
            self.remove(at: index)
        }
    }
}
