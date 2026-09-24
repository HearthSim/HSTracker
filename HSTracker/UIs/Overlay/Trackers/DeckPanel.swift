//
//  DeckPanel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// One orderable section of a deck tracker - HDT's `Enums/DeckPanel.cs`, which
/// drives `OverlayWindow.UpdatePlayerLayout` / `UpdateOpponentLayout`.
///
/// HDT's `Fatigue` case has no HSTracker counterpart because HSTracker shows it
/// in its counters overlay rather than in the stack.
///
/// `graveyard` is HSTracker's own: HDT has no graveyard counter in the stack.
///
/// The raw values are what `Settings.deckPanelOrderPlayer` /
/// `deckPanelOrderOpponent` persist, so they must not change.
enum DeckPanel: String, CaseIterable {
    case deckTitle = "deck_title"
    case wins
    /// HDT's opponent-class matchup record, e.g. "Vs Mage: 2-1 (67%)".
    /// This panel is opponent-only.
    case winrate
    case cardsTop = "cards_top"
    case cards
    case cardsBottom = "cards_bottom"
    case sideboards
    case cardCounter = "card_counter"
    case drawChances = "draw_chances"
    case graveyard

    /// HDT's `DeckPanelOrderLocalPlayer` default, with the graveyard counter -
    /// which HDT does not have - appended.
    static let defaultPlayerOrder: [DeckPanel] = [
        .deckTitle, .wins, .cardsTop, .cards, .cardsBottom, .sideboards, .cardCounter, .drawChances, .graveyard
    ]

    /// HDT's `DeckPanelOrderOpponent` default, with HSTracker's hero bar first
    /// and graveyard counter appended.
    static let defaultOpponentOrder: [DeckPanel] = [
        .deckTitle, .winrate, .cards, .cardCounter, .drawChances, .graveyard
    ]

    /// The sections that exist on a given side. The player's deck is the only one
    /// with a known order to its cards, so top/bottom/sideboards are player-only.
    /// HDT's win-rate panel is an opponent-class matchup, so it has no player-side
    /// counterpart.
    static func available(for playerType: PlayerType) -> [DeckPanel] {
        playerType == .opponent
            ? [.deckTitle, .winrate, .cards, .cardCounter, .drawChances, .graveyard]
            : allCases.filter { $0 != .winrate }
    }

    /// The saved order for a side, filtered down to the sections that side has and
    /// topped up with any that a saved order predates - so a section added in a
    /// later build appears rather than silently going missing.
    static func order(for playerType: PlayerType) -> [DeckPanel] {
        let raw = playerType == .opponent ? Settings.deckPanelOrderOpponent : Settings.deckPanelOrderPlayer
        let available = Set(self.available(for: playerType))
        var order = raw.compactMap { DeckPanel(rawValue: $0) }.filter { available.contains($0) }
        if playerType == .opponent, !order.contains(.winrate),
           let titleIndex = order.firstIndex(of: .deckTitle) {
            order.insert(.winrate, at: titleIndex + 1)
        }
        let missing = (playerType == .opponent ? defaultOpponentOrder : defaultPlayerOrder)
            .filter { available.contains($0) && !order.contains($0) }
        order.append(contentsOf: missing)
        return order
    }

    static func setOrder(_ order: [DeckPanel], for playerType: PlayerType) {
        if playerType == .opponent {
            Settings.deckPanelOrderOpponent = order.map { $0.rawValue }
        } else {
            Settings.deckPanelOrderPlayer = order.map { $0.rawValue }
        }
    }

    /// The label the reordering UI shows, using HDT's own `Enum_DeckPanel_*`
    /// strings where one exists.
    var localizedName: String {
        switch self {
        case .deckTitle: return String.localizedString("Enum_DeckPanel_DeckTitle", comment: "")
        case .wins: return String.localizedString("Enum_DeckPanel_Wins", comment: "")
        case .winrate: return String.localizedString("Enum_DeckPanel_Winrate", comment: "")
        case .cardsTop: return String.localizedString("Enum_DeckPanel_CardsTop", comment: "")
        case .cards: return String.localizedString("Enum_DeckPanel_Cards", comment: "")
        case .cardsBottom: return String.localizedString("Enum_DeckPanel_CardsBottom", comment: "")
        case .sideboards: return String.localizedString("Enum_DeckPanel_ETCBand", comment: "")
        case .cardCounter: return String.localizedString("Enum_DeckPanel_CardCounter", comment: "")
        case .drawChances: return String.localizedString("Enum_DeckPanel_DrawChances", comment: "")
        case .graveyard: return String.localizedString("Enum_DeckPanel_Graveyard", comment: "")
        }
    }
}
