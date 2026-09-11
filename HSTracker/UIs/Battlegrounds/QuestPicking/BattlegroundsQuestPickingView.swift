//
//  BattlegroundsQuestPickingView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsQuestPicking.xaml: the stats drawn over the quest
// rewards offered on turns 1 and 4, with the MMR bracket they come from
// underneath.
//
// Like the other two pickers the control covers HDT's whole overlay canvas -
// OverlayWindow.Update sets it to Width/scaling by Height/scaling at Canvas 0,0
// with scaling = Height/1080 - which is the space RootOverlayView's scaled
// subtree lays its children out in, so everything inside keeps the XAML's own
// alignments and margins.
@available(macOS 10.15, *)
struct BattlegroundsQuestPickingView: View {
    @ObservedObject var viewModel: BattlegroundsQuestPickingViewModel
    let canvasWidth: CGFloat

    // Each reward is a Height="880" Width="273" Grid with Margin="56 0" in a
    // single-row UniformGrid, so its column is 56 + 273 + 56 wide.
    private static let cellWidth = BattlegroundsSingleQuestView.size.width + 2 * 56

    // Gated in here rather than by the parent: RootOverlayView instantiates
    // this unconditionally so its @ObservedObject binding stays live.
    var body: some View {
        ZStack {
            if viewModel.visibility, let quests = viewModel.quests {
                questRow(quests)
            }
            // Declared outside the animated Grid in the XAML, so it shows
            // whenever it has something to say - including while the stats are
            // still loading.
            message
        }
        .frame(width: canvasWidth, height: 1080)
    }

    // The ItemsControl, inside a Grid with Margin="0,154,5,0" that is centred
    // both ways - so it sits half of each of those margins below and left of
    // the centre of the canvas.
    private func questRow(_ quests: [BattlegroundsSingleQuestViewModel]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(quests.enumerated()), id: \.offset) { _, quest in
                BattlegroundsSingleQuestView(viewModel: quest)
                    .frame(width: Self.cellWidth, height: BattlegroundsSingleQuestView.size.height)
            }
        }
        .offset(x: Self.rowOffsetX, y: 154 / 2)
        // anim:FadeAnimation Direction="Down" Distance="20" Duration="0:0:0.2":
        // appearing, it starts 20pt above where it belongs and comes down into
        // place as it fades up. Driven by the withAnimation the view model
        // wraps its own assignments in.
        .transition(AnyTransition.opacity.combined(with: .offset(x: 0, y: -20)))
    }

    // Half of the containing Grid's Margin="0,154,5,0" - see questRow() above.
    private static let rowOffsetX: CGFloat = -5 / 2

    // HorizontalAlignment="Center" VerticalAlignment="Bottom"
    // Margin="738 0 0 13", as on every picker.
    private var message: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            OverlayMessageView(text: viewModel.message.text)
                .offset(x: 738 / 2)
                .padding(.bottom, 13)
        }
    }
}
