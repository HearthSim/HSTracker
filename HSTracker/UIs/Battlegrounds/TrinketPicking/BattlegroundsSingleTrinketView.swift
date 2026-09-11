//
//  BattlegroundsSingleTrinketView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsSingleTrinket.xaml: one offered trinket's stats
// plate. It is the hero header's plate with the tier square lifted clear of the
// two panels (see BattlegroundsStatsPlateChrome.Layout), the tier label over the
// square and the average placement and pick rate in the panels below it.
@available(macOS 10.15, *)
struct BattlegroundsSingleTrinketView: View {
    let viewModel: StatsHeaderViewModel

    // The DataTemplate's Grid: Height="430" Width="252".
    static let size = CGSize(width: 252, height: 430)

    // The two Grids inside the Canvas: the plate is 243x100 at 0,0 and the
    // stats Grid is 243x61 at Canvas.Top="39".
    private static let plateSize = CGSize(width: 243, height: 100)
    private static let statsTop: CGFloat = 39
    private static let statsHeight: CGFloat = 61
    // ColumnDefinitions "*", "64", "*" and RowDefinitions "22", "*", the same
    // three columns the plate is drawn in.
    private static let tierColumnWidth: CGFloat = 64
    private static let sideColumnWidth = (plateSize.width - tierColumnWidth) / 2
    private static let rightColumnX = sideColumnWidth + tierColumnWidth
    private static let titleRowHeight: CGFloat = 22

    var body: some View {
        ZStack(alignment: .topLeading) {
            BattlegroundsStatsPlateChrome(tierGradient: viewModel.tierLinearGradient, layout: .trinketPlate)
                .frame(width: Self.plateSize.width, height: Self.plateSize.height)

            tier

            stats
        }
        // The control's root is a Canvas, which has no desired size of its own:
        // its children draw from the cell's top-left corner down.
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
    }

    // Grid.RowSpan="2" Grid.Column="1" Height="52" Width="52"
    // VerticalAlignment="Top", over the tier square.
    private var tier: some View {
        VStack(spacing: 0) {
            Text(String.localizedString("BattlegroundsHeroPicking_Header_Tier", comment: ""))
                .font(.system(size: 10))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                // Margin="0 4 0 0".
                .padding(.top, 4)
            Text(verbatim: viewModel.tierChar)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .fixedSize()
                // Margin="0 -5 0 0".
                .padding(.top, -5)
        }
        .frame(width: 52, height: 52)
        .offset(x: Self.sideColumnWidth + (Self.tierColumnWidth - 52) / 2)
    }

    // The second Grid, at Canvas.Top="39": the two stat columns in the panels.
    private var stats: some View {
        ZStack(alignment: .topLeading) {
            title(String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacement", comment: ""))
                .frame(width: Self.sideColumnWidth, height: Self.titleRowHeight)
            value(BattlegroundsStatsText.avgPlacement(viewModel.avgPlacement))
                .foregroundColor(Color(hex: viewModel.avgPlacementColor))
                .frame(width: Self.sideColumnWidth, height: Self.statsHeight - Self.titleRowHeight)
                .offset(y: Self.titleRowHeight)

            title(String.localizedString("BattlegroundsHeroPicking_Header_PickRate", comment: ""))
                .frame(width: Self.sideColumnWidth, height: Self.titleRowHeight)
                .offset(x: Self.rightColumnX)
            value(BattlegroundsStatsText.pickRate(viewModel.pickRate))
                .foregroundColor(.white)
                .frame(width: Self.sideColumnWidth, height: Self.statsHeight - Self.titleRowHeight)
                .offset(x: Self.rightColumnX, y: Self.titleRowHeight)
        }
        .frame(width: Self.plateSize.width, height: Self.statsHeight, alignment: .topLeading)
        .offset(y: Self.statsTop)
    }

    // DefaultTextStyle: white, 12pt, centred both ways, ellipsised.
    private func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .multilineTextAlignment(.center)
    }

    // BoldTextStyle: the Chunkfive face at 20pt.
    private func value(_ text: String) -> some View {
        Text(verbatim: text)
            .chunkFive(size: 20)
            .fixedSize()
    }
}
