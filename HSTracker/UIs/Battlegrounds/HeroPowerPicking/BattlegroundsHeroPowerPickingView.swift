//
//  BattlegroundsHeroPowerPickingView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

private extension Color {
    static let tier7Purple = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)
}

// Port of HDT's BattlegroundsHeroPowerPicking.xaml: the hero pick stats over the
// hero powers Sir Finley offers, each with the portrait of its hero below it,
// the MMR bracket they come from, and the toggle that shows and hides them.
//
// Like the other pickers the control covers HDT's whole 1080-high overlay
// canvas, which is the space RootOverlayView's scaled subtree lays its children
// out in.
struct BattlegroundsHeroPowerPickingView: View {
    @ObservedObject var viewModel: BattlegroundsHeroPowerPickingViewModel
    let canvasWidth: CGFloat

    // Each hero power is a Height="430" Width="252" Grid with Margin="67.07,0"
    // in a single-row UniformGrid.
    private static let cellSize = CGSize(width: 252, height: 430)
    private static let cellWidth = cellSize.width + 2 * 67.07

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
            if viewModel.statsVisibility, let heroPowerStats = viewModel.heroPowerStats {
                stats(heroPowerStats)
            }
            visibilityToggle
        }
        .frame(width: canvasWidth, height: 1080)
    }

    private func stats(_ heroPowerStats: [BattlegroundsSingleHeroPowerViewModel]) -> some View {
        ZStack {
            heroPowers(heroPowerStats)
            message
        }
        // anim:FadeAnimation Direction="Down" Distance="20" Duration="0:0:0.2".
        .transition(AnyTransition.opacity.combined(with: .offset(x: 0, y: -20)))
    }

    // The ItemsControl, inside a Grid with Margin="0,-175.8,0,0" that is
    // centred both ways - so it sits half of that above the canvas centre.
    private func heroPowers(_ heroPowerStats: [BattlegroundsSingleHeroPowerViewModel]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(heroPowerStats.enumerated()), id: \.offset) { _, heroPower in
                BattlegroundsSingleHeroPowerCell(viewModel: heroPower)
                    .frame(width: Self.cellSize.width, height: Self.cellSize.height, alignment: .topLeading)
                    .frame(width: Self.cellWidth)
            }
        }
        .offset(y: -175.8 / 2)
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
    // Margin="0 0 936 135".
    private var visibilityToggle: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            toggleButton
                .offset(x: -936 / 2)
                .padding(.bottom, 135)
        }
    }

    private var toggleButton: some View {
        HStack(spacing: 0) {
            Text(viewModel.visibilityToggleText)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fixedSize()
            Spacer(minLength: 0)
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

// The DataTemplate's Grid: the stats plate centred at the top, and the hero's
// portrait floating below the hero power without taking up layout space.
private struct BattlegroundsSingleHeroPowerCell: View {
    @ObservedObject var viewModel: BattlegroundsSingleHeroPowerViewModel

    // The inner Canvas at Canvas.Left="221.9" Canvas.Top="403.6", scaled by
    // 0.6 from its top-left corner: a 160x170 hero render with the armor badge,
    // a 100x100 Grid, at 85,95 within it.
    private static let portraitOrigin = CGPoint(x: 221.9, y: 403.6)
    private static let portraitScale: CGFloat = 0.6

    var body: some View {
        ZStack(alignment: .topLeading) {
            // HorizontalAlignment="Center" VerticalAlignment="Top" Width="243"
            // in the 252 wide cell.
            BattlegroundsSingleHeroPowerView(viewModel: viewModel.bgsHeroHeaderVM)
                .offset(x: (252 - BattlegroundsSingleHeroPowerView.plateSize.width) / 2)

            portrait
                .scaleEffect(Self.portraitScale, anchor: .topLeading)
                .offset(x: Self.portraitOrigin.x, y: Self.portraitOrigin.y)
        }
    }

    private var portrait: some View {
        ZStack(alignment: .topLeading) {
            if let heroImage = viewModel.heroImage {
                Image(nsImage: heroImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 170)
            } else {
                Color.clear.frame(width: 160, height: 170)
            }

            if viewModel.armorVisibility, let armor = viewModel.armor {
                ZStack {
                    Image("armor")
                        .resizable()
                        .frame(width: 100, height: 100)
                    // An OutlinedTextBlock with StrokeWidth="4.2", half of
                    // which falls outside the glyphs.
                    Text(verbatim: "\(armor)")
                        .chunkFive(size: 42)
                        .fixedSize()
                        .outlinedText(width: 2.1)
                }
                .frame(width: 100, height: 100)
                .offset(x: 85, y: 95)
            }
        }
        .frame(width: 160, height: 170, alignment: .topLeading)
    }
}
