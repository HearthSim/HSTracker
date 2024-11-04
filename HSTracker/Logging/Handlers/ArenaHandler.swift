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

    let HeroRegex = Regex("Draft Deck ID: (\\d+), Hero Card = (HERO_\\w+)")
    let ClientChoosesRegex = Regex("Client chooses: .* \\((\\w*)\\)")

	private let coreManager: CoreManager
	
	init(with coreManager: CoreManager) {
		self.coreManager = coreManager
	}
	
    func handle(logLine: LogLine) {

        if HeroRegex.match(logLine.line) {
            let matches = HeroRegex.matches(logLine.line)
            if let heroID = Cards.hero(byId: matches[1].value) {
                logger.info("Found arena hero : \(heroID.playerClass)")
            }
        } else if logLine.line.contains("IN_REWARDS") && coreManager.game.currentMode == .draft {
            //Watchers.ArenaWatcher.Update();
        } else if ClientChoosesRegex.match(logLine.line) {
            if let match = ClientChoosesRegex.matches(logLine.line).first,
               let card = Cards.hero(byId: match.value) {
                logger.info("Client choose arena hero : \(card.playerClass)")
            }
        }
    }
}
