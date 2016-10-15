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
    case invalid,
    deathknight,
    druid,
    hunter,
    mage,
    paladin,
    priest,
    rogue,
    shaman,
    warlock,
    warrior,
    dream

    init?(rawString: String) {
        for _enum in TagClass.allValues() {
            if "\(_enum)" == rawString.lowercaseString {
                self = _enum
                return
            }
        }
        if let value = Int(rawString), let _enum = TagClass(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }

    static func allValues() -> [TagClass] {
        return [.invalid, .deathknight, .druid, .hunter, .mage,
                .paladin, .priest, .rogue, .shaman, .warlock,
                .warrior, .dream]
    }
}
