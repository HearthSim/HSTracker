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
    static let HeroRegex = "Draft Deck ID: (\\d+), Hero Card = (HERO_\\w+)"
    static let DeckContainsRegex = "Draft deck contains card (\\w*)"
    static let ClientChoosesRegex = "Client chooses: .* \\((\\w*)\\)"
    // swiftlint:enable line_length
    
    func handle(game: Game, logLine: LogLine) {
        let draft = Draft.instance
        
        // Hero match
        if logLine.line.match(self.dynamicType.HeroRegex) {
            let matches = logLine.line.matches(self.dynamicType.HeroRegex)
            if let heroID = Cards.hero(byId: matches[1].value) {
                draft.startDraft(heroID.playerClass)
            } else {
                Log.error?.message("Hero didn't match, failing")
            }
        }
        // Deck contains card
        else if logLine.line.match(self.dynamicType.DeckContainsRegex) {
            if let match = logLine.line.matches(self.dynamicType.DeckContainsRegex).first {
                if let card = Cards.byId(match.value) {
                    Log.verbose?.message("Adding card \(card)")
                    draft.addCard(card)
                }
            }
        }
        // Client selects a card
        else if logLine.line.match(self.dynamicType.ClientChoosesRegex) {
            if let match = logLine.line.matches(self.dynamicType.ClientChoosesRegex).first {
                if let card = Cards.byId(match.value) {
                    Log.verbose?.message("Client selected card \(card)")
                    draft.addCard(card)
                } else if let card = Cards.hero(byId: match.value) {
                    draft.startDraft(card.playerClass)
                }
            }
        }
    }
}
