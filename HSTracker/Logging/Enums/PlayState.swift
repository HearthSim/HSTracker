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

enum PlayState: Int, EnumCollection {
    case invalid = 0,
    playing = 1,
    winning = 2,
    losing = 3,
    won = 4,
    lost = 5,
    tied = 6,
    disconnected = 7,
    conceded = 8

    init?(rawString: String) {
        let string = rawString.lowercased()
        for _enum in PlayState.cases() where "\(_enum)" == string {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = PlayState(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }
}
