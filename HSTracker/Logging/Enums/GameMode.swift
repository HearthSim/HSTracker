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
}
