//
//  BattlegroundsCompositionStatsRowView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsCompositionStatsRow.xaml and the
// BattlegroundsCompositionStatsBar.xaml it hosts
// (Controls/Overlay/Battlegrounds/Composition). One row of the session panel's
// Composition Stats table: faded key-minion art with the comp's name over it,
// a first-place popularity bar, and the average placement.
@available(macOS 10.15, *)
struct BattlegroundsCompositionStatsRowView: View {
    let viewModel: BattlegroundsCompositionStatsRowViewModel

    // Grid Height="30" Width="240" Background="#141617", columns
    // 0.9* / 70px / 0.8* - so 90 / 70 / 80 of the 240.
    private static let rowHeight: CGFloat = 30
    private static let rowWidth: CGFloat = 240
    private static let nameColumnWidth: CGFloat = 90
    private static let barColumnWidth: CGFloat = 70
    private static let placementColumnWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#141617")

            // Canvas Grid.Column="0" Width="120px" ClipToBounds="True": wider
            // than its own column, deliberately overflowing under the bar.
            ZStack(alignment: .topLeading) {
                // Image Canvas.Left="-35" Canvas.Top="5" Margin="-18,-5,0,0"
                // Height="34" Width="145" - so (-53, 0) once the margin is
                // folded in.
                BattlegroundsSessionTileArt(card: Cards.by(dbfId: viewModel.minionDbfId, collectible: false),
                                            fadeColor: Color(hex: "#141617"))
                    .offset(x: -53, y: 0)
                // HearthstoneTextBlock Canvas.Left="8" Canvas.Top="6" FontSize="13"
                Text(viewModel.name)
                    .chunkFive(size: 13)
                    .outlinedText()
                    .fixedSize()
                    .offset(x: 8, y: 6)
            }
            .frame(width: 120, height: Self.rowHeight, alignment: .topLeading)
            .clipped()

            HStack(spacing: 0) {
                Color.clear
                    .frame(width: Self.nameColumnWidth)
                BattlegroundsCompositionStatsBarView(percent: viewModel.firstPlacePercent,
                                                     maxPercent: viewModel.maxBarPercentage)
                    .frame(width: Self.barColumnWidth)
                Text(viewModel.avgPlacement)
                    .chunkFive(size: 13)
                    .foregroundColor(Color(hex: viewModel.avgPlacementColor))
                    .frame(width: Self.placementColumnWidth)
            }
            .frame(width: Self.rowWidth, height: Self.rowHeight)
        }
        .frame(width: Self.rowWidth, height: Self.rowHeight)
    }
}

// BattlegroundsCompositionStatsBar.xaml: a 70x22 rounded track with a
// gradient-filled progress border and the percentage written over it.
@available(macOS 10.15, *)
struct BattlegroundsCompositionStatsBarView: View {
    let percent: Double
    let maxPercent: Double

    private static let width: CGFloat = 70
    private static let height: CGFloat = 22

    // Ensure MaxPercent is not zero to avoid division by zero
    private var fillWidth: CGFloat {
        let safeMaxPercent = maxPercent == 0 ? 100.0 : maxPercent
        return min(Self.width, max(0, Self.width * CGFloat(percent) / CGFloat(safeMaxPercent)))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#232526"))
                .frame(width: Self.width, height: Self.height)

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(gradient: Gradient(colors: [
                        Color(hex: "#FFC58DC9"),
                        Color(hex: "#CCC58DC9")
                    ]), startPoint: .top, endPoint: .bottom))
                    .frame(width: fillWidth, height: Self.height)
                Spacer(minLength: 0)
            }
            .frame(width: Self.width, height: Self.height)

            // percentageText.Text = $"{newPercent:0.0}%"
            Text(verbatim: String(format: "%.1f%%", percent))
                .chunkFive(size: 13)
                .outlinedText()
                .fixedSize()
        }
        .frame(width: Self.width, height: Self.height)
    }
}
