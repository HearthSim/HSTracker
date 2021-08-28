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
import RegexUtil

struct RachelleHandler: LogEventParser {
    let TowardsGolds: RegexPattern = "(\\d)/3 wins towards 10 gold"
    let CardInCache: RegexPattern = ".*somehow the card def for (\\w+_\\w+) was already in the cache\\.\\.\\."

    func handle(logLine: LogLine) {
        if logLine.line.match(TowardsGolds) {
            if let match = logLine.line.matches(TowardsGolds).first,
                let victories = Int(match.value) {
                logger.info("\(victories) / 3 -> 10 gold")
            }
        }
    }
}
