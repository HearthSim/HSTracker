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

struct ArenaHandler {

    let HeroRegex = "Draft Deck ID: (\\d+), Hero Card = (HERO_\\w+)"
    let ClientChoosesRegex = "Client chooses: .* \\((\\w*)\\)"

    func handle(game: Game, logLine: LogLine) {

        if logLine.line.match(HeroRegex) {
            let matches = logLine.line.matches(HeroRegex)
            if let heroID = Cards.hero(byId: matches[1].value),
               let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone {
                Log.info?.message("Found arena hero : \(heroID.playerClass)")
                hearthstone.arenaWatcher.hero = heroID.playerClass
            }
        } else if logLine.line.contains("IN_REWARDS") && game.currentMode == .draft {
            //Watchers.ArenaWatcher.Update();
        } else if logLine.line.match(ClientChoosesRegex) {
            if let match = logLine.line.matches(ClientChoosesRegex).first,
               let card = Cards.hero(byId: match.value),
               let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone {
                Log.info?.message("Client choose arena hero : \(card.playerClass)")
                hearthstone.arenaWatcher.hero = card.playerClass
            }
        }
    }
}