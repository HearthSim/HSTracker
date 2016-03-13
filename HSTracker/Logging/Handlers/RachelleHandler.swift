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
    static let TowardsGolds = NSRegularExpression.rx("(\\d)/3 wins towards 10 gold")
    static let CardInCache = NSRegularExpression.rx(".*somehow the card def for (\\w+_\\w+) was already in the cache\\.\\.\\.")

    static func handle(game: Game, _ line: String) {
        if line.isMatch(TowardsGolds) {
            if let victories = Int(line.firstMatch(TowardsGolds)) {
                DDLogInfo("\(victories) / 3 -> 10 gold")
            }
        }

        if line.isMatch(CardInCache) {
            let match = line.firstMatchWithDetails(CardInCache)
            let cardId: String = match.groups[1].value
            if game.currentGameMode == .Arena {
                DDLogInfo("Possible arena card draft : \(cardId) ?")
            } else {
                DDLogInfo("Possible constructed card draft : \(cardId) ?")
            }
        }
    }
}
