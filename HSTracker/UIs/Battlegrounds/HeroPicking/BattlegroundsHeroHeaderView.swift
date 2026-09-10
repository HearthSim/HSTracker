//
//  BattlegroundsHeroHeaderView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
private extension Color {
    static let tier7Purple = Color(red: 0x36 / 255, green: 0x16 / 255, blue: 0x37 / 255)
    static let tier7Black = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x17 / 255)
}

// Port of HDT's BattlegroundsHeroHeader.xaml: the stats plate that sits over
// one offered hero - average placement on the left, tier in the middle, pick
// rate on the right - and the placement distribution that takes over its right
// half while the cursor is on the average placement.
@available(macOS 10.15, *)
struct BattlegroundsHeroHeaderView: View {
    @ObservedObject var viewModel: BattlegroundsHeroHeaderViewModel

    // Grid Height="60" Width="243".
    static let size = CGSize(width: 243, height: 60)
    // ColumnDefinitions "*", "64", "*".
    private static let tierColumnWidth: CGFloat = 64
    private static let sideColumnWidth = (size.width - tierColumnWidth) / 2
    private static let tierColumnX = sideColumnWidth
    private static let rightColumnX = sideColumnWidth + tierColumnWidth
    // RowDefinitions "22", "*".
    private static let titleRowHeight: CGFloat = 22
    private static let valueRowHeight = size.height - titleRowHeight

    var body: some View {
        ZStack(alignment: .topLeading) {
            BattlegroundsHeroHeaderChrome(tierGradient: viewModel.tierLinearGradient)

            // Avg Placement, column 0.
            title(String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacement", comment: ""))
                .frame(width: Self.sideColumnWidth, height: Self.titleRowHeight)
            value(Self.avgPlacementText(viewModel.avgPlacement))
                .foregroundColor(Color(hex: viewModel.avgPlacementColor))
                .frame(width: Self.sideColumnWidth, height: Self.valueRowHeight)
                .offset(y: Self.titleRowHeight)

            // Pick Rate, column 2.
            title(String.localizedString("BattlegroundsHeroPicking_Header_PickRate", comment: ""))
                .frame(width: Self.sideColumnWidth, height: Self.titleRowHeight)
                .offset(x: Self.rightColumnX)
            value(Self.pickRateText(viewModel.pickRate))
                .foregroundColor(.white)
                .frame(width: Self.sideColumnWidth, height: Self.valueRowHeight)
                .offset(x: Self.rightColumnX, y: Self.titleRowHeight)

            tier

            if viewModel.placementDistributionVisibility {
                // Grid.Column="1" Grid.ColumnSpan="2" Grid.RowSpan="2"
                // Margin="5 0 0 0".
                BattlegroundsPlacementDistributionView(values: viewModel.placementDistribution ?? [])
                    .frame(width: Self.size.width - Self.tierColumnX - 5, height: Self.size.height)
                    .offset(x: Self.tierColumnX + 5)
            }

            avgPlacementTrigger
            pickRateTrigger
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    // MARK: - Text

    // The file's default TextBlock style: white, 12pt, centred both ways, and
    // ellipsised rather than wrapped.
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

    // Grid.RowSpan="2" Grid.Column="1" Height="52" Width="52"
    // VerticalAlignment="Top", holding a vertically centred StackPanel.
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

    // MARK: - Hover triggers

    // AvgPlacementTrigger: the whole left column, IsOverlayHitTestVisible, with
    // MouseEnter/MouseLeave revealing the placement distribution on every hero.
    private var avgPlacementTrigger: some View {
        Color.clear
            .frame(width: Self.sideColumnWidth, height: Self.size.height)
            // The Grid's OpacityMask is a Border with CornerRadius="0 0 35 0",
            // which rounds the trigger's bottom-right corner away to follow the
            // plate's own notch. The rectangle RootOverlayWindow is told about
            // below stays the full column - it only decides which pixels stop
            // being click-through, and a hair of extra area there costs
            // nothing.
            .contentShape(RoundedCorner(radius: 35, corners: .bottomRight))
            .onHover { hovering in
                onAvgPlacementHover(hovering)
            }
            .bgsTopTooltip(
                title: String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacementTooltip_Title", comment: ""),
                desc: String.localizedString("BattlegroundsHeroPicking_Header_AvgPlacementTooltip_Desc", comment: ""))
            .background(interactiveRegion)
    }

    // The pick rate's tooltip trigger is a fixed 90x62 centred on the right
    // column rather than the whole of it, masked to round its bottom-left
    // corner (CornerRadius="0 0 0 35").
    private var pickRateTrigger: some View {
        Color.clear
            .frame(width: 90, height: 62)
            .contentShape(RoundedCorner(radius: 35, corners: .bottomLeft))
            .bgsTopTooltip(
                title: String.localizedString("BattlegroundsHeroPicking_Header_PickRateTooltip_Title", comment: ""),
                desc: String.localizedString("BattlegroundsHeroPicking_Header_PickRateTooltip_Desc", comment: ""))
            .background(interactiveRegion)
            .offset(x: Self.rightColumnX + (Self.sideColumnWidth - 90) / 2,
                    y: (Self.size.height - 62) / 2)
    }

    private var interactiveRegion: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: InteractiveRegionPreferenceKey.self,
                                   value: [proxy.frame(in: .rootOverlayCanvas)])
        }
    }

    // AvgPlacementTrigger_MouseEnter/MouseLeave, both debounced by 100ms so
    // sweeping the cursor across the row doesn't flicker the distribution on
    // and off on every hero.
    private func onAvgPlacementHover(_ hovering: Bool) {
        Task.init {
            if await Debounce.wasCalledAgain(milliseconds: 100, callerMemberName: "AvgPlacementTrigger") {
                return
            }
            viewModel.onPlacementHover?(hovering)
        }
    }

    // MARK: - Formatting

    // StringFormat=N2 and StringFormat={}{0:0.0}%, both culture-aware, which is
    // what the NSTextField formatters the AppKit header carried did too.
    private static let avgPlacementFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Language.culture
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let pickRateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Language.culture
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    // TargetNullValue on both. HDT's XAML uses an en dash; HSTracker's shared
    // StatsHeaderViewModel already answers a missing tier with an em dash, so
    // all three placeholders in this plate stay the one character.
    private static let missingValue = "—"

    private static func avgPlacementText(_ value: Double?) -> String {
        guard let value else {
            return missingValue
        }
        return avgPlacementFormatter.string(from: NSNumber(value: value)) ?? missingValue
    }

    private static func pickRateText(_ value: Double?) -> String {
        guard let value else {
            return missingValue
        }
        return pickRateFormatter.string(from: NSNumber(value: value / 100.0)) ?? missingValue
    }
}
