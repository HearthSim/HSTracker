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
        return self.sort {
            //DDLogVerbose("Comparing card \($0) with \($1)")
            if $0.cost != $1.cost {
                return $0.cost < $1.cost
            }

            if $0.type != $1.type {
                return $1.type < $0.type
            }

            return $0.name < $1.name
        }
    }

}

extension Array where Element: Equatable {
    mutating func remove(e: Element) {
        if let index = indexOf(e) {
            removeAtIndex(index)
        }
    }
}