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

class AssetHandler {

    static let MedalRank = "Medal_Ranked_(\\d+)"
    static let UnloadingCard = "unloading name=(\\w+_\\w+) family=CardPrefab persistent=False"

    static func handle(game: Game, _ line: String) {

        if game.awaitingRankedDetection {
            game.lastAssetUnload = NSDate().timeIntervalSince1970
            game.awaitingRankedDetection = false
        }

        if line.match(MedalRank) {
            let match = line.matches(MedalRank)
            if let match = match.first,
                let rank = Int(match.value) {
                    game.currentGameMode = .Ranked
                    game.setPlayerRank(rank)
            }
        } else if line.contains("rank_window") {
            game.currentGameMode = .Ranked
        } else if line.match(UnloadingCard) {
            let match = line.matches(UnloadingCard)
            if let match = match.first {
                let cardId = match.value

                if game.currentMode == Mode.DRAFT && game.previousMode == Mode.HUB {
                    DDLogInfo("Possible arena card draft : \(cardId) ?")
                } else if (game.currentMode == Mode.COLLECTIONMANAGER || game.currentMode == Mode.TAVERN_BRAWL) && game.previousMode == Mode.HUB {
                    DDLogInfo("Possible constructed card draft : \(cardId) ?")
                }
            }
        } else if line.contains("unloading name=Tavern_Brawl") {
            game.currentGameMode = .Brawl
        }
    }
}
