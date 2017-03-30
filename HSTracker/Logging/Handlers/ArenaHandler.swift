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
import CleanroomLogger
import RegexUtil

struct ArenaHandler: LogEventParser {

    let HeroRegex = "Draft Deck ID: (\\d+), Hero Card = (HERO_\\w+)"
    let ClientChoosesRegex = "Client chooses: .* \\((\\w*)\\)"

	private unowned let coreManager: CoreManager
	
	init(with coreManager: CoreManager) {
		self.coreManager = coreManager
	}
	
    func handle(logLine: LogLine) {

        if logLine.line.match(HeroRegex) {
            let matches = logLine.line.matches(HeroRegex)
            if let heroID = Cards.hero(byId: matches[1].value) {
                Log.info?.message("Found arena hero : \(heroID.playerClass)")
                coreManager.arenaWatcher.hero = heroID.playerClass
            }
        } else if logLine.line.contains("IN_REWARDS") && coreManager.game.currentMode == .draft {
            //Watchers.ArenaWatcher.Update();
        } else if logLine.line.match(ClientChoosesRegex) {
            if let match = logLine.line.matches(ClientChoosesRegex).first,
               let card = Cards.hero(byId: match.value) {
                Log.info?.message("Client choose arena hero : \(card.playerClass)")
                coreManager.arenaWatcher.hero = card.playerClass
            }
        }
    }
}
