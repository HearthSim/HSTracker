//
//  BattlegroundsCompGuideViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsCompGuideViewModel. Tier/difficulty are kept as
// raw Int (not pre-formatted text) so the view can render them as literal
// Text("S")/Text("Hard") - lets Xcode's String Catalog auto-extraction handle
// localization instead of hand-maintaining catalog entries here.
//
// Not ported yet: AreAllCompCardsPinned/PinAllCompCardsCommand (need Minion
// Pinning) and ShowExampleBoardsCommand (needs Inspiration) - both are later
// milestones.
@available(macOS 10.15, *)
struct BattlegroundsCompGuideViewModel: Identifiable {
    let compGuide: BattlegroundsCompGuide
    var id: String { compGuide.name }

    struct GuideMinion: Identifiable {
        let id: Int // dbfId
        let card: Card
        let isAvailable: Bool
        let attack: Int
        let health: Int
        let tier: Int
        let hasTaunt: Bool
        let hasReborn: Bool
        let hasDeathrattle: Bool
        let hasPoisonous: Bool
        let hasVenomous: Bool
        let hasDivineShield: Bool
        let isLegendary: Bool

        init(dbfId: Int, card: Card, isAvailable: Bool) {
            self.id = dbfId
            self.card = card
            self.isAvailable = isAvailable
            self.attack = card.attack
            self.health = card.health
            self.tier = card.techLevel
            self.hasTaunt = card.mechanics.contains("TAUNT")
            self.hasReborn = card.mechanics.contains("REBORN")
            self.hasDeathrattle = card.mechanics.contains("DEATHRATTLE")
            self.hasPoisonous = card.mechanics.contains("POISONOUS")
            self.hasVenomous = card.mechanics.contains("VENOMOUS")
            self.hasDivineShield = card.mechanics.contains("DIVINE_SHIELD")
            self.isLegendary = card.rarity == .legendary
        }
    }

    let coreCards: [GuideMinion]
    let addonCards: [GuideMinion]
    let representativeCard: Card?
    let tier: Int
    let tierColors: [Color]
    let difficulty: Int
    let difficultyColor: Color
    let primaryTribe: Int
    let howToPlay: String
    let whenToCommitLines: [[GuideTextSegment]]
    let commonEnablerLines: [[GuideTextSegment]]
    let lastUpdatedText: String?

    // HDT's ExampleBoardsButtonEnabled - the button itself isn't wired up
    // until the Inspiration milestone, but the gating already matches.
    var exampleBoardsButtonEnabled: Bool { Self.isTier7Enabled }

    init(_ compGuide: BattlegroundsCompGuide) {
        self.compGuide = compGuide

        // HDT only filters core/addon cards down to the current lobby's
        // available pool when Tier7 is enabled - free-tier users always see
        // the full list, unfiltered.
        let checkAvailability = Self.isTier7Enabled
        let available = checkAvailability ? Self.availableCardIds() : nil

        func minions(_ dbfIds: [Int]) -> [GuideMinion] {
            dbfIds.compactMap { dbfId in
                guard let card = Cards.by(dbfId: dbfId, collectible: false) else { return nil }
                let isAvailable = available.map { $0.contains(dbfId) } ?? true
                return GuideMinion(dbfId: dbfId, card: card, isAvailable: isAvailable)
            }
        }

        coreCards = minions(compGuide.core_cards)
        addonCards = minions(compGuide.addon_cards)
        representativeCard = Cards.by(cardId: compGuide.representative_card)
        tier = compGuide.tier
        tierColors = Self.tierColors(compGuide.tier)
        difficulty = compGuide.difficulty
        difficultyColor = Self.difficultyColor(compGuide.difficulty)
        primaryTribe = compGuide.primary_tribe
        howToPlay = compGuide.how_to_play
        // One pill per line, matching HDT's ItemsControl over
        // WhenToCommitTags/CommonEnablerTags (an array of per-line inline
        // runs) - not a single flowing paragraph.
        whenToCommitLines = GuideCardText.parse(compGuide.when_to_commit)
        commonEnablerLines = GuideCardText.parse(compGuide.common_enablers)
        lastUpdatedText = Self.relativeDate(compGuide.last_updated)
    }

    // last_updated is decoded as a raw String (see BattlegroundsCompGuides.swift
    // for why), so this parses on demand rather than at decode time - the
    // sibling Arenasmith app confirmed the wire format is ISO8601 by
    // successfully decoding it that way against the live API. Tries with
    // fractional seconds first (its own sample payload carried microsecond
    // precision, e.g. "2025-12-13T03:25:14.280302Z", which the plain
    // .withInternetDateTime option can't parse) and falls back to without.
    private static func relativeDate(_ raw: String?) -> String? {
        guard let raw else { return nil }

        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let date = withFractional.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
        guard let date else { return nil }
        return RelativeDateTimeFormatter().localizedString(fromTimeInterval: date.timeIntervalSinceNow)
    }

    private static var isTier7Enabled: Bool {
        (HSReplayAPI.accountData?.is_tier7 ?? false) || Tier7Trial.token != nil
    }

    private static func availableCardIds() -> Set<Int> {
        let game = AppDelegate.instance().coreManager.game
        let isDuos = game.isBattlegroundsDuosMatch()
        var races = Set(game.availableRaces ?? [])
        races.insert(.all)
        races.insert(.invalid)
        let cards = BattlegroundsDbSingleton.instance.getCardsByRaces(Array(races), isDuos)
            + BattlegroundsDbSingleton.instance.getSpells(isDuos)
        return Set(cards.map { $0.dbfId })
    }

    private static func tierColors(_ tier: Int) -> [Color] {
        switch tier {
        case 1: return [Color(hex: "#408ABF"), Color(hex: "#385F7A")]
        case 2: return [Color(hex: "#6BA036"), Color(hex: "#587937")]
        case 3: return [Color(hex: "#92A036"), Color(hex: "#687937")]
        case 4: return [Color(hex: "#A07C36"), Color(hex: "#795F37")]
        case 5: return [Color(hex: "#A04836"), Color(hex: "#794237")]
        default: return [Color(hex: "#707070"), Color(hex: "#404040")]
        }
    }

    private static func difficultyColor(_ difficulty: Int) -> Color {
        switch difficulty {
        case 1: return Color(hex: "#7f303e")
        case 2: return Color(hex: "#917b43")
        case 3: return Color(hex: "#49634b")
        default: return Color(hex: "#404040")
        }
    }
}
