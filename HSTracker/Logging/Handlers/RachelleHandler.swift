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

struct RachelleHandler: LogEventParser {
    let TowardsGolds = Regex("(\\d)/3 wins towards 10 gold")

    func handle(logLine: LogLine) {
        if TowardsGolds.match(logLine.line) {
            if let match = TowardsGolds.matches(logLine.line).first,
                let victories = Int(match.value) {
                logger.info("\(victories) / 3 -> 10 gold")
            }
        }
    }
}
