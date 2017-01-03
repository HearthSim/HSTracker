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
            
            game.currentMode = Mode(rawValue: matches[1].value.lowercased()) ?? .invalid
            game.previousMode = Mode(rawValue: matches[0].value.lowercased()) ?? .invalid

            Log.info?.message("Game mode from \(game.previousMode) to \(game.currentMode)")

            if game.previousMode == .gameplay && game.currentMode != .gameplay {
                game.inMenu()
            }

            if game.currentMode == .draft {
                //Watchers.ArenaWatcher.Run();
            } else if game.currentMode == .packopening {
                //Watchers.PackWatcher.Run();
            } else if game.currentMode == .tavern_brawl {
                //Core.Game.CacheBrawlInfo();
            } else {
                //Watchers.ArenaWatcher.Stop();
                //Watchers.PackWatcher.Stop();
            }

        } else if logLine.line.contains("Gameplay.Start") {
            game.gameStart(at: logLine.time)
        }
    }

    func getGameMode(mode: Mode) -> GameMode? {
        switch mode {
        case .tournament: return .casual
        case .friendly: return .friendly
        case .draft: return .arena
        case .adventure: return .practice
        case .tavern_brawl: return .brawl
        default: return .none
        }
    }
}
