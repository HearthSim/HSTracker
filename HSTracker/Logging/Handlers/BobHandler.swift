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

class BobHandler {
    static func handle(game: Game, _ line: String) {

        let legendRank = NSRegularExpression.rx("legend rank (\\d+)")
        if !line.isMatch(legendRank) {
            /*let match = line.firstMatchWithDetails(legendRank)
             if let rank = Int(match.groups[1].value) {
             game.MetaData.LegendRank = rank;
             }*/
        }
    }
}
