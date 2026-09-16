//
//  CardTooltipPlacement.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

// HDT's ToolTipService.Placement, as consumed by its own overlay tooltip system
// (OverlayExtensions.Tooltip + OverlayWindow.Tooltips.cs) rather than by WPF's:
// SetTooltip normalizes Top, Bottom and Left and folds everything else -
// including unset - into Right. So Right is the default here too, matching
// CardTile.xaml, which attaches a CardTooltip without naming a placement.
//
// Shared by everything that ports a piece of SetTooltip: CardTooltipPanel, which
// positions the hover preview itself; the Battlegrounds guides and the pool
// browser, which ask it for a side; and Game.setRelatedCardsTrigger, which
// carries vm.TooltipPlacement for the related-cards grid it places by hand.
enum CardTooltipPlacement {
    case left
    case right
    case top
    case bottom

    // SetTooltip only ever swaps a placement for the opposite one on the same
    // axis, so Left and Right never become Top or Bottom.
    var flipped: CardTooltipPlacement {
        switch self {
        case .left: return .right
        case .right: return .left
        case .top: return .bottom
        case .bottom: return .top
        }
    }
}
