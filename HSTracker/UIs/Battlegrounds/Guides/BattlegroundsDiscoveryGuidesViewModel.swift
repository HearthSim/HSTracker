//
//  BattlegroundsDiscoveryGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// The state behind HDT's DiscoveryGuidesTooltipTrigger - the one overlay
// element SetTrinketGuidesTrigger and SetQuestGuidesTrigger share
// (Windows/OverlayWindow.Tooltips.cs). Both write the same
// CardGridTooltipViewModel, so whichever of the two the hovered choice is, the
// trigger ends up over it; the trinket one resets the shared state first, which
// is what clears it when nothing applies.
@available(macOS 10.15, *)
struct BattlegroundsDiscoveryGuideTrigger: Equatable {
    // Which guide the trigger raises - HDT keys this off the card's type in
    // GuideTooltipContainer.UpdateContent.
    enum Content: Equatable {
        case trinket(dbfId: Int)
        case questReward(dbfId: Int)
    }

    // vm.TooltipPlacement, of the guide relative to the trigger.
    enum Placement: Equatable {
        case left
        case right
        case bottom
    }

    let content: Content

    // The rectangle, as HDT writes it into the view model: x goes through
    // GetScaledXPos, the other three are fractions of the client height.
    let x: CGFloat
    let top: CGFloat
    let width: CGFloat
    let height: CGFloat

    let placement: Placement
    // vm.TooltipVerticalOffset, before HDT's * vm.Scale - this lives in the
    // scaled subtree, which applies that scale itself.
    let verticalOffset: CGFloat
    // vm.TooltipAlignment: Start pins the guide's leading/top edge to the
    // trigger's, Center centres it (the CardGridTooltipViewModel default).
    let alignsToStart: Bool
}

@available(macOS 10.15, *)
final class BattlegroundsDiscoveryGuidesViewModel: ObservableObject {
    // Non-nil only while the game has a tooltip up for a hovered trinket or
    // quest reward - see BattlegroundsDiscoveryGuideTriggerView.
    //
    // Main thread only, as the @Published write demands; the Game-side setters
    // reach it through onMainOverlay.
    @Published var trigger: BattlegroundsDiscoveryGuideTrigger?
}
