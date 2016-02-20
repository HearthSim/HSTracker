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

enum PlayState: Int {
    case INVALID = 0,
         PLAYING = 1,
         WINNING = 2,
         LOSING = 3,
         WON = 4,
         LOST = 5,
         TIED = 6,
         DISCONNECTED = 7,
         CONCEDED = 8

    init?(rawString: String) {
        for _enum in _PlayStateAllValues {
            if "\(_enum)" == rawString {
                self = _enum
                return
            }
        }
        self = .INVALID
    }
}

let _PlayStateAllValues: [PlayState] = [.INVALID, .PLAYING, .WINNING, .LOSING, .WON, .LOST, .TIED, .DISCONNECTED, .CONCEDED]