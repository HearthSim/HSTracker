/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Foundation
import CleanroomLogger

struct RachelleHandler {
    // swiftlint:disable line_length
    static let TowardsGolds = "(\\d)/3 wins towards 10 gold"
    static let CardInCache = ".*somehow the card def for (\\w+_\\w+) was already in the cache\\.\\.\\."
    // swiftlint:enable line_length

    func handle(game: Game, _ line: String) {
        if line.match(self.dynamicType.TowardsGolds) {
            if let match = line.matches(self.dynamicType.TowardsGolds).first,
                victories = Int(match.value) {
                Log.info?.message("\(victories) / 3 -> 10 gold")
            }
        }

        if line.match(self.dynamicType.CardInCache) {
            if let match = line.matches(self.dynamicType.CardInCache).first {
                let cardId: String = match.value
                if let card = Cards.byId(cardId) {
                    if game.currentGameMode == .Arena {
                        Log.verbose?.message("Possible arena card draft : \(card) ?")
                    } else {
                        Log.verbose?.message("Possible constructed card draft : \(card) ?")
                    }
                }
            }
        }
    }
}
