//
//  GuidesTabsView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's GuidesTabs.xaml: an icon row that toggles which guide's
// content shows below it. Replaces Milestone 1's standalone
// BattlegroundsCompGuidesPanel - Comps now shows behind a tab click instead
// of always-on, matching HDT. Trinkets/Anomalies never get one (tooltip-only
// in HDT too).
@available(macOS 10.15, *)
struct GuidesTabsView: View {
    @ObservedObject var viewModel: BattlegroundsGuidesTabsViewModel
    @ObservedObject var compsGuides: BattlegroundsCompsGuidesViewModel
    @ObservedObject var heroGuides: BattlegroundsHeroGuidesViewModel
    @ObservedObject var questGuides: BattlegroundsQuestGuidesViewModel

    // Matches HDT's GuidesTabs.xaml Width="249" exactly (3 buttons x 83pt
    // each, once Minions joins as the third tab).
    private static let width: CGFloat = 249

    var body: some View {
        // Visibility gated here, in a View holding its own @ObservedObject -
        // see BattlegroundsCompGuidesPanel's old header comment (Milestone 1)
        // for why gating from RootOverlayView itself doesn't reliably react
        // to nested ObservableObject changes.
        if AppDelegate.instance().coreManager.game.isBattlegroundsMatch() {
            VStack(spacing: 0) {
                tabStrip
                if let activeTab = viewModel.activeTab {
                    content(for: activeTab)
                }
            }
            .frame(width: Self.width)
            .background(Color(hex: "#23272A"))
            .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color(hex: "#3f4346"), lineWidth: 1))
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self, value: proxy.frame(in: .rootOverlayCanvas))
                }
            )
        }
    }

    private var tabStrip: some View {
        HStack(spacing: 0) {
            // Ported from HDT's Resources/Icons.xaml icon_comp, white +
            // amber Tier7-accent fills at fixed opacities - see
            // Assets.xcassets/icon-comp.imageset. Not a template/tintable
            // image, its two-tone coloring is fixed.
            GuidesTabButton(imageName: "icon-comp", iconSize: CGSize(width: 31, height: 23), isActive: viewModel.activeTab == .comps) {
                viewModel.toggleComps()
            }
            // Matches HDT's GuidesTabs.xaml: swaps icon_hero → icon_hero_and_quest
            // (a taller icon that stacks the quest scroll below the hero silhouette)
            // once the player has received their first quest reward mid-match.
            GuidesTabButton(
                imageName: questGuides.hasQuests ? "icon-hero-and-quest" : "icon-hero",
                iconSize: questGuides.hasQuests ? CGSize(width: 21, height: 34) : CGSize(width: 21, height: 23),
                isActive: viewModel.activeTab == .heroes
            ) {
                viewModel.toggleHeroes()
            }
            Spacer(minLength: 0)
        }
        .background(Color(hex: "#2C3135"))
    }

    @ViewBuilder
    private func content(for tab: GuidesTab) -> some View {
        switch tab {
        case .comps:
            if let comp = compsGuides.selectedComp {
                CompGuideDetailView(viewModel: compsGuides, comp: comp)
            } else {
                CompGuideListView(viewModel: compsGuides)
            }
        case .heroes:
            // Two independently-bordered panels stacked, matching HDT's
            // Heroes tab template (HeroGuide + QuestGuide as separate
            // UserControls, not one shared scroll region).
            VStack(spacing: 0) {
                HeroGuideView(viewModel: heroGuides)
                QuestGuideView(viewModel: questGuides)
            }
        }
    }
}

// Matches HDT's GuidesTabs.xaml Button style exactly: an 83x49 button (not a
// small icon-sized tap target), idle/hover/active background states
// (#141617/#2C3135/#23272A), rather than the opacity-only active/inactive
// distinction a first pass here used - that read as much smaller and flatter
// than HDT's real tab strip.
@available(macOS 10.15, *)
private struct GuidesTabButton: View {
    let imageName: String
    let iconSize: CGSize
    let isActive: Bool
    let action: () -> Void

    @SwiftUI.State private var isHovering = false

    private static let buttonWidth: CGFloat = 83
    private static let buttonHeight: CGFloat = 49

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize.width, height: iconSize.height)
                .frame(width: Self.buttonWidth, height: Self.buttonHeight)
                .background(backgroundColor)
                // HDT's active button drops its bottom border, since it sits
                // flush against the content panel below (same #23272A bg).
                .overlay(bottomBorder, alignment: .bottom)
                // See CompGuideRow's identical fix: without this, hover/
                // click hit-testing can end up scoped to the icon's own
                // rendered glyph instead of the full button frame.
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: Color {
        if isActive {
            return Color(hex: "#23272A")
        }
        return isHovering ? Color(hex: "#2C3135") : Color(hex: "#141617")
    }

    @ViewBuilder
    private var bottomBorder: some View {
        if !isActive {
            Rectangle().frame(height: 1).foregroundColor(Color(hex: "#3f4346"))
        }
    }
}
