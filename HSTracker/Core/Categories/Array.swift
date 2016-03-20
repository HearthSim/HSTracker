/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */

extension Array where Element: Card {
    func sortCardList() -> [Card] {
        return self.sort { $0.name < $1.name }
            .sort { $1.type < $0.type }
            .sort { $0.cost < $1.cost }
    }

    func toDict() -> [String: Int] {
        var result = [String: Int]()
        for card in self {
            result[card.cardId] = card.count
        }
        return result
    }
}

protocol Dictable {
    func toDict() -> [String: AnyObject]
}

extension Array where Element: Dictable {
    func toDict() -> [[String: AnyObject]] {
        var result = [[String: AnyObject]]()
        for element in self {
            result.append(element.toDict())
        }
        return result
    }
}

extension Array where Element: Equatable {
    mutating func remove(e: Element) {
        if let index = indexOf(e) {
            removeAtIndex(index)
        }
    }
}
