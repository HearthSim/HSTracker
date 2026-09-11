//
//  BattlegroundsQuestGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's BattlegroundsQuestGuideListViewModel. selectedQuests grows
// across the match (multiple quest rewards can be picked, typically turn 1
// and turn 4) - never cleared mid-match, only at onMatchEnd()/reset().
// The state HDT hangs off DiscoveryGuidesTooltipTrigger's
// CardGridTooltipViewModel: which reward the game has a tooltip up for, and
// where.
@available(macOS 10.15, *)
struct BattlegroundsQuestGuideTrigger: Equatable {
    let rewardDbfId: Int
    let zonePosition: Int
    let tooltipOnRight: Bool
}

@available(macOS 10.15, *)
final class BattlegroundsQuestGuidesViewModel: ObservableObject {
    @Published var questGuides: [Int: BattlegroundsQuestGuide]?
    @Published var selectedQuests: [BattlegroundsQuestGuideViewModel] = []

    // Non-nil only while the game has a quest reward tooltip up - see
    // BattlegroundsQuestGuideTriggerView, which draws over it.
    //
    // Main thread only, as the @Published write demands; Game.setQuestGuidesTrigger
    // reaches it through onMainOverlay.
    @Published var trigger: BattlegroundsQuestGuideTrigger?

    var hasQuests: Bool { !selectedQuests.isEmpty }

    @available(macOS 10.15.0, *)
    func update() async {
        guard questGuides == nil else { return }

        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"
        guard let data = await HSReplayAPI.getQuestGuides(gameLanguage: gameLanguage) else { return }

        await MainActor.run {
            self.questGuides = Dictionary(uniqueKeysWithValues: data.map { ($0.quest, $0) })
        }
    }

    func selectQuest(card: Card) {
        let guide = questGuides?[card.dbfId]
        selectedQuests.append(BattlegroundsQuestGuideViewModel(questCard: card, questGuide: guide))
    }

    // The guide for one offered reward, for the tooltip the quest picker
    // raises - HDT's BattlegroundsQuestGuideListViewModel.GetQuestGuide, keyed
    // by the reward card the way selectQuest(card:) above is.
    func guide(rewardDbfId: Int) -> BattlegroundsQuestGuideViewModel? {
        guard let card = Cards.by(dbfId: rewardDbfId, collectible: false) else {
            return nil
        }
        return BattlegroundsQuestGuideViewModel(questCard: card, questGuide: questGuides?[rewardDbfId])
    }

    func onMatchEnd() {
        selectedQuests = []
    }

    func reset() {
        questGuides = nil
        selectedQuests = []
    }
}
