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
	
	private unowned let hearthstone: Hearthstone
	
	init(with hearthstone: Hearthstone) {
		self.hearthstone = hearthstone
	}

    let GameModeRegex = "prevMode=(\\w+).*currMode=(\\w+)"

    func handle(logLine: LogLine) {
        if logLine.line.match(GameModeRegex) {
            let matches = logLine.line.matches(GameModeRegex)
			let game = hearthstone.game
            
            game.currentMode = Mode(rawValue: matches[1].value.lowercased()) ?? .invalid
            game.previousMode = Mode(rawValue: matches[0].value.lowercased()) ?? .invalid

            Log.info?.message("Game mode from \(game.previousMode) to \(game.currentMode)")

            if game.previousMode == .gameplay && game.currentMode != .gameplay {
                game.inMenu()
            }

            if game.currentMode == .draft {
                hearthstone.arenaDeckWatcher.start()
                if Settings.showArenaHelper {
                    hearthstone.arenaWatcher.start()
                }
            } else if game.previousMode == .draft {
                hearthstone.arenaWatcher.stop()
                hearthstone.arenaDeckWatcher.stop()
            } else if game.currentMode == .packopening {
                hearthstone.packWatcher.start()
            } else if game.previousMode == .packopening {
                hearthstone.packWatcher.stop()
            } else if game.currentMode == .tournament {
                hearthstone.deckWatcher.start()
            } else if game.previousMode == .tournament {
                hearthstone.deckWatcher.stop()
            } else if game.currentMode == .hub {
                game.clean()
            }

        } else if logLine.line.contains("Gameplay.Start") {
            hearthstone.game.gameStart(at: logLine.time)
        }
    }
}
