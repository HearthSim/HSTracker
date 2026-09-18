//
//  ConstructedMulliganGuideView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's ConstructedMulliganGuide (the V1 guide, used for every game type the V2
// one does not cover - everything outside Ranked and Friendly). It is declared
// straight on the overlay canvas in Windows/OverlayWindow.xaml and sized to it
// by OverlayWindow.Update:
//     ConstructedMulliganGuide.Width  = Width / scaling
//     ConstructedMulliganGuide.Height = Height / scaling
// with scaling = Height / 1080, which is exactly RootOverlayView's scaled
// subtree - so this takes the canvas whole and places its parts with the XAML's
// own alignments and margins. This replaces the AppKit window that used to hold
// it.
struct ConstructedMulliganGuideView: View {
    @ObservedObject var viewModel: ConstructedMulliganGuideViewModel
    // The canvas width RootOverlayView measured, in the 1080-tall reference
    // space this subtree is authored in.
    let canvasWidth: CGFloat

    private static let canvasHeight: CGFloat = 1080

    // The card row's container: Grid Margin="6,-30,0,0" Width="988"
    // HorizontalAlignment="Center" VerticalAlignment="Center". A WPF margin on a
    // centred element shifts it by half the difference between the two opposing
    // sides, so 6 on the left moves it 3 right and -30 on the top moves it 15 up.
    private static let cardRowWidth: CGFloat = 988
    private static let cardRowOffsetX: CGFloat = 3
    private static let cardRowOffsetY: CGFloat = -15

    // ItemsControl Margin="-16,0", which widens the UniformGrid the columns are
    // divided out of past its container on both sides.
    private static let cardRowBleed: CGFloat = 16

    // OverlayMessage HorizontalAlignment="Center" VerticalAlignment="Bottom"
    // Margin="738 0 0 13" - so 369 right of centre, 13 up from the bottom.
    private static let messageOffsetX: CGFloat = 369
    private static let messageBottom: CGFloat = 13

    // The toggle Border: MinWidth="180", Padding="8 5", CornerRadius="4",
    // HorizontalAlignment="Center" VerticalAlignment="Bottom"
    // Margin="0 0 936 213" - 468 left of centre, 213 up from the bottom.
    private static let toggleMinWidth: CGFloat = 180
    private static let toggleOffsetX: CGFloat = -468
    private static let toggleBottom: CGFloat = 213
    private static let hsReplayNetBlue = Color(hex: "#1D3657")

    var body: some View {
        // Instantiated unconditionally so the @ObservedObject binding keeps
        // driving it; each part draws nothing when its own flag says not to,
        // which is what replaces the window show/hide.
        ZStack {
            if viewModel.statsVisibility && !viewModel.cardStats.isEmpty {
                cardRow
                ConstructedMulliganOverlayMessageView(viewModel: viewModel.message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, Self.messageBottom)
                    .offset(x: Self.messageOffsetX)
            }

            if viewModel.visibility {
                visibilityToggle
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, Self.toggleBottom)
                    .offset(x: Self.toggleOffsetX)
            }
        }
        .frame(width: canvasWidth, height: Self.canvasHeight)
    }

    // The offered cards, laid out the way HDT's UniformGrid Rows="1" does:
    // however many columns there are share the row's width evenly, and each
    // 212-wide cell is centred in its own column - which, with five cards in a
    // 1020-wide row, is narrower than the cell, so the plates sit shoulder to
    // shoulder exactly as the cards under them do.
    private var cardRow: some View {
        let width = Self.cardRowWidth + Self.cardRowBleed * 2
        let columnWidth = viewModel.cardStats.isEmpty
            ? width
            : width / CGFloat(viewModel.cardStats.count)
        return HStack(spacing: 0) {
            ForEach(viewModel.cardStats) { card in
                ConstructedMulliganSingleCardStatsView(viewModel: card)
                    .frame(width: columnWidth)
            }
        }
        .frame(width: width)
        .offset(x: Self.cardRowOffsetX, y: Self.cardRowOffsetY)
    }

    private var visibilityToggle: some View {
        // The DockPanel inside the Border: the text docks left and the icon,
        // as the last child, fills what is left and right-aligns itself in it.
        // The trailing .fixedSize() is what keeps that from swallowing the
        // whole canvas: without it the Spacer makes this HStack greedy and the
        // Border stretches across the overlay, since the bottom-anchored frame
        // that positions it proposes the full canvas width. MinWidth="180"
        // still applies, so the Border is content-sized but never narrower.
        HStack(spacing: 0) {
            Text(viewModel.visibilityToggleText)
                // No FontSize on the TextBlock, so WPF's 12pt default.
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize()
            Spacer(minLength: 8)
            // Rectangle Height="12" Width="16" filled with the icon.
            Image(viewModel.visibilityToggleIcon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 12)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(minWidth: Self.toggleMinWidth)
        .background(Self.hsReplayNetBlue)
        .cornerRadius(4)
        .fixedSize()
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleStatsVisibility()
        }
        // IsOverlayHitTestVisible="True" on the Border: this is the one part of
        // the guide that takes clicks.
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                       value: [proxy.frame(in: .rootOverlayCanvas)])
            }
        )
    }
}

#Preview {
    let vm = ConstructedMulliganGuideViewModel()
    vm.cardStats = (1...4).map { rank in
        let stats = SingleCardStats(dbf_id: rank)
        stats.rank = rank
        stats.opening_hand_winrate = 46.0 + Double(rank) * 3
        stats.keep_percentage = 90.0 - Double(rank) * 7
        stats.baseWinRate = 52.0
        return ConstructedMulliganSingleCardViewModel(stats: stats, maxRank: 4)
    }
    vm.visibility = true
    vm.statsVisibility = true
    vm.message.text = "vs Mage, going first"
    return ConstructedMulliganGuideView(viewModel: vm, canvasWidth: 1920)
        .frame(width: 1920, height: 1080)
        .background(Color.gray)
}
