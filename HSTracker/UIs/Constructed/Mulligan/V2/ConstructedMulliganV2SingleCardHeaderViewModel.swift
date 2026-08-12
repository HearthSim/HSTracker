//
//  ConstructedMulliganV2SingleCardHeaderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// One "if you end up keeping exactly this combination of other cards" scenario
// for a single offered card, as returned by the server (MulliganCard.justifications).
@available(macOS 10.15, *)
struct MulliganJustification {
    let cardDbfIds: [Int]
    // Resolved once at construction (Cards.by(dbfId:) does an uncached full-database
    // scan) rather than in calculateConfidence(), which runs on every ~16ms live-state
    // poll tick - re-resolving here was pegging the main thread at 100% CPU.
    let cardIds: [String]
    let confidence: Double

    init(cardDbfIds: [Int], confidence: Double) {
        self.cardDbfIds = cardDbfIds
        self.cardIds = cardDbfIds.compactMap { Cards.by(dbfId: $0)?.id }
        self.confidence = confidence
    }

    // Keys look like "[]", "[118222]", "[118222, 121064]".
    static func parseKey(_ key: String) -> [Int] {
        let trimmed = key.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if trimmed.isEmpty { return [] }
        return trimmed.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}

// Per-card live selection state HSTracker doesn't have a source for yet (needs a
// HearthMirror binding exposing hand zone position + keep/replace selection, which
// the current HearthMirror.framework doesn't expose beyond a single waiting-for-input
// bool). ConstructedMulliganV2SingleCardHeaderViewModel.updateState(_:) is the seam
// this plugs into once that binding exists; until then it's never called and every
// card shows its static baseline confidence (the "keep everything" justification).
@available(macOS 10.15, *)
struct MulliganLiveCardState {
    let zonePosition: Int
    let cardId: String
    let kept: Bool
    let mouseOverInPlay: Bool
}

@available(macOS 10.15, *)
struct MulliganLiveState {
    let waitingForUserInput: Bool
    let cards: [MulliganLiveCardState]
}

@available(macOS 10.15, *)
class ConstructedMulliganV2SingleCardHeaderViewModel: ObservableObject, Identifiable {
    let id: Int
    var position: Int { id }

    @Published var card: Card?
    @Published var cardStatus: OfferedCardStatus
    @Published var justifications: [MulliganJustification]
    @Published var tips: [MulliganTipViewModel]
    @Published var liveState: MulliganLiveState?
    @Published private(set) var confidence: Double?
    @Published private(set) var isKeepingAll = true
    private var contextualConfidence: Double?

    // Fires whenever `confidence` actually moves, so LinearGaugeView can play its
    // "value changed" flash. Plain Combine (onReceive) rather than .onChange since
    // .onChange needs macOS 11.
    let confidenceDidChange = PassthroughSubject<Void, Never>()

    private static let barWidth: Double = 212
    private static let markerWidth: Double = 10

    // Whether the current player is going first in this match - initiative
    // tips need this to pick the "going first" vs "on the coin" icon/copy,
    // since the API's this/other_init_keep_rate pair is always relative to
    // whichever initiative the player actually has, not labeled explicitly.
    private let isFirst: Bool

    init(position: Int, data: MulliganV2Data.MulliganCard, isFirst: Bool) {
        self.id = position
        self.isFirst = isFirst
        let card = Cards.by(dbfId: data.dbf_id)
        self.card = card
        self.cardStatus = data.card_status

        switch data.card_status {
        case .valid, .lowData, .validWithInvalidNeighbors, .lowDataWithInvalidNeighbors:
            self.justifications = data.justification.map { MulliganJustification(cardDbfIds: MulliganJustification.parseKey($0.key), confidence: $0.value) }
            self.tips = data.tips.map { MulliganTipViewModel(tip: $0, ownerCard: card, ownerDbfId: data.dbf_id, isFirst: isFirst) }
        default:
            self.justifications = []
            self.tips = []
        }

        recalculateConfidence()
    }

    var hasError: Bool {
        cardStatus == .unknownCard || cardStatus == .noData
    }

    var errorText: String {
        switch cardStatus {
        case .noData, .unknownCard:
            return String.localizedString("MulliganGV2_Error_InsufficientData", comment: "")
        default:
            return ""
        }
    }

    var hasWarning: Bool {
        cardStatus == .lowData || cardStatus == .validWithInvalidNeighbors || cardStatus == .lowDataWithInvalidNeighbors
    }

    var warningText: String {
        switch cardStatus {
        case .lowData, .lowDataWithInvalidNeighbors:
            return String.localizedString("MulliganGV2_Warning_LowData", comment: "")
        case .validWithInvalidNeighbors:
            return String.localizedString("MulliganGV2_Warning_LowDataCombination", comment: "")
        default:
            return ""
        }
    }

    // A card the player has actively marked to replace has no matching justification.
    var replaced: Bool {
        confidence == nil && !hasError
    }

    var hasTooltip: Bool {
        confidence != nil
    }

    func updateCard(_ data: MulliganV2Data.MulliganCard) {
        card = Cards.by(dbfId: data.dbf_id)
        cardStatus = data.card_status
        justifications = data.justification.map { MulliganJustification(cardDbfIds: MulliganJustification.parseKey($0.key), confidence: $0.value) }
        tips = data.tips.map { MulliganTipViewModel(tip: $0, ownerCard: card, ownerDbfId: data.dbf_id, isFirst: isFirst) }
        recalculateConfidence()
    }

    // Deferred seam - see the doc comment on MulliganLiveState above. Not called
    // by anything yet.
    func updateState(_ state: MulliganLiveState?) {
        liveState = state
        if state?.waitingForUserInput == true {
            recalculateConfidence()
        }
    }

    private func calculateConfidence() -> Double? {
        guard let last = justifications.last else { return nil }
        contextualConfidence = last.confidence

        guard let liveState, liveState.waitingForUserInput else {
            return last.confidence
        }

        isKeepingAll = liveState.cards.allSatisfy { $0.kept }

        var keptCards = liveState.cards.filter { $0.kept }
        guard let thisCardIndex = keptCards.firstIndex(where: { $0.zonePosition == position }) else {
            return nil
        }
        keptCards.remove(at: thisCardIndex)

        let keptCardCounts = Dictionary(grouping: keptCards, by: { $0.cardId }).mapValues { $0.count }

        return justifications.first { justification in
            let justificationCounts = Dictionary(grouping: justification.cardIds, by: { $0 }).mapValues { $0.count }
            return keptCardCounts.count == justificationCounts.count &&
                keptCardCounts.allSatisfy { justificationCounts[$0.key] == $0.value }
        }?.confidence
    }

    private func recalculateConfidence() {
        let previous = confidence
        confidence = calculateConfidence()
        if previous != confidence {
            confidenceDidChange.send()
        }
    }

    var tooltipTitle: String? {
        guard let confidence else { return nil }
        let pct = Int((confidence * 100).rounded())
        let key = isKeepingAll ? "MulliganGV2_ContextualKeepRate_Title" : "MulliganGV2_DynamicKeepRate_Title"
        return String(format: String.localizedString(key, comment: ""), pct)
    }

    var tooltipText: String? {
        guard let confidence, let contextualConfidence else { return nil }
        let pct = Int((confidence * 100).rounded())
        let contextualPct = Int((contextualConfidence * 100).rounded())
        let delta = pct - contextualPct

        if isKeepingAll {
            return String(format: String.localizedString("MulliganGV2_ContextualKeepRate_Description", comment: ""), card?.name ?? "", pct)
        } else if delta >= 0 {
            return String(format: String.localizedString("MulliganGV2_DynamicKeepRate_Positive_Description", comment: ""), card?.name ?? "", delta, contextualPct)
        } else {
            return String(format: String.localizedString("MulliganGV2_DynamicKeepRate_Negative_Description", comment: ""), card?.name ?? "", -delta, contextualPct)
        }
    }

    var leftBand: Double? {
        guard let lowest = justifications.map({ $0.confidence }).min() else { return nil }
        let pos = lowest * (Self.barWidth - Self.markerWidth)
        return max(0, min(pos, Self.barWidth - Self.markerWidth))
    }

    var rightBand: Double? {
        guard let highest = justifications.map({ $0.confidence }).max() else { return nil }
        let pos = highest * (Self.barWidth - Self.markerWidth)
        return max(0, min(pos, Self.barWidth - Self.markerWidth))
    }

    var bandsWidth: Double? {
        guard let leftBand, let rightBand else { return nil }
        return rightBand - leftBand
    }

    var currentHandPosition: Double? {
        guard let confidence else { return nil }
        let pos = confidence * (Self.barWidth - Self.markerWidth)
        return max(0, min(pos, Self.barWidth - Self.markerWidth))
    }

    var negativeColor: Color {
        Color(hex: Helper.getColorString(mode: .MULLIGAN_CONFIDENCE, delta: -10, intensity: 75))
    }

    var neutralColor: Color {
        Color(hex: Helper.getColorString(mode: .MULLIGAN_CONFIDENCE, delta: 0, intensity: 75))
    }

    var positiveColor: Color {
        Color(hex: Helper.getColorString(mode: .MULLIGAN_CONFIDENCE, delta: 10, intensity: 75))
    }
}

@available(macOS 10.15, *)
class MulliganTipViewModel: ObservableObject, Identifiable {
    let id = UUID()
    private(set) var tipCard: Card?
    private(set) var tipClassIcon: String?
    private(set) var tipInitiativeIcon: String?
    let arrowCount: Int
    let arrowsUp: Bool
    private(set) var tooltipTitle: String?
    private(set) var tooltipText: String?
    private(set) var baseKeepRateText: String?
    private(set) var adjustedKeepRateText: String?

    // The API's tip_enum values aren't documented, so which family a tip
    // belongs to is derived from which fields are present: dbf_id -> card
    // synergy tip, opponent_class -> opponent-class tip, this/other_init_keep_rate
    // -> initiative tip (going first/coin).
    init(tip: MulliganV2Data.MulliganTip, ownerCard: Card?, ownerDbfId: Int?, isFirst: Bool) {
        arrowsUp = tip.arrows > 0
        arrowCount = abs(tip.arrows)

        if let dbfId = tip.dbf_id, let card = Cards.by(dbfId: dbfId) {
            configureCardTip(dbfId: dbfId, card: card, tip: tip, ownerCard: ownerCard, ownerDbfId: ownerDbfId)
        } else if let opponentClassString = tip.opponent_class,
                  let opponentClass = CardClass(rawValue: opponentClassString.lowercased()),
                  let thisOpponentKeepRate = tip.this_opponent_keep_rate,
                  let otherOpponentKeepRate = tip.other_opponent_keep_rate {
            configureOpponentTip(opponentClass: opponentClass, thisOpponentKeepRate: thisOpponentKeepRate, otherOpponentKeepRate: otherOpponentKeepRate, ownerCard: ownerCard)
        } else if let thisInitKeepRate = tip.this_init_keep_rate, let otherInitKeepRate = tip.other_init_keep_rate {
            configureInitiativeTip(thisInitKeepRate: thisInitKeepRate, otherInitKeepRate: otherInitKeepRate, isFirst: isFirst, ownerCard: ownerCard)
        }
    }

    private func configureCardTip(dbfId: Int, card: Card, tip: MulliganV2Data.MulliganTip, ownerCard: Card?, ownerDbfId: Int?) {
        tipCard = card

        let baseKeepRate = Self.format(tip.base_keep_rate ?? 0)
        let adjustedKeepRate = Self.format(tip.adjusted_keep_rate ?? 0)
        let delta = adjustedKeepRate - baseKeepRate

        tooltipTitle = String(format: String.localizedString("MulliganGV2_IconTooltip_Title", comment: ""), delta > 0 ? "+" : "-", abs(delta))

        let isSecondCopy = ownerDbfId != nil && dbfId == ownerDbfId
        switch (isSecondCopy, arrowsUp) {
        case (false, false):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptLess", comment: ""), ownerCard?.name ?? "", abs(delta), card.name)
        case (false, true):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptMore", comment: ""), ownerCard?.name ?? "", abs(delta), card.name)
        case (true, false):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptLess_SecondCopy", comment: ""), ownerCard?.name ?? "", abs(delta))
        case (true, true):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptMore_SecondCopy", comment: ""), ownerCard?.name ?? "", abs(delta))
        }

        baseKeepRateText = String(format: String.localizedString("MulliganGV2_Tooltip_BaseKeepRate", comment: ""), baseKeepRate)
        adjustedKeepRateText = String(format: String.localizedString("MulliganGV2_Tooltip_AdjustedKeepRate", comment: ""), adjustedKeepRate)
    }

    private func configureOpponentTip(opponentClass: CardClass, thisOpponentKeepRate: Double, otherOpponentKeepRate: Double, ownerCard: Card?) {
        tipClassIcon = opponentClass.rawValue

        let baseKeepRate = Self.format(otherOpponentKeepRate)
        let adjustedKeepRate = Self.format(thisOpponentKeepRate)
        let delta = adjustedKeepRate - baseKeepRate
        let className = String.localizedString("\(opponentClass)", comment: "")

        tooltipTitle = String(format: String.localizedString("MulliganGV2_IconTooltip_Title_Opponent", comment: ""), delta > 0 ? "+" : "-", abs(delta))
        tooltipText = arrowsUp
            ? String(format: String.localizedString("MulliganGV2_IconTooltip_KeptMore_Opponent", comment: ""), ownerCard?.name ?? "", abs(delta), className)
            : String(format: String.localizedString("MulliganGV2_IconTooltip_KeptLess_Opponent", comment: ""), ownerCard?.name ?? "", abs(delta), className)

        baseKeepRateText = String(format: String.localizedString("MulliganGV2_Tooltip_OtherOpponentKeepRate", comment: ""), baseKeepRate)
        adjustedKeepRateText = String(format: String.localizedString("MulliganGV2_Tooltip_ThisOpponentKeepRate", comment: ""), className, adjustedKeepRate)
    }

    // "this"/"other" here are relative to the player's actual initiative in
    // the current match (same convention as the opponent-class tip's
    // this/other_opponent_keep_rate), not tagged with which is which - so
    // isFirst (from the live game state, already sent as player_initiative
    // in the request) is what tells us whether "this" means going first or
    // being on the coin.
    private func configureInitiativeTip(thisInitKeepRate: Double, otherInitKeepRate: Double, isFirst: Bool, ownerCard: Card?) {
        tipInitiativeIcon = isFirst ? "going_first" : "going_second"

        let baseKeepRate = Self.format(otherInitKeepRate)
        let adjustedKeepRate = Self.format(thisInitKeepRate)
        let delta = adjustedKeepRate - baseKeepRate

        tooltipTitle = String(format: String.localizedString("MulliganGV2_IconTooltip_Title_Initiative", comment: ""), delta > 0 ? "+" : "-", abs(delta))
        switch (isFirst, arrowsUp) {
        case (true, false):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptLess_First", comment: ""), ownerCard?.name ?? "", abs(delta))
        case (true, true):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptMore_First", comment: ""), ownerCard?.name ?? "", abs(delta))
        case (false, false):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptLess_Coin", comment: ""), ownerCard?.name ?? "", abs(delta))
        case (false, true):
            tooltipText = String(format: String.localizedString("MulliganGV2_IconTooltip_KeptMore_Coin", comment: ""), ownerCard?.name ?? "", abs(delta))
        }

        let thisLabelKey = isFirst ? "MulliganGV2_Tooltip_GoingFirstKeepRate" : "MulliganGV2_Tooltip_GoingSecondKeepRate"
        let otherLabelKey = isFirst ? "MulliganGV2_Tooltip_GoingSecondKeepRate" : "MulliganGV2_Tooltip_GoingFirstKeepRate"
        baseKeepRateText = String(format: String.localizedString(otherLabelKey, comment: ""), baseKeepRate)
        adjustedKeepRateText = String(format: String.localizedString(thisLabelKey, comment: ""), adjustedKeepRate)
    }

    private static func format(_ value: Double) -> Int {
        Int((value * 100).rounded())
    }
}
