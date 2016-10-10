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

    static let UnloadingCard = "unloading name=(\\w+_\\w+) family=CardPrefab persistent=False"

    func handle(game: Game, logLine: LogLine) {
        if logLine.line.contains("rank_window") {
            game.currentGameMode = .Ranked
        } else if logLine.line.match(self.dynamicType.UnloadingCard) {
            let match = logLine.line.matches(self.dynamicType.UnloadingCard)
            if let match = match.first {
                let cardId = match.value

                if let card = Cards.by(cardId: cardId) {
                    if game.currentMode == Mode.DRAFT && game.previousMode == Mode.HUB {
                        Log.verbose?.message("Possible arena card draft : \(card) ?")
                    } else if (game.currentMode == Mode.COLLECTIONMANAGER
                        || game.currentMode == Mode.TAVERN_BRAWL)
                        && game.previousMode == Mode.HUB {
                        Log.verbose?.message("Possible constructed card draft : \(card) ?")
                    }
                }
            }
        } else if logLine.line.contains("unloading name=Tavern_Brawl") {
            game.currentGameMode = .Brawl
        }
    }
}
