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

    var body: some View {
        VStack(spacing: 0) {
            tierStrip
            ScrollView {
                VStack(spacing: 0) {
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
        // Adaptive sizing matches HDT's TierButton.Size logic:
        //   ≤6 tiers: badge=38, spacing=3 → 6×38+5×3+2×3=249pt
        //    7 tiers: badge=33, spacing=2 → 7×33+6×2+2×3=249pt
        let count = viewModel.availableTiers.count
        let badgeSize: CGFloat = count >= 7 ? 33 : 38
        let spacing: CGFloat = count >= 7 ? 2 : 3
        return HStack(spacing: spacing) {
            ForEach(viewModel.availableTiers, id: \.self) { tier in
                MinionsViewTierButton(tier: tier, isActive: viewModel.activeTier == tier, badgeSize: badgeSize) {
                    viewModel.selectTier(tier)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 5)
        .background(Color(hex: "#1c1f22"))
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
            .padding(.top, 5)
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
