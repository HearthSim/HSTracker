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
import Wrap

enum Zone: Int, WrappableEnum, EnumCollection {
    case invalid = 0,
    play = 1,
    deck = 2,
    hand = 3,
    graveyard = 4,
    removedfromgame = 5,
    setaside = 6,
    secret = 7

    init?(rawString: String) {
        let string = rawString.lowercased()
        for _enum in Zone.cases() where "\(_enum)" == string {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = Zone(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }
}
