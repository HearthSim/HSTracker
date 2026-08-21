//
//  BattlegroundsInspirationGameViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

// One first-place lineup in the Inspiration panel - HDT's
// BattlegroundsInspirationGameViewModel. Holds the hero portrait (downloaded),
// the starting hero power and the final board.
//
// An ObservableObject rather than a plain struct because the portrait arrives
// asynchronously and only that one row should redraw when it does.
@available(macOS 10.15, *)
final class BattlegroundsInspirationGameViewModel: ObservableObject, Identifiable {
    // Board minion with the stats and keywords the API reported, rather than
    // the card's own printed values - a first-place board is full of buffed
    // minions, and HDT likewise renders straight from the response.
    struct BoardMinion: Identifiable {
        let id = UUID()
        let card: Card
        let attack: Int
        let health: Int
        let isPremium: Bool
        let hasDivineShield: Bool
        let hasTaunt: Bool
        let hasVenomous: Bool
        let hasPoisonous: Bool
        let hasReborn: Bool
        let hasDeathrattle: Bool
        // HDT decodes Windfury but drops it: "Not supported by BattlegroundsMinion".
        // HSTracker's minion art has no windfury layer either, so it goes the
        // same way.
    }

    let id = UUID()

    @Published private(set) var heroImage: NSImage?

    let heroCard: Card?
    let heroPowerCard: Card?
    // HDT sets IsCoinCost on the hero power and passes `HideCost ? null : Cost`.
    let heroPowerCost: Int?
    let board: [BoardMinion]

    init(_ lineup: BattlegroundsInspiration.Lineup) {
        // GetBattlegroundsHeroFromDbf: a skin resolves to its parent hero, so
        // every lineup of the same hero shows the same portrait.
        var hero = Cards.by(dbfId: lineup.hero_dbf_id, collectible: false)
        if let skinParent = hero?.battlegroundsSkinParentId, skinParent > 0 {
            hero = Cards.by(dbfId: skinParent, collectible: false) ?? hero
        }
        heroCard = hero

        let heroPower = Cards.by(dbfId: lineup.starting_hero_power, collectible: false)
        heroPowerCard = heroPower
        heroPowerCost = (heroPower?.hideCost ?? true) ? nil : heroPower?.cost

        board = lineup.final_lineup
            // `x.ZonePosition is long` in HDT: entries without a numeric zone
            // position never reached the final board.
            .filter { $0.zone_position != nil }
            .compactMap { minion in
                guard let card = Cards.by(dbfId: minion.minion_dbf_id, collectible: false) else { return nil }
                return BoardMinion(
                    card: card,
                    attack: minion.attack,
                    health: minion.health,
                    isPremium: minion.premium,
                    hasDivineShield: minion.divine_shield,
                    hasTaunt: minion.taunt,
                    hasVenomous: minion.venemous,
                    hasPoisonous: minion.poison,
                    hasReborn: minion.reborn,
                    hasDeathrattle: minion.deathrattle
                )
            }

        loadHeroImage()
    }

    private func loadHeroImage() {
        guard let heroId = heroCard?.id else { return }
        if let cached = ImageUtils.cachedHero(cardId: heroId) {
            heroImage = cached
            return
        }
        ImageUtils.hero(for: heroId) { [weak self] image in
            DispatchQueue.main.async { self?.heroImage = image }
        }
    }
}
