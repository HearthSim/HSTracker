//
//  ArenaPickOptionViewModels.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

/// Palette shared by the three option types.
///
/// HDT uses a deliberately different red for cards and for hero stats - the card
/// icons are more solid than the hero text below them, so they need the darker
/// one. Keeping both here, named, so the difference doesn't read as a mistake.
@available(macOS 10.15, *)
enum ArenaOptionPalette {
    static let normalBorder = Color(hex: "#067F93")
    static let undergroundBorder = Color(hex: "#932020")
    static let normalForeground = Color(hex: "#168Fa3")
    static let cardUndergroundForeground = Color(hex: "#C72E2E")
    static let heroUndergroundForeground = Color(hex: "#DC4343")

    static func border(isUnderground: Bool) -> Color {
        isUnderground ? undergroundBorder : normalBorder
    }
}

// MARK: - card option

@available(macOS 10.15, *)
final class ArenaPickSingleCardOptionViewModel: ObservableObject {
    let cardId: String
    let card: Card?
    let cardStats: ArenaCardPickApiResponse.CardStatsEntry?
    let isUnderground: Bool
    let plaqueViewModel: ArenaPlaqueViewModel

    /// Cards already drafted, used to weight the synergy count.
    @Published var pickedDeck: [String]?
    @Published var highlightImprovements = false

    /// Loading state - the plate is drawn empty while the request is in flight.
    init(cardId: String, isUnderground: Bool) {
        self.cardId = cardId
        self.card = Cards.by(cardId: cardId)
        self.cardStats = nil
        self.isUnderground = isUnderground
        self.plaqueViewModel = ArenaPlaqueViewModel(score: "", level: 0,
                                                    randomSeed: cardId.hashValue,
                                                    isUnderground: isUnderground)
    }

    init(cardId: String,
         data: ArenaCardPickApiResponse.CardStatsEntry,
         pickedDeck: [String]?,
         isUnderground: Bool,
         // Retained for parity with HDT's constructor even though nothing reads
         // it here: HDT uses it to tag a missing-score telemetry event, which
         // this port deliberately does not send.
         apiError: Bool = false) {
        self.cardId = cardId
        self.card = Cards.by(cardId: cardId)
        self.cardStats = data
        self.pickedDeck = pickedDeck
        self.isUnderground = isUnderground

        // The dynamic score wins when present - it is the one adjusted for what is
        // already in the deck.
        var score = "-"
        if let dyn = data.arenasmith_dyn?.score {
            score = Self.formatScore(dyn)
        } else if let base = data.arenasmith?.score {
            score = Self.formatScore(base)
        }

        let level = data.arenasmith_dyn?.plaque ?? data.arenasmith?.plaque ?? 0

        self.plaqueViewModel = ArenaPlaqueViewModel(score: score, level: level,
                                                    randomSeed: cardId.hashValue,
                                                    isUnderground: isUnderground)
    }

    /// "8.0" reads as "8", but "8.5" keeps its decimal; a score of 10 or more drops
    /// the decimal entirely so it still fits the plate.
    private static func formatScore(_ score: String?) -> String {
        guard let score, !score.trimmingCharacters(in: .whitespaces).isEmpty else { return "-" }
        let parts = score.split(separator: ".")
        guard let intPart = parts.first, let intValue = Int(intPart) else { return "-" }
        let decimalPart = parts.count > 1 ? String(parts[parts.count - 1]) : "0"
        return intValue >= 10 || decimalPart == "0" ? String(intPart) : score
    }

    var isMultiTribe: Bool { (card?.races.count ?? 0) > 1 }

    var badgeBorderColor: Color { ArenaOptionPalette.border(isUnderground: isUnderground) }
    var badgeForegroundColor: Color {
        isUnderground ? ArenaOptionPalette.cardUndergroundForeground : ArenaOptionPalette.normalForeground
    }

    var hasRelatedCards: Bool {
        !(cardStats?.related_cards?.generated_card_ids?.generated?.isEmpty ?? true)
    }

    /// Cards already in the deck that this card would turn on.
    var enabledCardsIds: [String] { cardStats?.related_cards?.card_ids_enabled?.all ?? [] }

    /// Cards already in the deck that would make this card better.
    var enhancedByCardsIds: [String] { cardStats?.related_cards?.enhanced_by_card_ids?.all ?? [] }

    var showSynergy: Bool { synergyCount > 0 }

    var synergyCount: Int {
        let enabled = enabledCardsIds
        // Enabled cards count once; enhancers count once per copy in the deck.
        return enabled.count + enhancedByCardsIds
            .filter { !enabled.contains($0) }
            .reduce(0) { total, id in total + (pickedDeck?.filter { $0 == id }.count ?? 0) }
    }

    /// Advisory lines worth an icon on the card itself, as opposed to the ones that
    /// only appear in the bottom panel.
    var hasInfo: Bool {
        guard let messages = cardStats?.messages else { return false }
        return messages.contains { message in
            switch message.type {
            case .lowSynergy, .highlander, .softHighlander, .highlanderChances, .questHelps, .veryRare:
                return true
            default:
                return false
            }
        }
    }

    // The `caution` field on the dynamic score picks one of two warning icons in
    // HDT, but its `GetIcon()` is private, uncalled and carries a "@todo: add this
    // back" - so no badge is drawn from it here either.
}

// MARK: - hero options

/// Backs all three hero-side option types. HDT has three near-identical view
/// models (`ArenaPickSingleHeroOptionViewModel`,
/// `...HeroPowerOptionViewModel`, `...DualClassHeroOptionViewModel`) that differ
/// only in the control they are bound to, so the variant is a field here.
@available(macOS 10.15, *)
final class ArenaPickSingleHeroOptionViewModel: ObservableObject {
    enum Variant {
        case hero
        case heroPower
        case dualClassHero
    }

    private static let tiers = ["A", "B", "C", "D"]

    let data: ArenaHeroPickApiResponse.ResponseData?
    let isUnderground: Bool
    let variant: Variant
    let index: Int
    let hasStats: Bool
    let winrate: Double
    let pickrate: Double
    let plaqueViewModel: ArenaPlaqueViewModel

    init(data: ArenaHeroPickApiResponse.ResponseData?, isUnderground: Bool, variant: Variant, index: Int) {
        self.data = data
        self.isUnderground = isUnderground
        self.variant = variant
        self.index = index
        self.hasStats = data != nil
        self.winrate = Double(data?.win_rate ?? 0)
        self.pickrate = Double(data?.pick_rate ?? 0)

        let tier = data?.tier?.uppercased() ?? "-"
        // A -> 5, B -> 4, C -> 3, D -> 2. Matching HDT exactly, including its
        // quirk: List.IndexOf returns -1 for an unrecognized tier, so 5 - (-1)
        // clamps to 5 and a missing tier draws the *most* ornate plate. Worth
        // checking against the real client before changing.
        let tierIndex = Self.tiers.firstIndex(of: tier) ?? -1
        let plaqueLevel = max(1, min(5, 5 - tierIndex))
        self.plaqueViewModel = ArenaPlaqueViewModel(score: tier, level: plaqueLevel,
                                                    randomSeed: data?.deck_class ?? 0,
                                                    isUnderground: isUnderground)
    }

    /// Loading state.
    convenience init(isUnderground: Bool, variant: Variant, index: Int) {
        self.init(data: nil, isUnderground: isUnderground, variant: variant, index: index)
    }

    // HDT gives each variant its own offsets: ArenaPickSingleHeroOption.xaml has
    // them as literal margins, while the hero-power and dual-class controls bind
    // Margin from their own view models. The port previously used the hero values
    // for all three, which put the hero-power and dual-class plates far too high.
    //
    // The `.hero` values are the one case measured against the live client rather
    // than taken from HDT (which has 230 / 533). Measuring the overlay window and
    // the game side by side puts the hero portrait at reference y 188.3-430.3, so
    // HDT's 230 dropped the plaque wholly inside the portrait and its 533 pushed
    // the badges down onto the hero-name row. 159 centres the 58-tall plaque on
    // the portrait's top edge, and 435 sits just under its bottom. Hero power and
    // dual class keep HDT's numbers - those screens have not been measured.
    var plaqueTop: CGFloat {
        switch variant {
        case .hero: return 159
        case .heroPower: return 560
        case .dualClassHero: return hasStats ? 170 : 560
        }
    }

    var statsTop: CGFloat {
        switch variant {
        case .hero: return 435
        case .heroPower: return 630
        case .dualClassHero: return hasStats ? 428 : 630
        }
    }

    /// HDT pulls the outer two options inward on the hero-power and dual-class
    /// screens (its `HorizontalMargin`), leaving the middle one alone.
    private var horizontalInset: CGFloat {
        switch variant {
        case .hero: return 0
        case .heroPower: return 47
        case .dualClassHero: return 55
        }
    }

    var leadingInset: CGFloat { index == 2 ? horizontalInset : 0 }
    var trailingInset: CGFloat { index == 0 ? horizontalInset : 0 }

    var badgeBorderColor: Color { ArenaOptionPalette.border(isUnderground: isUnderground) }
    var badgeForegroundColor: Color {
        isUnderground ? ArenaOptionPalette.heroUndergroundForeground : ArenaOptionPalette.normalForeground
    }

    /// Cards that define the class's winning decks, shown in the bottom panel.
    ///
    /// The API sends these as a JSON object keyed by card id, already in
    /// descending score order - its own header reads "Highest Impact Cards". HDT
    /// takes `Dictionary.Keys` and gets that order back, because C# happens to
    /// enumerate a freshly deserialized dictionary in insertion order. Swift's
    /// Dictionary gives no such guarantee, and its per-process hash seed
    /// reshuffles the list on every launch.
    ///
    /// The order cannot simply be preserved instead: checked against a live
    /// response, JSONDecoder's `allKeys` is hash-ordered too, so it is gone
    /// before any of our code sees it. Sorting by the score reproduces the
    /// server's list exactly, bar ties, which fall back to the card id so the
    /// order is at least the same every launch.
    var classDeckSignatureCardIds: [String] {
        guard let entries = data?.class_deck_signature?.data else { return [] }
        // "Arenasmith" and "12+ PPC" are different scales - live responses carry
        // the score in 12+ PPC with Arenasmith null throughout - so the field is
        // chosen once for the whole list rather than per entry.
        let useArenasmith = entries.values.contains { $0.arenasmith != nil }
        func score(_ entry: DeckSignatureEntry) -> Double {
            (useArenasmith ? entry.arenasmith : entry.ppc) ?? -.greatestFiniteMagnitude
        }
        return entries.sorted { lhs, rhs in
            let left = score(lhs.value), right = score(rhs.value)
            return left == right ? lhs.key < rhs.key : left > right
        }.map { $0.key }
    }
}
