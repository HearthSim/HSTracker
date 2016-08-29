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
    case All, //for filtering @ deck stats
    Ranked,
    Casual,
    Arena,
    Brawl,
    Friendly,
    Practice,
    Spectator,
    None

    static func unboxFallbackValue() -> GameMode {
        return .None
    }
    
    var userFacingName: String {
        switch self {
        case .All:       return NSLocalizedString("mode_all", comment: "")
        case .Ranked:    return NSLocalizedString("mode_ranked", comment: "")
        case .Casual:    return NSLocalizedString("mode_casual", comment: "")
        case .Arena:     return NSLocalizedString("mode_arena", comment: "")
        case .Brawl:     return NSLocalizedString("mode_brawl", comment: "")
        case .Friendly:  return NSLocalizedString("mode_friendly", comment: "")
        case .Practice:  return NSLocalizedString("mode_practice", comment: "")
        case .Spectator: return NSLocalizedString("mode_spectator", comment: "")
        case .None:      return NSLocalizedString("mode_none", comment: "")
        }
    }
}
