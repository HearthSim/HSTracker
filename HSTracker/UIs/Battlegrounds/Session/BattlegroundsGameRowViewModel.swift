//
//  BattlegroundsGameRowViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Port of HDT's BattlegroundsGameViewModel
// (Controls/Overlay/Battlegrounds/Session/BattlegroundsGameViewModel.cs), the
// data behind one row of the session's Latest Games list.
@available(macOS 10.15, *)
class BattlegroundsGameRowViewModel: ObservableObject, Identifiable, Equatable {
    static func == (lhs: BattlegroundsGameRowViewModel, rhs: BattlegroundsGameRowViewModel) -> Bool {
        return lhs === rhs
    }

    // a single game never swings the rating this far, so we hide implausible deltas instead of showing something wrong
    private static let maxPlausibleMMRDelta = 500

    // These are the languages where we'd prefer we show the localized hero name rather than our English-only short version
    private static var preferTranslatedCardName: Bool {
        switch Settings.hearthstoneLanguage?.rawValue {
        case "jaJP", "koKR", "thTH", "zhCN", "zhTW":
            return true
        default:
            return false
        }
    }

    let startTime: Date
    let placement: Int
    let heroName: String
    let heroCard: Card?
    let mmrDelta: Int
    let mmrDeltaText: String
    let showCrown: Bool
    let finalBoardMinions: [Entity]

    var id: Date { startTime }

    private let duos: Bool
    private let friendlyGame: Bool

    init(gameItem: BattlegroundsLastGames.GameItem) {
        startTime = gameItem.startTime
        placement = gameItem.placement
        duos = gameItem.duos ?? false
        friendlyGame = gameItem.friendlyGame ?? false

        var card = Cards.by(cardId: gameItem.hero)
        if let parentId = card?.battlegroundsSkinParentId, parentId > 0 {
            card = Cards.by(dbfId: parentId, collectible: false)
        }
        heroCard = card

        if Self.preferTranslatedCardName {
            // Some languages have short card names, so we'd rather use the language from the game than our English-only short version.
            heroName = card?.name ?? "-"
        } else {
            let heroShortNameMap = RemoteConfig.data?.battlegrounds_short_names?.first(where: { x in x.dbf_id == card?.dbfId })
            heroName = heroShortNameMap?.short_name ?? card?.name ?? "-"
        }

        mmrDelta = gameItem.ratingAfter - gameItem.rating
        let signal = mmrDelta > 0 ? "+" : ""
        let unknownDelta = abs(mmrDelta) > Self.maxPlausibleMMRDelta || friendlyGame
        mmrDeltaText = unknownDelta ? "-" : "\(signal)\(mmrDelta)"

        showCrown = gameItem.placement == 1

        finalBoardMinions = gameItem.finalBoard?.minions.map { minion in
            let entity = Entity()
            entity.cardId = minion.cardId
            for tag in minion.tags {
                if let gt = GameTag(rawValue: tag.tag) {
                    entity[gt] = tag.value
                }
            }
            return entity
        } ?? []
    }

    var placementText: String {
        String.localizedString("Battlegrounds_Game_Ordinal_\(placement)", comment: "")
    }

    var placementColor: Color {
        let win = duos ? placement <= 2 : placement <= 4
        return win ? BattlegroundsSessionColors.placementLow : BattlegroundsSessionColors.placementHigh
    }

    var mmrDeltaColor: Color {
        if mmrDelta == 0 || abs(mmrDelta) > Self.maxPlausibleMMRDelta || friendlyGame {
            return .white
        }
        return mmrDelta > 0 ? BattlegroundsSessionColors.mmrPositive : BattlegroundsSessionColors.mmrNegative
    }

    // HDT's FinalBoardEmptyLabelVisibility.
    var finalBoardIsEmpty: Bool { finalBoardMinions.isEmpty }
}
