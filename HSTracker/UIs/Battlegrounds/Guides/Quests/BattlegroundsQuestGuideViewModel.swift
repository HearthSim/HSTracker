//
//  BattlegroundsQuestGuideViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's BattlegroundsQuestGuideViewModel, computed once at selection
// time - same convention as BattlegroundsHeroGuideViewModel.
@available(macOS 10.15, *)
struct BattlegroundsQuestGuideViewModel: Identifiable {
    let id = UUID()
    let questCard: Card
    let howToPlay: String
    let isGuidePublished: Bool
    let favorableTribes: [Race]

    init(questCard: Card, questGuide: BattlegroundsQuestGuide?) {
        self.questCard = questCard

        let howToPlay = questGuide?.published_guide ?? ""
        self.howToPlay = howToPlay
        self.isGuidePublished = !howToPlay.isEmpty

        let availableRaces = Set(AppDelegate.instance().coreManager.game.availableRaces ?? [])
        self.favorableTribes = (questGuide?.favorable_tribes ?? []).compactMap { raceNumber -> Race? in
            guard raceNumber >= 0, raceNumber < Race.allCases.count else { return nil }
            let race = Race.allCases[raceNumber]
            return availableRaces.contains(race) ? race : nil
        }
    }
}
