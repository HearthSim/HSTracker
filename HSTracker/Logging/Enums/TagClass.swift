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

enum TagClass: Int, EnumCollection {
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
        let string = rawString.lowercased()
        for _enum in TagClass.cases() where "\(_enum)" == string {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = TagClass(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }

    var cardClassValue: CardClass {
        switch self {
        case .druid: return CardClass.druid
        case .hunter: return CardClass.hunter
        case .mage: return CardClass.mage
        case .paladin: return CardClass.paladin
        case .priest: return CardClass.priest
        case .rogue: return CardClass.rogue
        case .shaman: return CardClass.shaman
        case .warlock: return CardClass.warlock
        case .warrior: return CardClass.warrior

        case .invalid, .deathknight, .dream: return CardClass.neutral
        }
    }
}
