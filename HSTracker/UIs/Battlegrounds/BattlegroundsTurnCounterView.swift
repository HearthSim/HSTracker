//
//  BattlegroundsTurnCounterView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/20/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's TurnCounter.xaml, which is a single Border - Background
// "#141617", CornerRadius "0,0,0,3" - wrapping a HearthstoneTextBlock
// (ChunkFive 20pt, outlined) at Margin="10,3".
//
// It sits in BgsTopBar immediately left of the guides tabs, which is why
// RootOverlayView pairs the two in one top-trailing HStack rather than
// positioning this separately. Height 49 comes from that StackPanel and
// matches GuidesTabsView's own tab strip, so the two line up.
@available(macOS 10.15, *)
final class BattlegroundsTurnCounterViewModel: ObservableObject {
    @Published var turn = 0
    @Published var isShown = false

    // HDT formats Overlay_Battlegrounds_Turn_Counter ("Turn {0}"); HSTracker
    // already had the equivalent "Turn %d" key from the AppKit counter, so that
    // one is kept and its translations carry over.
    var turnText: String {
        String(format: String.localizedString("Turn %d", comment: ""), max(turn, 1))
    }

    func update(turn: Int? = nil, isShown: Bool) {
        if let turn, turn > 0 {
            self.turn = turn
        }
        self.isShown = isShown
    }

    func reset() {
        turn = 0
        isShown = false
    }
}

@available(macOS 10.15, *)
struct BattlegroundsTurnCounterView: View {
    @ObservedObject var viewModel: BattlegroundsTurnCounterViewModel
    // The MultiDataTrigger on the TurnCounter's style binds across to two other
    // elements - BattlegroundsMinions' IsFilterButtonVisible and GuidesTabs'
    // Visibility - so the counter needs both view models, not just its own.
    // Held as @ObservedObject rather than read through RootOverlayViewModel
    // because a parent view does not re-render for a nested ObservableObject's
    // changes (see GuidesTabsView's own header comment).
    @ObservedObject var minionsGuide: BattlegroundsMinionsViewModel
    @ObservedObject var guidesTabs: BattlegroundsGuidesTabsViewModel

    // Height="49" on the TurnCounter in BgsTopBar.
    static let height: CGFloat = 49

    // TranslateTransform.X target once the filter tab is out and the tab strip
    // is gone. A RenderTransform in HDT and .offset here - both are visual only,
    // so the guides panel beside the counter stays put and the counter slides
    // left over the game board to make room for the tab.
    private static let slideOffset: CGFloat = -46

    // The MultiDataTrigger's two conditions: IsFilterButtonVisible on the
    // minions view model, and GuidesTabs collapsed - which is any state other
    // than "browser on and guides on", the only one that draws the tab strip.
    //
    // Faithful to HDT down to its quirk: with the browser off entirely the tab
    // strip is also collapsed, and the top-bar hover mask still runs, so merely
    // hovering the corner slides the counter aside for a tab that isn't there.
    private var isSlidLeft: Bool {
        minionsGuide.isFilterButtonVisible && !(guidesTabs.showBrowser && guidesTabs.showGuides)
    }

    var body: some View {
        if viewModel.isShown {
            Text(viewModel.turnText)
                .chunkFive(size: 20)
                .outlinedText()
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .frame(height: Self.height)
                .background(TurnCounterShape().fill(Color(hex: "#141617")))
                // No animation of its own: HDT gives this 0.2s each way while
                // the tab it moves for uses 0.2s out and 0.4s back, leaving the
                // two out of step on the way in. Letting whichever withAnimation
                // changed IsFilterButtonVisible carry both keeps them together.
                .offset(x: isSlidLeft ? Self.slideOffset : 0)
        }
    }
}

// CornerRadius="0,0,0,3": square except the bottom-left corner, where the
// counter meets the game board. Same silhouette as the tier strip's, kept
// local rather than shared because the two have no other coupling.
@available(macOS 10.15, *)
private struct TurnCounterShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 3
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}
