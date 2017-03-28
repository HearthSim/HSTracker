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

struct LoadingScreenHandler: LogEventParser {
	
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
                ArenaDeckWatcher.start()
                if Settings.showArenaHelper {
                    coreManager.arenaWatcher.startWatching()
                }
            } else if game.previousMode == .draft {
                coreManager.arenaWatcher.stopWatching()
                ArenaDeckWatcher.stop()
            } else if game.currentMode == .packopening {
                coreManager.packWatcher.startWatching()
            } else if game.previousMode == .packopening {
                coreManager.packWatcher.stopWatching()
            } else if game.currentMode == .tournament {
                DeckWatcher.start()
            } else if game.previousMode == .tournament {
                DeckWatcher.stop()
            } else if game.currentMode == .hub {
                //game.clean()
            }

        } else if logLine.line.contains("Gameplay.Start") {
            // uncommenting this line will prevent powerlog reader to work properly
            //coreManager.game.gameStart(at: logLine.time)
        }
    }
}
