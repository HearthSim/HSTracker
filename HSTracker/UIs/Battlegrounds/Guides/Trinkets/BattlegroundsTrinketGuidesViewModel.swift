//
//  BattlegroundsTrinketGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's BattlegroundsTrinketGuideListViewModel - tooltip-only, no
// selection state (unlike Comps/Heroes, there's no dedicated tab; a guide is
// looked up per-dbfId whenever a trinket card is hovered).
@available(macOS 10.15, *)
final class BattlegroundsTrinketGuidesViewModel: ObservableObject {
    @Published var trinketGuides: [Int: BattlegroundsTrinketGuide]?

    @available(macOS 10.15.0, *)
    func update() async {
        guard trinketGuides == nil else { return }

        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"
        guard let data = await HSReplayAPI.getTrinketGuides(gameLanguage: gameLanguage) else { return }

        await MainActor.run {
            self.trinketGuides = Dictionary(uniqueKeysWithValues: data.map { ($0.trinket, $0) })
        }
    }

    func guide(dbfId: Int) -> BattlegroundsTrinketGuide? {
        trinketGuides?[dbfId]
    }

    func reset() {
        trinketGuides = nil
    }
}
