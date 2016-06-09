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

enum TagClass: Int {
    case INVALID,
    DEATHKNIGHT,
    DRUID,
    HUNTER,
    MAGE,
    PALADIN,
    PRIEST,
    ROGUE,
    SHAMAN,
    WARLOCK,
    WARRIOR,
    DREAM

    init?(rawString: String) {
        for _enum in TagClass.allValues() {
            if "\(_enum)" == rawString {
                self = _enum
                return
            }
        }
        if let value = Int(rawString), _enum = TagClass(rawValue: value) {
            self = _enum
            return
        }
        self = .INVALID
    }

    static func allValues() -> [TagClass] {
        return [.INVALID, .DEATHKNIGHT, .DRUID, .HUNTER, .MAGE,
                .PALADIN, .PRIEST, .ROGUE, .SHAMAN, .WARLOCK,
                .WARRIOR, .DREAM]
    }
}
