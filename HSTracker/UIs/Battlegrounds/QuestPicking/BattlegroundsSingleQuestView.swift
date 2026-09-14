//
//  BattlegroundsSingleQuestView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/14/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let tier7Purple = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)
    static let tier7Black = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
}

// Port of HDT's BattlegroundsSingleQuestView.xaml: one offered quest reward -
// its average placement, tier and pick rate along the top, and the warband
// compositions that most often win with it far below, over the reward's own
// card.
@available(macOS 10.15, *)
struct BattlegroundsSingleQuestView: View {
    let viewModel: BattlegroundsSingleQuestViewModel

    // The DataTemplate's Grid: Height="880" Width="273".
    static let size = CGSize(width: 273, height: 880)

    // Grid Height="60" with ColumnDefinitions "*", "68", "*".
    private static let headerHeight: CGFloat = 60
    private static let tierColumnWidth: CGFloat = 68
    private static let sideColumnWidth = (size.width - tierColumnWidth) / 2
    // The purple cap each stat box is topped with.
    private static let capHeight: CGFloat = 19

    var body: some View {
        // The root StackPanel: the header, then the compositions pushed down by
        // their own Margin="0 667 0 0".
        VStack(spacing: 0) {
            header
            // The gap the compositions box's own Margin="0 667 0 0" opens up is
            // where the offered reward card itself sits.
            Color.clear
                .frame(height: 667)
            BattlegroundsCompositionPopularityView(viewModel: viewModel.compVM)
            Spacer(minLength: 0)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .top)
    }

    private var header: some View {
        HStack(spacing: 0) {
            statBox(title: String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacement", comment: ""),
                    value: BattlegroundsStatsText.avgPlacement(viewModel.avgPlacement),
                    valueColor: Color(hex: viewModel.avgPlacementColor),
                    cornerRadius: 4)
                .frame(width: Self.sideColumnWidth)
                .bgsTopTooltip(
                    title: String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacementTooltip_Title", comment: ""),
                    desc: String.localizedString("BattlegroundsQuestPickingHeader_AvgPlacementTooltip_Desc", comment: ""))
                .background(interactiveRegion)

            tierBox
                .frame(width: Self.tierColumnWidth)

            // The pick rate Border's CornerRadius is 1 rather than the 4 on the
            // average placement's - as in the XAML.
            statBox(title: String.localizedString("BattlegroundsHeroPicking_Header_PickRate", comment: ""),
                    value: BattlegroundsStatsText.pickRate(viewModel.pickRate),
                    valueColor: .white,
                    cornerRadius: 1)
                .frame(width: Self.sideColumnWidth)
                .bgsTopTooltip(
                    title: String.localizedString("BattlegroundsHeroPicking_Header_PickRateTooltip_Title", comment: ""),
                    desc: String.localizedString("BattlegroundsQuestPickingHeader_PickRateTooltip_Desc", comment: ""))
                .background(interactiveRegion)
        }
        .frame(height: Self.headerHeight)
    }

    // Background="{StaticResource Tier7Black}" BorderBrush="{StaticResource
    // Tier7Purple}" BorderThickness="1", holding a DockPanel of the purple cap
    // and the value under it.
    private func statBox(title: String, value: String, valueColor: Color, cornerRadius: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                // Margin="4 0" on the TextBlock, in a Height="19" Border.
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .frame(height: Self.capHeight)
                .background(Color.tier7Purple)
                // CornerRadius="4 4 0 0" with Margin="-1", so the cap covers the
                // box's own border along the top and both sides.
                .cornerRadius(4, corners: [.topLeft, .topRight])
                .padding(EdgeInsets(top: -1, leading: -1, bottom: 0, trailing: -1))

            // StatTextStyle: Chunkfive 20pt, centred, Margin="4 2 4 0".
            Text(verbatim: value)
                .chunkFive(size: 20)
                .foregroundColor(valueColor)
                .fixedSize()
                .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 4))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(RoundedRectangle(cornerRadius: cornerRadius).fill(Color.tier7Black))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.tier7Purple, lineWidth: 1))
    }

    // The tier Border is filled and bordered with the same TierGradient, with a
    // second #2E000000 Border drawn over it for a subtle inner edge.
    private var tierBox: some View {
        VStack(spacing: 0) {
            Text(String.localizedString("BattlegroundsHeroPicking_Header_Tier", comment: ""))
                .font(.system(size: 10))
                .foregroundColor(.white)
                .fixedSize()
            Text(verbatim: viewModel.tierChar)
                .chunkFive(size: 28)
                .foregroundColor(.white)
                .fixedSize()
                .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 4).fill(viewModel.tierLinearGradient))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0x2E / 255.0), lineWidth: 1))
        // Margin="4 0" on both Borders.
        .padding(.horizontal, 4)
    }

    private var interactiveRegion: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                   value: [proxy.frame(in: .rootOverlayCanvas)])
        }
    }
}
