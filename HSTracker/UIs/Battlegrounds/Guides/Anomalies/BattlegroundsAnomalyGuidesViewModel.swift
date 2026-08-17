//
//  BattlegroundsAnomalyGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's BattlegroundsAnomalyGuideListViewModel - tooltip-only, no
// tab, same shape as BattlegroundsTrinketGuidesViewModel.
@available(macOS 10.15, *)
final class BattlegroundsAnomalyGuidesViewModel: ObservableObject {
    @Published var anomalyGuides: [Int: BattlegroundsAnomalyGuide]?

    // Mirrors HDT's SetAnomalyGuidesTrigger(string cardId) - the card
    // currently reported as hovered by the game's own memory-read state
    // (Game.onBigCardChange), when it's the battleground anomaly badge.
    // AnomalyGuideBadgeTriggerView shows the tooltip whenever this is set.
    @Published private(set) var hoveredAnomalyCard: Card?

    @available(macOS 10.15.0, *)
    func update() async {
        guard anomalyGuides == nil else { return }

        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"
        guard let data = await HSReplayAPI.getAnomalyGuides(gameLanguage: gameLanguage) else { return }

        await MainActor.run {
            self.anomalyGuides = Dictionary(uniqueKeysWithValues: data.map { ($0.anomaly, $0) })
        }
    }

    func guide(dbfId: Int) -> BattlegroundsAnomalyGuide? {
        anomalyGuides?[dbfId]
    }

    func updateHoveredCard(cardId: String) {
        guard let card = Cards.by(cardId: cardId), card.type == .battleground_anomaly else {
            hoveredAnomalyCard = nil
            return
        }
        hoveredAnomalyCard = card
    }

    func reset() {
        anomalyGuides = nil
        hoveredAnomalyCard = nil
    }
}
