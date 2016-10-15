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

struct AssetHandler {

    let UnloadingCard = "unloading name=(\\w+_\\w+) family=CardPrefab persistent=False"

    func handle(game: Game, logLine: LogLine) {
        if logLine.line.contains("rank_window") {
            game.currentGameMode = .ranked
        } else if logLine.line.match(UnloadingCard) {
            let match = logLine.line.matches(UnloadingCard)
            if let match = match.first {
                let cardId = match.value

                if let card = Cards.by(cardId: cardId) {
                    if game.currentMode == .draft && game.previousMode == .hub {
                        Log.verbose?.message("Possible arena card draft : \(card) ?")
                    } else if (game.currentMode == .collectionmanager
                        || game.currentMode == .tavern_brawl)
                        && game.previousMode == .hub {
                        Log.verbose?.message("Possible constructed card draft : \(card) ?")
                    }
                }
            }
        } else if logLine.line.contains("unloading name=Tavern_Brawl") {
            game.currentGameMode = .brawl
        }
    }
}
