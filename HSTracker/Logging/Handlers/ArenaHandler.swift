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
    
    // swiftlint:disable line_length
    static let HeroRegex = "Draft Deck ID: (\\d+), Hero Card = (HERO_\\d+)"
    static let DeckContainsRegex = "Draft deck contains card (\\w*)"
    static let ClientChoosesRegex = "Client chooses: .* \\((\\w*)\\)"
    // swiftlint:enable line_length
    
    static var token: dispatch_once_t = 0
    
    func handle(game: Game, line: String) {
        let draft = Draft.instance
        print(line)
        
        // Hero match
        if line.match(self.dynamicType.HeroRegex) {
            let matches = line.matches(self.dynamicType.HeroRegex)
            if let heroID = Cards.heroById(matches[1].value) {
                draft.startDraft(heroID.playerClass)
            } else {
                Log.error?.message("Hero didn't match, failing")
            }
        }
        // Deck contains card
        else if line.match(self.dynamicType.DeckContainsRegex) {
            if let match = line.matches(self.dynamicType.DeckContainsRegex).first {
                if let card = Cards.byId(match.value) {
                    Log.debug?.message("Adding card \(card)")
                    draft.addCard(card)
                }
            }
        }
            
        // Client selects a card
        else if line.match(self.dynamicType.ClientChoosesRegex) {
            if let match = line.matches(self.dynamicType.ClientChoosesRegex).first {
                if let card = Cards.byId(match.value) {
                    Log.debug?.message("Client selected card \(card)")
                    draft.addCard(card)
                }
            }
        }
        
        // We're doing 25 because there's an issue where the logger doesn't
        // log duplicate cards multiple times.
        if draft.deck?.countCards() == 15 {
            dispatch_once(&self.dynamicType.token) { () -> Void in
                NSNotificationCenter.defaultCenter()
                    .postNotification(NSNotification(name: "arena_deck_full", object: nil))
            }
        }
    }
}
