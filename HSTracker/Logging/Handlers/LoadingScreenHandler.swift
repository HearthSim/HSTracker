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
import CleanroomLogger

struct LoadingScreenHandler {

    static let GameModeRegex = "prevMode=(\\w+).*currMode=(\\w+)"

    func handle(game: Game, line: String) {
        if !line.match(self.dynamicType.GameModeRegex) {
            return
        }

        let matches = line.matches(self.dynamicType.GameModeRegex)

        game.currentMode = Mode(rawValue: matches[1].value)
        game.previousMode = Mode(rawValue: matches[0].value)

        var newMode: GameMode?
        if let mode = game.currentMode, currentMode = getGameMode(mode) {
            newMode = currentMode
        } else if let mode = game.currentMode, currentMode = getGameMode(mode) {
            newMode = currentMode
        }

        if let newMode = newMode { 
            Log.info?.message("Game mode : \(newMode)")
            game.currentGameMode = newMode
        }
        if game.previousMode == .GAMEPLAY {
            game.inMenu()
        }
        if let currentMode = game.currentMode {
            switch currentMode {
            case .COLLECTIONMANAGER, .TAVERN_BRAWL:
                // gameState.GameHandler.ResetConstructedImporting();
                break

            case .DRAFT:
                Log.info?.message("Resetting arena draft.")
                Draft.instance.resetDraft()
                break

            default: break
            }
        }
    }

    func getGameMode(mode: Mode) -> GameMode? {
        switch mode {
        case Mode.TOURNAMENT: return .Casual
        case Mode.FRIENDLY: return .Friendly
        case Mode.DRAFT: return .Arena
        case Mode.ADVENTURE: return .Practice
        case Mode.TAVERN_BRAWL: return .Brawl
        default: return .None
        }
    }
}
