//
//  BattlegroundsMinionsViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// Mirrors HDT's BattlegroundsMinionsViewModel: drives the Minions tab that
// replaced the AppKit BattlegroundsTierDetailsView + BattlegroundsTierDetailWindowController.
// Filter state is activeTier (show a tier's cards grouped by tribe) XOR
// activeTribe (show a tribe's cards grouped by tier), matching the two modes
// of BattlegroundsTierDetailsView.groups exactly.
@available(macOS 10.15, *)
final class BattlegroundsMinionsViewModel: ObservableObject {
    struct MinionGroup: Identifiable {
        var id: String { "\(tier)-\(minionType)" }
        let tier: Int
        let minionType: Int      // Race.lookup result, or -1 for spells
        let raceName: String
        let groupedByMinionType: Bool  // true when in tribe mode (groups by tier)
        let cards: [Card]
    }

    @Published var activeTier: Int?
    @Published var activeTribe: Race?
    @Published var availableTiers: [Int] = BattlegroundsUtils.getAvailableTiers(anomalyCardId: nil)

    private var availableRaces: [Race]?
    private var isDuos = false
    private var anomaly: String?
    private var settingsCancellable: AnyCancellable?

    // Both coreManager and tierOverlay are implicitly-unwrapped: coreManager
    // isn't assigned until AppDelegate.completeSetup(), and tierOverlay is an
    // @IBOutlet that stays nil until BattlegroundsTierOverlay's nib is loaded
    // (which only happens once that window is first shown). Since the
    // UserDefaults subscription below can fire this from any settings write
    // anywhere in the app, force-unwrapping the chain would crash whenever a
    // setting changed before those were realized - so chain optionally and
    // default to "don't force tier 7 on".
    private var showTier7: Bool {
        AppDelegate.instance().coreManager?.game.windowManager
            .battlegroundsTierOverlay.tierOverlay?.showTavernTier7 ?? false
    }

    init() {
        settingsCancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshAvailableTiers() }
    }

    private func refreshAvailableTiers() {
        var tiers = BattlegroundsUtils.getAvailableTiers(anomalyCardId: anomaly)
        if (Settings.alwaysShowTier7 || showTier7) && !tiers.contains(7) {
            tiers.append(7)
        }
        availableTiers = tiers
    }

    var unavailableRaces: [Race] {
        guard let available = availableRaces else { return [] }
        return BattlegroundsDbSingleton.instance.races.filter {
            !available.contains($0) && $0 != .invalid && $0 != .all
        }
    }

    var groups: [MinionGroup] {
        if let tier = activeTier {
            return groupsByTribe(tier: tier)
        }
        if let tribe = activeTribe {
            return groupsByTier(tribe: tribe)
        }
        return []
    }

    // MARK: - Lifecycle

    func onMatchStart() {
        let game = AppDelegate.instance().coreManager.game
        availableRaces = game.availableRaces
        isDuos = game.isBattlegroundsDuosMatch()
        let anomalyDbfId = BattlegroundsUtils.getBattlegroundsAnomalyDbfId(game: game.gameEntity)
        anomaly = Cards.by(dbfId: anomalyDbfId, collectible: false)?.id
        activeTier = nil
        activeTribe = nil
        refreshAvailableTiers()
    }

    func onMatchEnd() {
        activeTier = nil
        activeTribe = nil
        availableRaces = nil
    }

    // MARK: - Filter actions

    func selectTier(_ tier: Int) {
        activeTier = activeTier == tier ? nil : tier
        activeTribe = nil
    }

    func selectTribe(_ race: Race) {
        activeTribe = activeTribe == race ? nil : race
        activeTier = nil
    }

    // MARK: - Group computation (mirrors BattlegroundsTierDetailsView.groups)

    private func groupsByTribe(tier: Int) -> [MinionGroup] {
        var result = [MinionGroup]()
        for race in BattlegroundsDbSingleton.instance.races {
            if let ar = availableRaces, !ar.contains(race) && race != .invalid && race != .all {
                continue
            }
            let cards = BattlegroundsDbSingleton.instance.getCards(tier, race, isDuos)
            guard !cards.isEmpty else { continue }
            result.append(MinionGroup(
                tier: tier,
                minionType: Race.lookup(race),
                raceName: String.localizedString("\(race)", comment: ""),
                groupedByMinionType: false,
                cards: cards.sorted { $0.name < $1.name }
            ))
        }
        if Settings.showTavernSpells {
            let spells = BattlegroundsDbSingleton.instance.getSpells(tier, isDuos)
                .sorted { a, b in a.cost == b.cost ? a.name < b.name : a.cost < b.cost }
            if !spells.isEmpty {
                result.append(MinionGroup(tier: tier, minionType: -1, raceName: "",
                                          groupedByMinionType: false, cards: spells))
            }
        }
        return result.sorted { a, b in
            let sa = sortKey(a.minionType)
            let sb = sortKey(b.minionType)
            return sa == sb ? a.raceName < b.raceName : sa < sb
        }
    }

    private func groupsByTier(tribe: Race) -> [MinionGroup] {
        var tiers = availableTiers
        if showTier7 { tiers.append(7) }
        let minionType = Race.lookup(tribe)
        let raceName = String.localizedString("\(tribe)", comment: "")
        var result = [MinionGroup]()
        for tier in tiers {
            let cards: [Card]
            if minionType == -1 {
                cards = BattlegroundsDbSingleton.instance.getSpells(tier, isDuos).sorted { $0.name < $1.name }
            } else {
                let main = BattlegroundsDbSingleton.instance.getCards(tier, tribe, isDuos)
                let extra = (tribe != .all && tribe != .invalid)
                    ? BattlegroundsDbSingleton.instance.getCards(tier, .all, isDuos)
                    : []
                cards = (main + extra).sorted { $0.name < $1.name }
            }
            guard !cards.isEmpty else { continue }
            result.append(MinionGroup(tier: tier, minionType: minionType, raceName: raceName,
                                      groupedByMinionType: true, cards: cards))
        }
        return result
    }

    private func sortKey(_ minionType: Int) -> Int {
        switch minionType {
        case Race.lookup(.all): return -1
        case Race.lookup(.invalid): return 1
        case -1: return 2
        default: return 0
        }
    }
}
