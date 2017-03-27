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

struct LoadingScreenHandler: LogEventHandler {
	
	private unowned let coreManager: CoreManager
	
	init(with coreManager: CoreManager) {
		self.coreManager = coreManager
	}

    let GameModeRegex = "prevMode=(\\w+).*currMode=(\\w+)"

    func handle(logLine: LogLine) {
        if logLine.line.match(GameModeRegex) {
            let matches = logLine.line.matches(GameModeRegex)
			let game = coreManager.game
            
            game.currentMode = Mode(rawValue: matches[1].value.lowercased()) ?? .invalid
            game.previousMode = Mode(rawValue: matches[0].value.lowercased()) ?? .invalid

            Log.info?.message("Game mode from \(game.previousMode) to \(game.currentMode)")

            if game.previousMode == .gameplay && game.currentMode != .gameplay {
                game.inMenu()
            }

            if game.currentMode == .draft {
                coreManager.arenaDeckWatcher.start()
                if Settings.showArenaHelper {
                    coreManager.arenaWatcher.start()
                }
            } else if game.previousMode == .draft {
                coreManager.arenaWatcher.stop()
                coreManager.arenaDeckWatcher.stop()
            } else if game.currentMode == .packopening {
                coreManager.packWatcher.start()
            } else if game.previousMode == .packopening {
                coreManager.packWatcher.stop()
            } else if game.currentMode == .tournament {
                coreManager.deckWatcher.start()
            } else if game.previousMode == .tournament {
                coreManager.deckWatcher.stop()
            } else if game.currentMode == .hub {
                //game.clean()
            }

        } else if logLine.line.contains("Gameplay.Start") {
            coreManager.game.gameStart(at: logLine.time)
        }
    }
}
