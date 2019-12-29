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
import RegexUtil

struct LoadingScreenHandler: LogEventParser {
	
	private unowned(unsafe) let coreManager: CoreManager
	
	init(with coreManager: CoreManager) {
		self.coreManager = coreManager
	}

    let GameModeRegex: RegexPattern = "prevMode=(\\w+).*currMode=(\\w+)"

    func handle(logLine: LogLine) {
        if logLine.line.match(GameModeRegex) {
            let matches = logLine.line.matches(GameModeRegex)
			let game = coreManager.game
            
            game.currentMode = Mode(rawValue: matches[1].value.lowercased()) ?? .invalid
            game.previousMode = Mode(rawValue: matches[0].value.lowercased()) ?? .invalid

            logger.info("Game mode from \(String(describing: game.previousMode)) "
                + "to \(String(describing: game.currentMode))")

            if game.previousMode == .gameplay && game.currentMode != .gameplay {
                game.inMenu()
            }

            switch game.currentMode {
            case Optional(.draft):
                ArenaDeckWatcher.start()
                if Settings.showArenaHelper {
                    ArenaWatcher.start(handler: game)
                }
            case Optional(.packopening):
                coreManager.packWatcher.startWatching()
            case Optional(.tournament):
                DeckWatcher.start()
            case Optional(.adventure):
                DeckWatcher.start()
                DungeonRunDeckWatcher.start()
            case Optional(.friendly):
                DeckWatcher.start()
            case Optional(.collectionmanager):
                CollectionWatcher.start(windowManager: game.windowManager)
            default: break
            }

            switch game.previousMode {
            case Optional(.draft):
                ArenaWatcher.stop()
                ArenaDeckWatcher.stop()
            case Optional(.packopening):
                coreManager.packWatcher.stopWatching()
            case Optional(.tournament):
                DeckWatcher.stop()
            case Optional(.adventure):
                DeckWatcher.stop()
                DungeonRunDeckWatcher.stop()
            case Optional(.friendly):
                DeckWatcher.stop()
            case Optional(.collectionmanager):
                CollectionWatcher.stop()
            default: break
            }

        } else if logLine.line.contains("Gameplay.Start") {
            // uncommenting this line will prevent powerlog reader to work properly
            //coreManager.game.gameStart(at: logLine.time)
        }
    }
}
