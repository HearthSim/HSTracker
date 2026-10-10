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
struct BattlegroundsHeroGuideTrigger: Equatable {
    let zonePosition: Int
    let tooltipOnRight: Bool
    let tooltipCards: [String]
    let buddiesEnabled: Bool
}

final class BattlegroundsHeroGuidesViewModel: ObservableObject {
    @Published var heroGuides: [Int: BattlegroundsHeroGuide]?
    // The picked hero's guide, followed by the guides of the heroes the current
    // hero powers come from (e.g. after Sir Finley's choice).
    @Published var heroes: [BattlegroundsHeroGuideViewModel]?

    var isHeroSelected: Bool {
        return !(heroes?.isEmpty ?? true)
    }

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
    //
    // Looked up with any(byId:) rather than by(cardId:), which is the unfiltered
    // lookup HDT's HearthDb.Cards.GetFromDbfId is: by(cardId:) drops hero powers
    // outright, so it can never resolve the one card this is handed.
    func guide(heroPowerCardId: String) -> BattlegroundsHeroGuideViewModel? {
        guard let heroPower = Cards.any(byId: heroPowerCardId) else { return nil }
        let heroDbfId = heroPower.baconHeroPowerBaseHeroId
        guard heroDbfId != 0 else { return nil }
        return guide(dbfId: heroDbfId)
    }

    private var pickedHeroDbfId: Int?

    func update() async {
        guard heroGuides == nil else { return }

        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"
        guard let data = await HSReplayAPI.getHeroGuides(gameLanguage: gameLanguage) else { return }

        await MainActor.run {
            self.heroGuides = Dictionary(uniqueKeysWithValues: data.map { ($0.hero, $0) })
            self.updateHeroes()
        }
    }

    func selectHero(dbfId: Int?) {
        pickedHeroDbfId = dbfId
        updateHeroes()
    }

    private var heroPowerDbfIds = [Int]()

    // these guides are only about choosing a hero power, so the chosen hero's guide replaces them
    private static let replaceableHeroes: Set<String> = [
        CardIds.NonCollectible.Neutral.SirFinleyMrrggltonTavernBrawl1,
        CardIds.NonCollectible.Neutral.GennWorgenKing
    ]

    // Main thread only, as the @Published write demands.
    func onHeroPowers(_ heroPowers: [Entity]) {
        heroPowerDbfIds = heroPowers
            .sorted { $0[.additional_hero_power_index] < $1[.additional_hero_power_index] }
            .map { $0.card.dbfId }
        updateHeroes()
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
        heroes = nil
        pickedHeroDbfId = nil
        heroPowerDbfIds = []
    }

    func reset() {
        heroGuides = nil
        heroes = nil
        pickedHeroDbfId = nil
        heroPowerDbfIds = []
    }

    private func updateHeroes() {
        // The hero id can be a skin, so this resolves the base hero.
        guard let dbfId = pickedHeroDbfId, let pickedHero = Cards.getBattlegroundsHeroFromDbfid(dbfId: dbfId) else {
            return
        }

        // some heroes' own hero power points at another hero (e.g. Genn's points at Sir Finley)
        let ownHeroPower = pickedHero.heroPowerDbfId
        var heroDbfIds = [Int]()
        for heroDbfId in [pickedHero.dbfId] + heroPowerDbfIds.map({ heroPower in
            heroPower == ownHeroPower
                ? pickedHero.dbfId
                : Cards.by(dbfId: heroPower, collectible: false)?.baconHeroPowerBaseHeroId ?? 0
        }) where heroDbfId > 0 && !heroDbfIds.contains(heroDbfId) {
            heroDbfIds.append(heroDbfId)
        }

        if heroDbfIds.count > 1 && Self.replaceableHeroes.contains(pickedHero.id) {
            heroDbfIds.removeFirst()
        }

        heroes = heroDbfIds
            .compactMap { dbfId in Cards.by(dbfId: dbfId, collectible: false) }
            .map { card in BattlegroundsHeroGuideViewModel(heroCard: card, heroGuide: heroGuides?[card.dbfId]) }
    }
}
