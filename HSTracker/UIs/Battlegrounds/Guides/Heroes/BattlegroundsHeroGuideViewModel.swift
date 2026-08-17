//
//  BattlegroundsHeroGuideViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's BattlegroundsHeroGuideViewModel, computed once at selection
// time (like BattlegroundsCompGuideViewModel) rather than as live-computed
// properties - buddies-enabled/available-races are stable for the rest of
// the match by the time a hero is actually picked.
@available(macOS 10.15, *)
struct BattlegroundsHeroGuideViewModel {
    let heroCard: Card
    let howToPlay: String
    let isGuidePublished: Bool
    let howToPlayBuddy: String
    let isBuddyGuidePublished: Bool
    let favorableTribes: [Race]

    init(heroCard: Card, heroGuide: BattlegroundsHeroGuide?) {
        self.heroCard = heroCard

        let howToPlay = heroGuide?.published_guide ?? ""
        self.howToPlay = howToPlay
        self.isGuidePublished = !howToPlay.isEmpty

        let howToPlayBuddy = heroGuide?.buddy_guide ?? ""
        self.howToPlayBuddy = howToPlayBuddy
        let buddiesEnabled = AppDelegate.instance().coreManager.game.battlegroundsBuddiesEnabled
        self.isBuddyGuidePublished = isGuidePublished && buddiesEnabled && !howToPlayBuddy.isEmpty

        let availableRaces = Set(AppDelegate.instance().coreManager.game.availableRaces ?? [])
        self.favorableTribes = (heroGuide?.favorable_tribes ?? []).compactMap { raceNumber -> Race? in
            guard raceNumber >= 0, raceNumber < Race.allCases.count else { return nil }
            let race = Race.allCases[raceNumber]
            return availableRaces.contains(race) ? race : nil
        }
    }
}
