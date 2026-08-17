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
@available(macOS 10.15, *)
final class BattlegroundsQuestGuidesViewModel: ObservableObject {
    @Published var questGuides: [Int: BattlegroundsQuestGuide]?
    @Published var selectedQuests: [BattlegroundsQuestGuideViewModel] = []

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

    func onMatchEnd() {
        selectedQuests = []
    }

    func reset() {
        questGuides = nil
        selectedQuests = []
    }
}
