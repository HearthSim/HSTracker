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
import Unbox
import Wrap

enum GameMode: Int, UnboxableEnum, WrappableEnum {
    case all, //for filtering @ deck stats
    ranked,
    casual,
    arena,
    brawl,
    friendly,
    practice,
    spectator,
    none

    static func unboxFallbackValue() -> GameMode {
        return .none
    }
    
    var userFacingName: String {
        switch self {
        case .all: return NSLocalizedString("mode_all", comment: "")
        case .ranked: return NSLocalizedString("mode_ranked", comment: "")
        case .casual: return NSLocalizedString("mode_casual", comment: "")
        case .arena: return NSLocalizedString("mode_arena", comment: "")
        case .brawl: return NSLocalizedString("mode_brawl", comment: "")
        case .friendly: return NSLocalizedString("mode_friendly", comment: "")
        case .practice: return NSLocalizedString("mode_practice", comment: "")
        case .spectator: return NSLocalizedString("mode_spectator", comment: "")
        case .none: return NSLocalizedString("mode_none", comment: "")
        }
    }
}
