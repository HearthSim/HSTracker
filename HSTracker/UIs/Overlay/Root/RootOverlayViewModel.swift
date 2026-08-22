//
//  RootOverlayViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Single scaled canvas new SwiftUI overlay features attach to as children,
// instead of each feature owning its own window + hand-rolled height/1080
// scaling math (what every AppKit overlay, including the V1 mulligan guide,
// currently does individually). RootOverlayView derives scale/canvas size
// directly from its own measured bounds (GeometryReader) rather than from
// state pushed in here, so content authored at the 1080-tall reference
// (matching the rest of HSTracker's overlay scaling convention) lines up
// regardless of the window's aspect ratio.
@available(macOS 10.15, *)
class RootOverlayViewModel: ObservableObject {
    let mulliganGuideV2 = ConstructedMulliganGuideV2ViewModel()
    let constructedMulliganPreLobbyWidget = ConstructedMulliganPreLobbyWidgetViewModel()
    let mulliganGuideTrialsExhausted = MulliganGuideTrialsExhaustedViewModel()
    let battlegroundsCompsGuides = BattlegroundsCompsGuidesViewModel()
    let battlegroundsHeroGuides = BattlegroundsHeroGuidesViewModel()
    let battlegroundsTrinketGuides = BattlegroundsTrinketGuidesViewModel()
    let battlegroundsAnomalyGuides = BattlegroundsAnomalyGuidesViewModel()
    let battlegroundsQuestGuides = BattlegroundsQuestGuidesViewModel()
    let battlegroundsMinionsGuide = BattlegroundsMinionsViewModel()
    let battlegroundsGuidesTabs = BattlegroundsGuidesTabsViewModel()
    let battlegroundsTurnCounter = BattlegroundsTurnCounterViewModel()
    let battlegroundsInspiration = BattlegroundsInspirationViewModel()
    let battlegroundsMinionPinning = BattlegroundsMinionPinningViewModel()

    init() {
        // HDT wires the same reference in OverlayWindow's constructor
        // (BattlegroundsMinionPinningViewModel.CompsGuidesVM = ...): the key
        // piece recommendations are mined out of the loaded comp guides.
        battlegroundsMinionPinning.compsGuides = battlegroundsCompsGuides
    }

    // On-screen frames (in RootOverlayView's own coordinate space) of every
    // child that currently needs real mouse interactivity, reported by
    // InteractiveRegionPreferenceKey. RootOverlayWindow reads these to know
    // which pixels should stop being click-through. One rect per child rather
    // than their bounding box - see the preference key for why.
    @Published var interactiveRegions: [CGRect] = []

    // Frame of whichever child wants to know when the cursor is merely *over*
    // it, without claiming clicks. This is HDT's IsOverlayHoverVisible, the
    // counterpart to the IsOverlayHitTestVisible that interactiveRegion covers:
    // BgsTopBarMask is `IsHitTestVisible="False"` precisely so it can reveal the
    // minion browser's filter button on hover while every click in that corner
    // still falls through to Hearthstone.
    //
    // Reported by HoverRegionPreferenceKey and matched against the cursor by
    // RootOverlayWindow, which tracks it continuously regardless of
    // ignoresMouseEvents - SwiftUI's own .onHover can't do this job, since it
    // only fires once the window has already stopped being click-through.
    @Published var hoverRegion: CGRect?
}
