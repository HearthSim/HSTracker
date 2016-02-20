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
    static let TowardsGolds = "(\\d)/3 wins towards 10 gold"
    static let CardInCache = ".*somehow the card def for (\\w+_\\w+) was already in the cache\\.\\.\\."

    static func handle(line: String) {
        if line.isMatch(NSRegularExpression.rx(TowardsGolds)) {
            if let victories = Int(line.firstMatch(NSRegularExpression.rx(TowardsGolds))) {
                DDLogInfo("\(victories) / 3 -> 10 gold")
            }
        }

        if line.isMatch(NSRegularExpression.rx(CardInCache)) {
            let match = line.firstMatchWithDetails(NSRegularExpression.rx(CardInCache))
            let cardId: String = match.groups[1].value
            if Game.instance.gameMode == .Arena {
                DDLogInfo("Possible arena card draft : \(cardId) ?")
            } else {
                DDLogInfo("Possible constructed card draft : \(cardId) ?")
            }
        }
    }
}
