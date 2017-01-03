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
import Wrap

enum GameMode: Int, WrappableEnum {
    case all, //for filtering @ deck stats
    ranked,
    casual,
    arena,
    brawl,
    friendly,
    practice,
    spectator,
    none
    
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

    init(gameType: GameType) {
        switch gameType {
        case .gt_vs_ai:
            self = .practice
        case .gt_vs_friend:
            self = .friendly
        case .gt_arena:
            self = .arena
        case .gt_ranked:
            self = .ranked
        case .gt_casual:
            self = .casual
        case .gt_tavernbrawl, .gt_tb_2p_coop, .gt_tb_1p_vs_ai:
            self = .brawl
        default:
            self = .none
        }
    }
}
