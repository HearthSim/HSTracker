//
//  BattlegroundsGameRowView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsGameView.xaml
// (Controls/Overlay/Battlegrounds/Session): one row of the Latest Games list.
//
// The final-board tooltip the row opens on hover is drawn by
// BattlegroundsFinalBoardPanel rather than here - see that file for why it
// cannot live inside the session window. The row only reports that it is
// hovered and where it sits, in the session panel's own coordinate space.
@available(macOS 10.15, *)
struct BattlegroundsGameRowView: View {
    let viewModel: BattlegroundsGameRowViewModel

    // Canvas Height="34" Width="238" - the row content, inside the panel's
    // 1pt border.
    static let rowHeight: CGFloat = 34
    static let rowWidth: CGFloat = 238

    // Grid.ColumnDefinitions 1.7* / 1* / 1* over the 238pt row.
    private static let heroColumnWidth: CGFloat = rowWidth * 1.7 / 3.7
    private static let placeColumnWidth: CGFloat = rowWidth * 1.0 / 3.7
    private static let mmrColumnWidth: CGFloat = rowWidth * 1.0 / 3.7

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Group {
            ZStack(alignment: .topLeading) {
                // Image Canvas.Left="-35" Canvas.Top="5" Margin="-10,-5,0,0",
                // i.e. (-45, 0).
                BattlegroundsSessionTileArt(card: viewModel.heroCard,
                                            fadeColor: Color(hex: "#AA000000"))
                    .offset(x: -45, y: 0)

                HStack(spacing: 0) {
                    // HeroName, HorizontalAlignment="Left" Margin="8,0,0,0".
                    // HearthstoneTextBlock shrinks the font until the name fits
                    // rather than trimming it (OutlinedTextBlock.MeasureOverride),
                    // which is what keeps a hero with no short name - "Overlord
                    // Saurfang", "Yogg-Saron, Hope's End" - readable in the
                    // ~101pt the column leaves.
                    Text(viewModel.heroName)
                        .chunkFive(size: 13)
                        .lineLimit(1)
                        .minimumScaleFactor(1.0 / 13.0)
                        .outlinedText()
                        .padding(.leading, 8)
                        .frame(width: Self.heroColumnWidth, alignment: .leading)

                    // Canvas 22x18 holding the placement text, with the crown
                    // pinned at Canvas.Left="-8" Canvas.Top="-7".
                    ZStack(alignment: .topLeading) {
                        // WPF lets a NoWrap TextBlock overflow its Width
                        // instead of trimming it, and "2nd" at 13pt bold is a
                        // hair wider than 23pt - .fixedSize() keeps SwiftUI
                        // from truncating it to "2...".
                        Text(viewModel.placementText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(viewModel.placementColor)
                            .multilineTextAlignment(.center)
                            .fixedSize()
                            .frame(width: 23)
                        if viewModel.showCrown {
                            Image("bgs_crown")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .offset(x: -8, y: -7)
                        }
                    }
                    .frame(width: 22, height: 18)
                    .frame(width: Self.placeColumnWidth)

                    Text(viewModel.mmrDeltaText)
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.mmrDeltaColor)
                        .frame(width: Self.mmrColumnWidth)
                }
                .frame(width: Self.rowWidth, height: Self.rowHeight)
            }
            .frame(width: Self.rowWidth, height: Self.rowHeight, alignment: .topLeading)
            .clipped()
        }
        .frame(width: Self.rowWidth, height: Self.rowHeight)
        .background(Color(hex: "#AA000000"))
        // Border BorderBrush="#1C2022" BorderThickness="0,1,0,0". Drawn over
        // the row rather than stacked above it: HDT's border overflows the
        // 34pt Canvas it wraps, so consecutive rows still sit 34pt apart.
        .overlay(Color(hex: "#1C2022").frame(height: 1), alignment: .top)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: HoveredGamePreferenceKey.self,
                    value: isHovering
                        ? HoveredGame(frame: proxy.frame(in: .named(BattlegroundsSessionView.coordinateSpace)),
                                      viewModel: viewModel)
                        : nil
                )
            }
        )
    }
}

// What a hovered row hands up to the session panel so the tooltip window can be
// placed relative to that row. The frame is in the panel's own unscaled
// coordinate space, whose origin is the panel's top-left corner.
@available(macOS 10.15, *)
struct HoveredGame: Equatable {
    let frame: CGRect
    let viewModel: BattlegroundsGameRowViewModel
}

@available(macOS 10.15, *)
struct HoveredGamePreferenceKey: PreferenceKey {
    static var defaultValue: HoveredGame?
    static func reduce(value: inout HoveredGame?, nextValue: () -> HoveredGame?) {
        value = nextValue() ?? value
    }
}
