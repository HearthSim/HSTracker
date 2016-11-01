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
    let DeckContainsRegex = "Draft deck contains card (\\w*)"
    let ClientChoosesRegex = "Client chooses: .* \\((\\w*)\\)"
    let DraftIdRegex = "Got new draft deck with ID: (\\d+)"
    
    func handle(game: Game, logLine: LogLine) {
        let draft = Draft.instance
        
        // Hero match
        if logLine.line.match(HeroRegex) {
            let matches = logLine.line.matches(HeroRegex)
            if let id = Int(matches[0].value),
                let heroID = Cards.hero(byId: matches[1].value) {
                draft.startDraft(for: heroID.playerClass)
                draft.hearthstoneId = id
                Log.info?.message("Found arena deck id : \(id)")
            } else {
                Log.error?.message("Hero didn't match, failing")
            }
        }
        // deck id
        else if logLine.line.match(DraftIdRegex) {
            if let match = logLine.line.matches(DraftIdRegex).first,
                let id = Int(match.value) {
                draft.hearthstoneId = id
                Log.info?.message("Found arena deck id : \(id)")
            }
        }
        // Deck contains card
        else if logLine.line.match(DeckContainsRegex) {
            if let match = logLine.line.matches(DeckContainsRegex).first {
                if let card = Cards.by(cardId: match.value) {
                    draft.add(card: card)
                }
            }
        }
        // Client selects a card
        else if logLine.line.match(ClientChoosesRegex) {
            if let match = logLine.line.matches(ClientChoosesRegex).first {
                if let card = Cards.by(cardId: match.value) {
                    Log.verbose?.message("Client selected card \(card)")
                    draft.add(card: card)
                } else if let card = Cards.hero(byId: match.value) {
                    draft.startDraft(for: card.playerClass)
                }
            }
        }
    }
}
