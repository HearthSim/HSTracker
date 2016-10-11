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

    let GameModeRegex = "prevMode=(\\w+).*currMode=(\\w+)"

    func handle(game: Game, logLine: LogLine) {
        if logLine.line.match(GameModeRegex) {
            let matches = logLine.line.matches(GameModeRegex)
            
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
            if game.previousMode == .GAMEPLAY && game.currentMode != .GAMEPLAY {
                game.inMenu()
            }
        } else if logLine.line.contains("Gameplay.Start") {
            game.gameStart(logLine.time)
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
