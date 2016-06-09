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

// swiftlint:disable type_name

enum CardType: Int {
    case INVALID = 0,
    GAME = 1,
    PLAYER = 2,
    HERO = 3,
    MINION = 4,
    SPELL = 5,
    ENCHANTMENT = 6,
    WEAPON = 7,
    ITEM = 8,
    TOKEN = 9,
    HERO_POWER = 10

    init?(rawString: String) {
        for _enum in CardType.allValues() {
            if "\(_enum)" == rawString {
                self = _enum
                return
            }
        }
        if let value = Int(rawString), _enum = CardType(rawValue: value) {
            self = _enum
            return
        }
        self = .INVALID
    }

    static func allValues() -> [CardType] {
        return [.INVALID, .GAME, .PLAYER, .HERO, .MINION, .SPELL,
                .ENCHANTMENT, .WEAPON, .ITEM, .TOKEN, .HERO_POWER]
    }
}
