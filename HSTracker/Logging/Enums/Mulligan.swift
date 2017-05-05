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

enum Mulligan: Int, EnumCollection {
    case invalid = 0,
    input = 1,
    dealing = 2,
    waiting = 3,
    done = 4

    init?(rawString: String) {
        let string = rawString.lowercased()
        for _enum in Mulligan.cases() where "\(_enum)" == string {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = Mulligan(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }
}
