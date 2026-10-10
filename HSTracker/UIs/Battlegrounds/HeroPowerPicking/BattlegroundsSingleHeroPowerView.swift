//
//  BattlegroundsSingleHeroPowerView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Port of HDT's BattlegroundsSingleHeroPower.xaml: the trinket plate's layout -
// the tier square above two panels pushed 39pt down - with a circle cut out of
// the panels around the hero power below, and the hero header's placement
// distribution and tooltips on the panels.
struct BattlegroundsSingleHeroPowerView: View {
    @ObservedObject var viewModel: BattlegroundsHeroHeaderViewModel

    // The two Grids inside the Canvas: the plate is 243x100 at 0,0 and the
    // stats Grid is 243x61 at Canvas.Top="39".
    static let plateSize = CGSize(width: 243, height: 100)
    private static let statsTop: CGFloat = 39
    private static let statsHeight: CGFloat = 61
    // ColumnDefinitions "*", "64", "*" and RowDefinitions "22", "*".
    private static let tierColumnWidth: CGFloat = 64
    private static let sideColumnWidth = (plateSize.width - tierColumnWidth) / 2
    private static let tierColumnX = sideColumnWidth
    private static let rightColumnX = sideColumnWidth + tierColumnWidth
    private static let titleRowHeight: CGFloat = 22

    var body: some View {
        ZStack(alignment: .topLeading) {
            BattlegroundsStatsPlateChrome(tierGradient: viewModel.tierLinearGradient, layout: .heroPowerPlate)
                .frame(width: Self.plateSize.width, height: Self.plateSize.height)

            tier

            stats
        }
        .frame(width: Self.plateSize.width, height: Self.plateSize.height, alignment: .topLeading)
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
        .offset(x: Self.tierColumnX + (Self.tierColumnWidth - 52) / 2)
    }

    // The second Grid, at Canvas.Top="39": the two stat columns in the panels,
    // the tooltip triggers over them and the placement distribution.
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

            avgPlacementTrigger
            pickRateTrigger

            if viewModel.placementDistributionVisibility {
                // Grid.Column="1" Grid.ColumnSpan="2" Grid.RowSpan="2"
                // Margin="5 0 0 0" MaxValue="30".
                BattlegroundsPlacementDistributionView(values: viewModel.placementDistribution ?? [])
                    .frame(width: Self.plateSize.width - Self.tierColumnX - 5, height: Self.statsHeight)
                    .offset(x: Self.tierColumnX + 5)
            }
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

    // MARK: - Hover triggers

    // The left column, masked to round its bottom-right corner
    // (CornerRadius="0 0 35 0"), with MouseEnter/MouseLeave revealing the
    // placement distribution on every hero power.
    private var avgPlacementTrigger: some View {
        Color.clear
            .frame(width: Self.sideColumnWidth, height: Self.statsHeight)
            .contentShape(RoundedCorner(radius: 35, corners: .bottomRight))
            .onHover { hovering in
                onAvgPlacementHover(hovering)
            }
            .bgsTopTooltip(
                title: String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacementTooltip_Title", comment: ""),
                desc: String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacementTooltip_Desc", comment: ""))
            .background(interactiveRegion)
    }

    // The right column, masked to round its bottom-left corner
    // (CornerRadius="0 0 0 35").
    private var pickRateTrigger: some View {
        Color.clear
            .frame(width: Self.sideColumnWidth, height: Self.statsHeight)
            .contentShape(RoundedCorner(radius: 35, corners: .bottomLeft))
            .bgsTopTooltip(
                title: String.localizedString("BattlegroundsHeroPicking_Header_PickRateTooltip_Title", comment: ""),
                desc: String.localizedString("BattlegroundsHeroPicking_Header_PickRateTooltip_Desc", comment: ""))
            .background(interactiveRegion)
            .offset(x: Self.rightColumnX)
    }

    private var interactiveRegion: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                   value: [proxy.frame(in: .rootOverlayCanvas)])
        }
    }

    // AvgPlacementTrigger_MouseEnter/MouseLeave, both debounced by 100ms.
    private func onAvgPlacementHover(_ hovering: Bool) {
        Task.init {
            if await Debounce.wasCalledAgain(milliseconds: 100, callerMemberName: "AvgPlacementTrigger") {
                return
            }
            viewModel.onPlacementHover?(hovering)
        }
    }
}
