/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Foundation

struct ArenaHandler: LogEventParser {

	private let coreManager: CoreManager
	
	init(with coreManager: CoreManager) {
		self.coreManager = coreManager
	}
	
    func handle(logLine: LogLine) {

        if logLine.line.contains("IN_REWARDS") && coreManager.game.currentMode == .draft {
            _ = Watchers.arenaWatcher.update()
        } else if (logLine.line.contains("DRAFTING") || logLine.line.contains("REDRAFTING")) && coreManager.game.currentMode == .draft {
            Watchers.arenaWatcher.run()
        }
    }
}
