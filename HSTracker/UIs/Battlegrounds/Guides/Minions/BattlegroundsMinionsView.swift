//
//  BattlegroundsMinionsView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct BattlegroundsMinionsView: View {
    @ObservedObject var viewModel: BattlegroundsMinionsViewModel

    // HDT's TierButton style: Setter Property="Padding" Value="9" (all sides).
    private static let horizontalPadding: CGFloat = 9

    var body: some View {
        VStack(spacing: 0) {
            tierStrip
            ScrollView {
                // 5pt spacing goes *between* groups only (VStack spacing, not
                // each group's own top padding) - a per-group top padding put
                // an unwanted transparent gap directly under the tier strip
                // for the first group too, since the minions tab's content
                // background is Color.clear (see GuidesTabsView.body).
                VStack(spacing: 5) {
                    ForEach(viewModel.groups) { group in
                        BattlegroundsCardsGroupView(group: group) { race in
                            viewModel.selectTribe(race)
                        }
                    }
                    if viewModel.activeTier != nil && viewModel.activeTribe == nil {
                        unavailableFooter
                    }
                }
            }
        }
    }

    // MARK: - Tier strip

    private var tierStrip: some View {
        // Adaptive sizing follows HDT's TierButton.Size logic (≤6 tiers: 38pt
        // badges at 3pt spacing; 7 tiers: 33pt at 2pt), but the badge size is
        // capped to whatever actually fits the panel rather than taken as a
        // constant. HDT's numbers assume 3pt of horizontal padding, which is
        // what makes them total exactly 249; under the 9pt padding this row
        // now uses they'd come to 261 and overflow the panel on both sides
        // (measured: the row rendered 264 wide at x=-7.5 inside a 249 frame,
        // spilling past the panel border).
        let count = viewModel.availableTiers.count
        let spacing: CGFloat = count >= 7 ? 2 : 3
        let preferredBadge: CGFloat = count >= 7 ? 33 : 38
        let available = GuidesTabsView.width
            - Self.horizontalPadding * 2
            - spacing * CGFloat(max(count - 1, 0))
        let badgeSize: CGFloat = count > 0
            ? min(preferredBadge, (available / CGFloat(count)).rounded(.down))
            : preferredBadge
        return HStack(spacing: spacing) {
            ForEach(viewModel.availableTiers, id: \.self) { tier in
                MinionsViewTierButton(tier: tier, isActive: viewModel.activeTier == tier, badgeSize: badgeSize) {
                    viewModel.selectTier(tier)
                }
            }
        }
        // Matches HDT's TierButton style: Setter Property="Padding" Value="9" (all sides).
        .padding(Self.horizontalPadding)
        // Left-align via a flexible frame rather than a trailing Spacer: a
        // Spacer is a full HStack child, so it added a sixth `spacing` gap and
        // pushed the row to 252pt inside the 249pt panel (measured), spilling
        // 1.5pt past each edge.
        .frame(maxWidth: .infinity, alignment: .leading)
        // Matches GuidesTabButton's isActive background (#23272A), NOT
        // tabStrip's own idle/hover fill (#2C3135) - the Minions tab button
        // is always active while this is visible, and it deliberately drops
        // its bottom border to sit flush against this exact color (see
        // GuidesTabButton's bottomBorder comment).
        .background(Color(hex: "#23272A"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#141617")), alignment: .bottom)
        .clipped()
    }

    // MARK: - Unavailable footer (mirrors BattlegroundsMinionTypesBox.xaml)
    //
    // Shows when a tier is selected (no tribe/keyword filter active) and at
    // least one race from Db.Races is not in the lobby's available races.
    // Structure: dark-blue header (#1d3657) + comma-joined race names below.

    @ViewBuilder
    private var unavailableFooter: some View {
        let races = viewModel.unavailableRaces
        if !races.isEmpty {
            let names = races
                .map { String.localizedString("\($0)", comment: "") }
                .sorted()
                .joined(separator: ", ")
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(String.localizedString("unavailable", comment: ""))
                        .chunkFive(size: 14)
                        .outlinedText()
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                    Spacer(minLength: 0)
                }
                .background(Color(hex: "#1d3657"))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#141617")), alignment: .bottom)

                Text(names)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(hex: "#23272a"))
            .overlay(Rectangle().stroke(Color(hex: "#141617"), lineWidth: 1))
        }
    }

}

// MARK: - Tier button strip

@available(macOS 10.15, *)
private struct MinionsViewTierButton: View {
    let tier: Int
    let isActive: Bool
    let badgeSize: CGFloat
    let action: () -> Void

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // tier-glow.png drawn behind the badge for active/hover state,
                // matching BattlegroundsTierOverlayView.drawTier() which draws the
                // glow at (x, 8, 40, 40) behind a (x+2, 10, 36, 36) badge.
                // We scale proportionally: glow fills the button, badge is inset 1pt.
                if isActive || isHovering, let glow = Self.glowImage {
                    Image(nsImage: glow)
                        .resizable()
                        .frame(width: badgeSize, height: badgeSize)
                        .opacity(isActive ? 1.0 : 0.5)
                }
                // Badge fades to 0.5 when inactive; stays full when active or hovered.
                // Unavailable tiers in the overlay fade to 0.3; available stay at 1.0.
                // Since our strip only shows available tiers, inactive = 0.5 (dim, not hidden).
                MinionsViewTierBadge(tier: tier, badgeSize: badgeSize)
                    .opacity(isActive || isHovering ? 1.0 : 0.5)

                // Hovering the already-selected tier previews a deselect: tier-x.png,
                // matching the real Battlegrounds tavern tier selector's own hover
                // affordance for its currently-picked tier.
                if isActive && isHovering, let tierX = Self.tierXImage {
                    Image(nsImage: tierX)
                        .resizable()
                        .frame(width: badgeSize, height: badgeSize)
                }
            }
            .frame(width: badgeSize, height: badgeSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
    }

    private static let glowImage: NSImage? = {
        guard let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-glow.png")
    }()

    private static let tierXImage: NSImage? = {
        guard let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-x.png")
    }()
}

@available(macOS 10.15, *)
struct MinionsViewTierBadge: View {
    let tier: Int
    let badgeSize: CGFloat

    var body: some View {
        Group {
            if let img = Self.tierImage(tier) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: badgeSize, height: badgeSize)
            } else {
                Text("\(tier)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: badgeSize, height: badgeSize)
            }
        }
    }

    static func tierImage(_ tier: Int) -> NSImage? {
        guard tier > 0, let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-\(tier).png")
    }
}
