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

enum Zone: Int {
    case INVALID = -1,
         CREATED = 0,
         PLAY = 1,
         DECK = 2,
         HAND = 3,
         GRAVEYARD = 4,
         REMOVEDFROMGAME = 5,
         SETASIDE = 6,
         SECRET = 7

    init?(rawString: String) {
        for _enum in _ZoneAllValues {
            if "\(_enum)" == rawString {
                self = _enum
                return
            }
        }
        self = .CREATED
    }
}

let _ZoneAllValues: [Zone] = [.INVALID, .CREATED, .PLAY, .DECK, .HAND, .GRAVEYARD, .REMOVEDFROMGAME, .SETASIDE, .SECRET]