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
    mutating func update(other: Dictionary) {
        for (key, value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

extension Array where Element: Card {
    func sortCardList() -> [Card] {
        return sort {
            if $0.cost == $1.cost {
                return $0.name < $1.name
            }
            return $0.cost < $1.cost
        }
    }

    func toDict() -> [String: Int] {
        var result = [String: Int]()
        for card in self {
            result[card.id] = card.count
        }
        return result
    }

    func shuffleOne() -> Card? {
        return self[Int(arc4random()) % Int(count)]
    }
}

extension Array where Element: Equatable {
    mutating func remove(element: Element) {
        if let index = indexOf(element) {
            removeAtIndex(index)
        }
    }
}
