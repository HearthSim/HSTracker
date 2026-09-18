//
//  ConstructedMulliganGuideViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/19/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

// HDT's ConstructedMulliganGuideViewModel, behind the V1 mulligan guide.
class ConstructedMulliganGuideViewModel: ObservableObject {
    // Whether the guide is up at all - which, in HDT, is only the visibility of
    // the toggle button; the stats themselves are behind statsVisibility.
    @Published var visibility = false

    @Published var statsVisibility = false

    @Published var cardStats: [ConstructedMulliganSingleCardViewModel] = []

    // HDT's Message. Its own ObservableObject, so the banner view observes it
    // directly - a parent view does not re-render for a nested one's changes.
    let message = ConstructedMulliganOverlayMessageViewModel()

    var visibilityToggleIcon: String {
        statsVisibility ? "eye_slash" : "eye"
    }

    var visibilityToggleText: String {
        statsVisibility
            ? String.localizedString("ConstructedMulliganGuide_VisibilityToggle_Hide", comment: "")
            : String.localizedString("ConstructedMulliganGuide_VisibilityToggle_Show", comment: "")
    }

    // ConstructedMulliganGuide.OverlayVisibilityToggle_MouseUp, which both flips
    // the stats and remembers the choice for the next game.
    func toggleStatsVisibility() {
        statsVisibility.toggle()
        Settings.autoShowMulliganGuide = statsVisibility
    }

    func reset() {
        cardStats = []
        visibility = false
        statsVisibility = false
        message.text = nil
    }

    func setMulliganData(stats: [SingleCardStats]?, maxRank: Int?, selectedParams: [String: String?]?) {
        cardStats = stats?.compactMap { x in ConstructedMulliganSingleCardViewModel(stats: x, maxRank: maxRank) } ?? []

        if let selectedParams {
            var opponentClass: CardClass?
            if let opponentClassString = selectedParams["opponent_class"] {
                opponentClass = CardClass(rawValue: opponentClassString ?? "")
            }
            var initiative: ConstructedMulliganOverlayMessageViewModel.PlayerInitiative?
            if let initiativeString = selectedParams["PlayerInitiative"] {
                initiative = ConstructedMulliganOverlayMessageViewModel.PlayerInitiative(rawValue: initiativeString?.lowercased() ?? "")
            }

            if let opponentClass, let initiative {
                message.scope(cardClass: opponentClass, initiative: initiative)
            }
        }

        visibility = true
        statsVisibility = Settings.autoShowMulliganGuide
    }
}
