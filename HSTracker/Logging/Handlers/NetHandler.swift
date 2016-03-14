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

class NetHandler {

    let ConnectRegex = "ConnectAPI\\.GotoGameServer -- address=(.+), game=(.+), client=(.+), spectateKey=(.+)"

    func handle(game: Game, _ line: String) {

        if line.match(ConnectRegex) {
            // let match = line.firstMatchWithDetails(NSRegularExpression.rx(regex))
            game.gameStart()
        }
    }
}
