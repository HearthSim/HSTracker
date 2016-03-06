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
        let game = Game.instance

        game.currentMode = Mode(rawValue: match.groups[2].value)
        game.previousMode = Mode(rawValue: match.groups[1].value)

        var newMode: GameMode?
        if let mode = game.currentMode, currentMode = getGameMode(mode) {
            newMode = currentMode
        }
        else if let mode = game.currentMode, currentMode = getGameMode(mode) {
            newMode = currentMode
        }

        if let newMode = newMode where !(game.currentGameMode == .Ranked && newMode == .Casual) {
            DDLogInfo("Game mode : \(newMode)")
            game.currentGameMode = newMode
        }
        if game.previousMode == .GAMEPLAY {
            // game.handleInMenu()
        }
        if let currentMode = game.currentMode {
            switch currentMode {
            case .COLLECTIONMANAGER,
                    .TAVERN_BRAWL:
                // gameState.GameHandler.ResetConstructedImporting();
                break

            case .DRAFT:
                // game.ResetArenaCards();
                break

            default: break
            }
        }
    }

    static func getGameMode(mode: Mode) -> GameMode? {
        switch mode {
        case Mode.TOURNAMENT: return .Casual
        case Mode.FRIENDLY: return .Friendly
        case Mode.DRAFT: return .Arena
        case Mode.ADVENTURE: return .Practice
        case Mode.TAVERN_BRAWL: return .Brawl
        default: return nil
        }
    }
}
