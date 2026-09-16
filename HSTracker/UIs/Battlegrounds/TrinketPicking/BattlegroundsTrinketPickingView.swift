//
//  BattlegroundsTrinketPickingView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let tier7Purple = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)
}

// Port of HDT's BattlegroundsTrinketPicking.xaml: the row of stats plates drawn
// over the trinkets offered mid-run, the MMR bracket they come from, and the
// toggle that shows and hides them.
//
// Like the hero picker, the control covers HDT's whole overlay canvas -
// OverlayWindow.Update sets it to Width/scaling by Height/scaling at Canvas 0,0
// with scaling = Height/1080 - which is the space RootOverlayView's scaled
// subtree lays its children out in, so everything inside keeps the XAML's own
// alignments and margins.
@available(macOS 10.15, *)
struct BattlegroundsTrinketPickingView: View {
    @ObservedObject var viewModel: BattlegroundsTrinketPickingViewModel
    let canvasWidth: CGFloat

    // Each trinket is a Height="430" Width="252" Grid with Margin="12.5,0" in a
    // single-row UniformGrid, so its column is 12.5 + 252 + 12.5 wide.
    private static let cellWidth = BattlegroundsSingleTrinketView.size.width + 2 * 12.5

    // Gated in here rather than by the parent: RootOverlayView instantiates
    // this unconditionally so its @ObservedObject binding stays live.
    var body: some View {
        ZStack {
            if viewModel.visibility {
                panel
            }
        }
    }

    private var panel: some View {
        ZStack {
            if viewModel.statsVisibility, let trinketStats = viewModel.trinketStats {
                stats(trinketStats)
            }
            visibilityToggle
        }
        .frame(width: canvasWidth, height: 1080)
    }

    private func stats(_ trinketStats: [StatsHeaderViewModel]) -> some View {
        ZStack {
            trinkets(trinketStats)
            message
        }
        // anim:FadeAnimation Direction="Down" Distance="20" Duration="0:0:0.2":
        // appearing, it starts 20pt above where it belongs and comes down into
        // place as it fades up. Driven by the withAnimation the view model
        // wraps its own assignments in.
        .transition(AnyTransition.opacity.combined(with: .offset(x: 0, y: -20)))
    }

    // The ItemsControl, inside a Grid with Margin="20,-165,0,0" that is centred
    // both ways - so it sits half of each of those margins right of and above
    // the centre of the canvas.
    private func trinkets(_ trinketStats: [StatsHeaderViewModel]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(trinketStats.enumerated()), id: \.offset) { _, trinket in
                BattlegroundsSingleTrinketView(viewModel: trinket)
                    .frame(width: Self.cellWidth, height: BattlegroundsSingleTrinketView.size.height)
            }
        }
        .offset(x: 20 / 2, y: -165 / 2)
    }

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

    // The Border at HorizontalAlignment="Center" VerticalAlignment="Bottom"
    // Margin="0 0 936 213": 213pt off the bottom of the canvas and, since only
    // the right margin is set on a centred element, 468pt left of its centre.
    private var visibilityToggle: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            toggleButton
                .offset(x: -936 / 2)
                .padding(.bottom, 213)
        }
    }

    private var toggleButton: some View {
        HStack(spacing: 0) {
            Text(viewModel.visibilityToggleText)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fixedSize()
            Spacer(minLength: 0)
            // A Rectangle filled with a VisualBrush of the eye/eye-slash icon,
            // Height="12" Width="16". HSTracker's icons are bitmaps rather than
            // HDT's vector resources, so they are fitted into that box instead
            // of stretched to it.
            Image(viewModel.visibilityToggleIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 12)
        }
        // Padding="8 5", MinWidth="180" on the Border - which includes it.
        .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
        .frame(minWidth: 180)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.tier7Purple))
        .fixedSize()
        // Cursor="Hand" and MouseUp on the Border.
        .onTapGesture {
            viewModel.toggleStatsVisibility()
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                       value: [proxy.frame(in: .rootOverlayCanvas)])
            }
        )
    }
}
