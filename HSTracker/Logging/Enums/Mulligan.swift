/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 19/02/16.
 */

import Foundation

enum Mulligan: Int {
    case INVALID = 0,
    INPUT = 1,
    DEALING = 2,
    WAITING = 3,
    DONE = 4

    init?(rawString: String) {
        for _enum in Mulligan.allValues() {
            if "\(_enum)" == rawString {
                self = _enum
                return
            }
        }
        if let value = Int(rawString), _enum = Mulligan(rawValue: value) {
            self = _enum
            return
        }
        self = .INVALID
    }

    static func allValues() -> [Mulligan] {
        return [.INVALID, .INPUT, .DEALING, .WAITING, .DONE]
    }
}
