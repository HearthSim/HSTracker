//
//  BattlegroundsMinionsView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsTierDetailsView in native SwiftUI:
//   - Tier button strip at the top (tier-N.png thumbnails, matches the look of
//     BattlegroundsTierOverlayView's own tier strip exactly).
//   - Tribe mode (click a tribe header → all tiers for that tribe with a back
//     button to return) mirrors BattlegroundsMinionTypesBox's click-to-filter
//     behaviour.
//   - Unavailable races footer shown in tier mode when the lobby has restricted
//     the pool.
//   - Card grid is 3-column BattlegroundsMinionArtView tiles (70x70 pt),
//     matching the width used in CompGuideDetailView.
@available(macOS 10.15, *)
struct BattlegroundsMinionsView: View {
    @ObservedObject var viewModel: BattlegroundsMinionsViewModel

    private static let cardColumns = 3
    private static let tileSize: CGFloat = 70

    var body: some View {
        VStack(spacing: 0) {
            tierStrip
            if viewModel.activeTier == nil && viewModel.activeTribe == nil {
                emptyPrompt
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.activeTribe != nil {
                            backButton
                        }
                        ForEach(viewModel.groups) { group in
                            groupSection(group)
                        }
                        if viewModel.activeTier != nil && viewModel.activeTribe == nil {
                            unavailableFooter
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tier strip

    private var tierStrip: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.availableTiers, id: \.self) { tier in
                MinionsViewTierButton(tier: tier, isActive: viewModel.activeTier == tier) {
                    viewModel.selectTier(tier)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color(hex: "#1c1f22"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#3f4346")), alignment: .bottom)
    }

    // MARK: - Card groups

    @ViewBuilder
    private func groupSection(_ group: BattlegroundsMinionsViewModel.MinionGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader(group)
            cardGrid(group.minions)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#1c1f22"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#3f4346")), alignment: .top)
    }

    @ViewBuilder
    private func groupHeader(_ group: BattlegroundsMinionsViewModel.MinionGroup) -> some View {
        if group.groupedByMinionType {
            // Tribe mode: header shows tier number using the tier-N.png image.
            tierGroupHeader(tier: group.tier)
        } else {
            // Tier mode: header shows tribe name, clickable to switch to tribe mode.
            tribeGroupHeader(group: group)
        }
    }

    private func tierGroupHeader(tier: Int) -> some View {
        HStack(spacing: 5) {
            MinionsViewTierBadge(tier: tier)
            Text("Tier \(tier)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    @ViewBuilder
    private func tribeGroupHeader(group: BattlegroundsMinionsViewModel.MinionGroup) -> some View {
        let raceName = groupLabel(minionType: group.minionType, raceName: group.raceName)
        let tribeRace = Race(rawValue: group.minionType)
        Button {
            if let race = tribeRace {
                viewModel.selectTribe(race)
            }
        } label: {
            HStack(spacing: 5) {
                if let imageName = tribeImageName(minionType: group.minionType) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
                Text(raceName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                if tribeRace != nil {
                    Text("›")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func groupLabel(minionType: Int, raceName: String) -> String {
        if minionType == -1 { return String.localizedString("spells", comment: "") }
        if minionType == Race.lookup(.invalid) { return String.localizedString("neutral", comment: "") }
        return raceName
    }

    private func tribeImageName(minionType: Int) -> String? {
        guard let race = Race(rawValue: minionType) else { return nil }
        switch race {
        case .murloc: return "tribe_murloc"
        case .demon: return "tribe_demon"
        case .mechanical: return "tribe_mechanical"
        case .elemental: return "tribe_elemental"
        case .beast: return "tribe_beast"
        case .pirate: return "tribe_pirate"
        case .dragon: return "tribe_dragon"
        case .quilboar: return "tribe_quilboar"
        case .naga: return "tribe_naga"
        case .undead: return "tribe_undead"
        default: return nil
        }
    }

    private func cardGrid(_ minions: [BattlegroundsCompGuideViewModel.GuideMinion]) -> some View {
        VStack(alignment: .center, spacing: 8) {
            ForEach(Array(minions.chunks(Self.cardColumns).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row) { minion in
                        BattlegroundsMinionArtView(minion: minion)
                            .scaledToFrame(width: Self.tileSize, height: Self.tileSize)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Back button (tribe mode)

    private var backButton: some View {
        Button {
            viewModel.activeTribe = nil
        } label: {
            HStack(spacing: 5) {
                Text("\u{2039}")
                    .font(.system(size: 12, weight: .bold))
                Text("All Tribes")
                    .font(.system(size: 10))
            }
            .foregroundColor(.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 30, alignment: .leading)
        .padding(.horizontal, 9)
    }

    // MARK: - Unavailable footer

    @ViewBuilder
    private var unavailableFooter: some View {
        let races = viewModel.unavailableRaces
        if !races.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Not in this lobby:")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                HStack(spacing: 8) {
                    ForEach(races, id: \.self) { race in
                        if let name = tribeImageName(minionType: Race.lookup(race)) {
                            Image(name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .opacity(0.35)
                        }
                    }
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#3f4346")), alignment: .top)
        }
    }

    // MARK: - Empty prompt

    private var emptyPrompt: some View {
        Text("Select a tier to see minions")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }
}

// Tier button in the top strip: shows the tier-N.png image with an active
// highlight (glow border) matching BattlegroundsTierOverlayView's own style.
@available(macOS 10.15, *)
private struct MinionsViewTierButton: View {
    let tier: Int
    let isActive: Bool
    let action: () -> Void

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: action) {
            MinionsViewTierBadge(tier: tier)
                .padding(2)
                .background(isActive ? Color(hex: "#FFB00D").opacity(0.25) : Color.clear)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isActive ? Color(hex: "#FFB00D").opacity(0.6) : Color.clear, lineWidth: 1)
                )
                .opacity(isHovering && !isActive ? 0.75 : 1.0)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
    }
}

// Reusable tier-N.png image badge used in both the strip buttons and the
// tier-grouped section headers.
@available(macOS 10.15, *)
struct MinionsViewTierBadge: View {
    let tier: Int

    var body: some View {
        Group {
            if let img = Self.tierImage(tier) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 28)
            } else {
                Text("\(tier)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 28)
            }
        }
    }

    static func tierImage(_ tier: Int) -> NSImage? {
        guard tier > 0, let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-\(tier).png")
    }
}
