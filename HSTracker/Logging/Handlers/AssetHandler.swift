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

    static let MedalRank = "Medal_Ranked_(\\d+)"
    static let UnloadingCard = "unloading name=(\\w+_\\w+) family=CardPrefab persistent=False"

    func handle(game: Game, line: String) {

        if game.awaitingRankedDetection {
            game.lastAssetUnload = NSDate().timeIntervalSince1970
            game.awaitingRankedDetection = false
        }

        if line.match(self.dynamicType.MedalRank) {
            let match = line.matches(self.dynamicType.MedalRank)
            if let match = match.first, rank = Int(match.value) {
                game.setPlayerRank(rank)
            }
        } else if line.contains("victory_screen_start") {
            game.victoryScreenShow = true
        } else if line.contains("rank_window") {
            game.currentGameMode = .Ranked
        } else if line.match(self.dynamicType.UnloadingCard) {
            let match = line.matches(self.dynamicType.UnloadingCard)
            if let match = match.first {
                let cardId = match.value

                if let card = Cards.byId(cardId) {
                    if game.currentMode == Mode.DRAFT && game.previousMode == Mode.HUB {
                        Log.verbose?.message("Possible arena card draft : \(card) ?")
                    } else if (game.currentMode == Mode.COLLECTIONMANAGER
                        || game.currentMode == Mode.TAVERN_BRAWL)
                        && game.previousMode == Mode.HUB {
                        Log.verbose?.message("Possible constructed card draft : \(card) ?")
                    }
                }
            }
        } else if line.contains("unloading name=Tavern_Brawl") {
            game.currentGameMode = .Brawl
        }
    }
}
