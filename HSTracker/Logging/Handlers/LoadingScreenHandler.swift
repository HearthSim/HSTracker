/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */

import Foundation

class LoadingScreenHandler {

    static func handle(line: String) {
        let regex = "prevMode=(\\w+).*currMode=(\\w+)"

        if !line.isMatch(NSRegularExpression.rx(regex)) {
            return
        }

        let match = line.firstMatchWithDetails(NSRegularExpression.rx(regex))
        let prev: String = match.groups[1].value
        if let newMode = self.parseGameMode(match.groups[2].value) {

            let game = Game.instance
            if !(game.gameMode == .Ranked && newMode == .Casual) {
                game.gameMode = newMode
            }
            if (prev == "GAMEPLAY") {
                //gameState.GameHandler.HandleInMenu();
            }
        }
    }

    static func parseGameMode(mode: String) -> GameMode? {
        switch mode {
        case "ADVENTURE":
            return .Practice
        case "TAVERN_BRAWL":
            return .Brawl
        case "TOURNAMENT":
            return .Casual
        case "DRAFT":
            return .Arena
        case "FRIENDLY":
            return .Friendly
        default:
            return nil
        }
    }

}
