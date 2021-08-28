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
    
    private let showExperienceDuringMode = [ Mode.hub, Mode.game_mode, Mode.tournament, Mode.bacon, Mode.draft, Mode.pvp_dungeon_run ]
	
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

            if logLine.time.timeIntervalSinceNow < 5 {
                if let currentMode = game.currentMode, currentMode == .hub && !MirrorHelper.isInitialized() {
                    DispatchQueue.global().async {
                        if MirrorHelper.getAccountId() != nil {
                            ExperienceWatcher._instance.startWatching()
                        }
                    }
                }
            }
            
            if let currentMode = game.currentMode, showExperienceDuringMode.contains(currentMode) {
                game.windowManager.experiencePanel.visible = true
                game.updateExperienceOverlay()
            } else {
                if let previousMode = game.previousMode, showExperienceDuringMode.contains(previousMode) {
                    game.windowManager.experiencePanel.visible = false
                    game.updateExperienceOverlay()
                }
            }
        
            if game.previousMode == .gameplay && game.currentMode != .gameplay {
                game.inMenu()
            }
            
            if game.currentMode == Mode.collectionmanager {
                CollectionWatcher.start(toaster: coreManager.toaster)
            } else {
                CollectionWatcher.stop()
            }
            
            if game.currentMode == Mode.tournament {
                DeckWatcher.start()
            } else {
                DeckWatcher.stop()
            }

            if game.currentMode == .draft {
                ArenaDeckWatcher.start()
                if Settings.showArenaHelper {
                    ArenaWatcher.start(handler: game)
                }
            } else {
                ArenaDeckWatcher.stop()
                ArenaWatcher.stop()
            }
            
            if game.currentMode == .packopening {
                coreManager.packWatcher.startWatching()
            } else {
                coreManager.packWatcher.stopWatching()
            }
            
            if game.currentMode == .tavern_brawl {
                game.cacheBrawlInfo()
            }
            
            if game.currentMode == .bacon {
                game.cacheBattlegroundRatingInfo()
            }
            
            if game.currentMode == .adventure || game.previousMode == Mode.adventure && game.currentMode == .gameplay {
                DungeonRunDeckWatcher.start()
            } else {
                DungeonRunDeckWatcher.stop()
            }
            
            if game.currentMode == Mode.pvp_dungeon_run || game.previousMode == Mode.pvp_dungeon_run && game.currentMode == Mode.gameplay {
                PVPDungeonRunWatcher.start()
            } else {
                PVPDungeonRunWatcher.stop()
            }
        } else if logLine.line.contains("Gameplay.Start") {
            // uncommenting this line will prevent powerlog reader to work properly
            coreManager.game.gameStart(at: logLine.time)
        }
    }
}
