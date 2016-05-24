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

struct NetHandler {

    // swiftlint:disable line_length
    static let ConnectRegex = "ConnectAPI\\.GotoGameServer -- address=(.+), game=(.+), client=(.+), spectateKey=(.+)"
    // swiftlint:enable line_length

    func handle(game: Game, line: String) {

        if line.match(self.dynamicType.ConnectRegex) {
            // let match = line.firstMatchWithDetails(NSRegularExpression.rx(regex))
            game.gameStart()
        }
    }
}
