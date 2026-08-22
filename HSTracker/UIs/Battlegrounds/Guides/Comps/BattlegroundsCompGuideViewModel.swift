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
// Not ported yet: ShowExampleBoardsCommand (needs Inspiration).
@available(macOS 10.15, *)
struct BattlegroundsCompGuideViewModel: Identifiable {
    let compGuide: BattlegroundsCompGuide
    var id: String { compGuide.name }

    // Kept as a nested name so every existing call site still reads
    // BattlegroundsCompGuideViewModel.GuideMinion; the type itself now lives
    // with the view that draws it, since the Inspiration panel builds them too.
    typealias GuideMinion = BattlegroundsMinionArt

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

    // HDT's TierText. Lives on the view model rather than in each view because
    // three of them render it now: the comp list row, the comp detail header,
    // and the Tavern Pinning key-piece tooltip.
    var tierText: String { Self.tierText(tier) }

    // The list's tier group headers label a bare tier number rather than a
    // comp, hence the static form.
    static func tierText(_ tier: Int) -> String {
        switch tier {
        case 1: return "S"
        case 2: return "A"
        case 3: return "B"
        case 4: return "C"
        case 5: return "D"
        default: return "?"
        }
    }

    // MARK: - Pinning (HDT's PinAllCompCardsCommand / AreAllCompCardsPinned)

    // Every card this guide names, in HDT's own order: core cards, add-ons,
    // "when to commit", "common enablers", "how to play" - de-duplicated, and
    // restricted to cards this lobby can actually offer.
    //
    // One flat list, rather than HDT's five separately-evaluated categories,
    // because the two halves of its own feature disagree in two ways:
    //
    //  1. PinAllCompCardsCommand filters *every* source by lobby availability;
    //     AreAllCompCardsPinned filters the two dbfId lists (AreAllDbfIdsPinned)
    //     but not the three inline ones (AreAllInlinePinned). So a guide naming
    //     an out-of-lobby card in its prose can never read as fully pinned -
    //     PinAll refuses to pin that card, and the check keeps demanding it.
    //
    //  2. AreAllCompCardsPinned ANDs its five per-category results, and each
    //     returns false both for "not all pinned" and for "this category had no
    //     cards at all" (its local `any` flag). A guide with no add-ons, or with
    //     no card references in its how-to-play prose, is therefore never "all
    //     pinned" no matter what the user does.
    //
    // Deriving the check and the action from this single de-duplicated list
    // makes the button's own state round-trip by construction.
    var pinnableCardIds: [String] {
        let available = Self.availableCardIds()
        var ids: [String] = []
        var seen: Set<String> = []

        func add(dbfId: Int) {
            guard available.contains(dbfId) else { return }
            guard let card = Cards.by(dbfId: dbfId, collectible: false), !card.id.isEmpty else { return }
            guard seen.insert(card.id).inserted else { return }
            ids.append(card.id)
        }

        compGuide.core_cards.forEach { add(dbfId: $0) }
        compGuide.addon_cards.forEach { add(dbfId: $0) }
        for lines in [whenToCommitLines, commonEnablerLines, Self.howToPlayLines(howToPlay)] {
            for line in lines {
                for segment in line {
                    if case .card(_, let dbfId) = segment, let dbfId {
                        add(dbfId: dbfId)
                    }
                }
            }
        }
        return ids
    }

    // AreAllCompCardsPinned: false when the guide names nothing pinnable at all,
    // which is what keeps the button dark for a guide with no resolvable cards.
    func areAllCompCardsPinned(_ pinning: BattlegroundsMinionPinningViewModel) -> Bool {
        let ids = pinnableCardIds
        guard !ids.isEmpty else { return false }
        return ids.allSatisfy { pinning.isCardPinned($0) }
    }

    // The command itself is a toggle: all pinned already means unpin them all.
    func togglePinAllCompCards(_ pinning: BattlegroundsMinionPinningViewModel) {
        let ids = pinnableCardIds
        guard !ids.isEmpty else { return }

        if ids.allSatisfy({ pinning.isCardPinned($0) }) {
            ids.forEach { pinning.unpinCard($0) }
        } else {
            ids.forEach { pinning.pinCard($0) }
        }
    }

    // HDT keeps HowToPlay pre-parsed as inlines; here the raw string is stored
    // (the detail view parses it for display), so this parses it on demand.
    private static func howToPlayLines(_ raw: String) -> [[GuideTextSegment]] {
        GuideCardText.parse(raw)
    }

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

    // HDT's GetAvailableCardIds, which memoizes per view model instance
    // (_availableCardIds). Memoized per *lobby* here instead: this is now read
    // from `areAllCompCardsPinned` on every render of every comp row, and these
    // view models are structs rebuilt from the guide list, so a per-instance
    // cache would miss constantly.
    private static var cachedLobbyKey: String?
    private static var cachedLobbyCardIds: Set<Int> = []

    static func availableCardIds() -> Set<Int> {
        let game = AppDelegate.instance().coreManager.game
        let isDuos = game.isBattlegroundsDuosMatch()
        let key = "\(game.availableRaces?.map { $0.rawValue }.sorted() ?? [])-\(isDuos)"
        if key == cachedLobbyKey {
            return cachedLobbyCardIds
        }
        let ids = computeAvailableCardIds(game: game, isDuos: isDuos)
        cachedLobbyKey = key
        cachedLobbyCardIds = ids
        return ids
    }

    private static func computeAvailableCardIds(game: Game, isDuos: Bool) -> Set<Int> {
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
