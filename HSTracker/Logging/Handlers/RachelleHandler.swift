/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

class RachelleHandler {
    let TowardsGolds = "(\\d)/3 wins towards 10 gold"
    let CardInCache = ".*somehow the card def for (\\w+_\\w+) was already in the cache\\.\\.\\."

    func handle(game: Game, _ line: String) {
        if line.match(TowardsGolds) {
            if let match = line.matches(TowardsGolds).first,
                let victories = Int(match.value) {
                    DDLogInfo("\(victories) / 3 -> 10 gold")
            }
        }

        if line.match(CardInCache) {
            if let match = line.matches(CardInCache).first {
                let cardId: String = match.value
                if game.currentGameMode == .Arena {
                    DDLogInfo("Possible arena card draft : \(cardId) ?")
                } else {
                    DDLogInfo("Possible constructed card draft : \(cardId) ?")
                }
            }
        }
    }
}
