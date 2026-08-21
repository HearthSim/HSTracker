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

    // Height="49" on the TurnCounter in BgsTopBar.
    static let height: CGFloat = 49

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
