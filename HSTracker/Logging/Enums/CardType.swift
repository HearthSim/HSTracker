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

enum CardType: Int, EnumCollection {
    case invalid = 0,
    game = 1,
    player = 2,
    hero = 3,
    minion = 4,
    spell = 5,
    enchantment = 6,
    weapon = 7,
    item = 8,
    token = 9,
    hero_power = 10

    init?(rawString: String) {
        let string = rawString.lowercased()
        for _enum in CardType.cases() where "\(_enum)" == string {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = CardType(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }
    
    func rawString() -> String {
        return "\(self)".replace("_", with: " ")
    }
}
