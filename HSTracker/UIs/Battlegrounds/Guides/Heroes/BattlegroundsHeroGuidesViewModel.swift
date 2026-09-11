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
// The state HDT hangs off GuidesTooltipTrigger's CardGridTooltipViewModel: where
// Hearthstone is drawing the hovered hero's tooltip, and which cards are in it.
@available(macOS 10.15, *)
struct BattlegroundsHeroGuideTrigger: Equatable {
    let zonePosition: Int
    let tooltipOnRight: Bool
    let tooltipCards: [String]
    let buddiesEnabled: Bool
}

@available(macOS 10.15, *)
final class BattlegroundsHeroGuidesViewModel: ObservableObject {
    @Published var heroGuides: [Int: BattlegroundsHeroGuide]?
    @Published var selectedHero: BattlegroundsHeroGuideViewModel?

    // Non-nil only while the game has a hero picking tooltip up - see
    // BattlegroundsHeroGuideTriggerView, which draws over it.
    @Published var trigger: BattlegroundsHeroGuideTrigger?

    // HDT's OverlayWindow.SetHeroGuidesTrigger, minus the placement, which the
    // view works out for itself. Its own gate: HDT is only confident about the
    // layout when the zone holds exactly the four offered heroes.
    //
    // Main thread only, as the @Published write demands - the watcher reaches it
    // through Game.onMainOverlay.
    func setTrigger(zoneSize: Int, zonePosition: Int, tooltipOnRight: Bool, cards: [String],
                    buddiesEnabled: Bool) {
        guard zoneSize == 4, !cards.isEmpty else {
            trigger = nil
            return
        }
        trigger = BattlegroundsHeroGuideTrigger(zonePosition: zonePosition,
                                                tooltipOnRight: tooltipOnRight,
                                                tooltipCards: cards,
                                                buddiesEnabled: buddiesEnabled)
    }

    // HDT's HeroGuideTooltip.Update: the tooltip carries the offered hero's
    // hero power, and the guide is keyed by the hero that hero power belongs to
    // (GameTag.BACON_HEROPOWER_BASE_HERO_ID).
    func guide(heroPowerCardId: String) -> BattlegroundsHeroGuideViewModel? {
        guard let heroPower = Cards.by(cardId: heroPowerCardId) else { return nil }
        let heroDbfId = heroPower.baconHeroPowerBaseHeroId
        guard heroDbfId != 0 else { return nil }
        return guide(dbfId: heroDbfId)
    }

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
    // The guide for one offered hero, for the tooltip the hero picker raises -
    // HDT's BattlegroundsHeroGuideListViewModel.GetHeroGuide, which is likewise
    // keyed by the base hero rather than the skin that was offered.
    func guide(dbfId: Int) -> BattlegroundsHeroGuideViewModel? {
        guard let baseHero = Cards.getBattlegroundsHeroFromDbfid(dbfId: dbfId) else {
            return nil
        }
        return BattlegroundsHeroGuideViewModel(heroCard: baseHero, heroGuide: heroGuides?[baseHero.dbfId])
    }

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
