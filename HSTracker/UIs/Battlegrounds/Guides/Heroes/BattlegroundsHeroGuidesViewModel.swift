//
//  BattlegroundsHeroGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's BattlegroundsHeroGuideListViewModel. Fetch (update()) and
// hero-selection (selectHero(dbfId:)) are decoupled here rather than both
// reading a shared Game property like HDT's UpdateSelectedHero() does -
// Game.snapshotBattlegroundsHeroPick() already returns the picked dbfId
// directly at the one call site that finalizes it (handlePlayerMulliganDone),
// so there's no need to expose more of Game's internals just to re-read it.
@available(macOS 10.15, *)
final class BattlegroundsHeroGuidesViewModel: ObservableObject {
    @Published var heroGuides: [Int: BattlegroundsHeroGuide]?
    @Published var selectedHero: BattlegroundsHeroGuideViewModel?

    private var pickedHeroDbfId: Int?

    @available(macOS 10.15.0, *)
    func update() async {
        guard heroGuides == nil else { return }

        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"
        guard let data = await HSReplayAPI.getHeroGuides(gameLanguage: gameLanguage) else { return }

        await MainActor.run {
            self.heroGuides = Dictionary(uniqueKeysWithValues: data.map { ($0.hero, $0) })
            self.resolveSelectedHero()
        }
    }

    func selectHero(dbfId: Int?) {
        pickedHeroDbfId = dbfId
        resolveSelectedHero()
    }

    // Unlike reset(), the fetched guide dict isn't lobby-specific (favorable
    // tribes are filtered against the current lobby at display time in
    // BattlegroundsHeroGuideViewModel, not baked into the stored guide), so
    // there's no need to refetch it every match - only which hero is
    // currently selected needs clearing. Mirrors BattlegroundsCompsGuidesVM's
    // onMatchEnd()/reset() split.
    func onMatchEnd() {
        selectedHero = nil
        pickedHeroDbfId = nil
    }

    func reset() {
        heroGuides = nil
        selectedHero = nil
        pickedHeroDbfId = nil
    }

    private func resolveSelectedHero() {
        guard let dbfId = pickedHeroDbfId, let baseHero = Cards.getBattlegroundsHeroFromDbfid(dbfId: dbfId) else {
            selectedHero = nil
            return
        }
        let guide = heroGuides?[baseHero.dbfId]
        selectedHero = BattlegroundsHeroGuideViewModel(heroCard: baseHero, heroGuide: guide)
    }
}
