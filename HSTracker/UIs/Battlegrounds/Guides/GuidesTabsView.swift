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
    @ObservedObject var minionsGuide: BattlegroundsMinionsViewModel

    // Matches HDT's GuidesTabs.xaml Width="249" exactly (3 buttons x 83pt
    // each, once Minions joins as the third tab). Not private - the tab
    // content sizes itself against this (see BattlegroundsMinionsView's
    // tierStrip, which derives its badge size so the row fits the panel).
    static let width: CGFloat = 249

    var body: some View {
        // Visibility gated here, in a View holding its own @ObservedObject -
        // see BattlegroundsCompGuidesPanel's old header comment (Milestone 1)
        // for why gating from RootOverlayView itself doesn't reliably react
        // to nested ObservableObject changes.
        // To exercise the guides panel outside a real Battlegrounds match, swap
        // the gate below for `if true` - the panel then renders whatever the view
        // models hold instead of waiting for a lobby. Pair it with the stand-in
        // lobby in BattlegroundsMinionsViewModel.availableRaces, or the Minions
        // tab comes up with no races and an empty Card Types grid.
        // if true {
        if viewModel.showBrowser && AppDelegate.instance().coreManager.game.isBattlegroundsMatch() {
            VStack(spacing: 0) {
                // Stand-alone mode drops the tab strip and shows the minions
                // browser on its own, matching HDT's third top-bar state
                // (browser on, guides off). The browser is always expanded there
                // - there is no tab left to collapse it with.
                if viewModel.isStandAlone {
                    tabContent(.minions)
                } else {
                    tabStrip
                    if let activeTab = viewModel.activeTab {
                        tabContent(activeTab)
                    }
                }
            }
            .frame(width: Self.width)
            // Top/right/bottom only - a full 4-sided stroke put an unwanted
            // seam down the left edge, most noticeable against the tab strip
            // and tier strip's flat backgrounds.
            //
            // Stand-alone has no outer border at all: the tier strip carries its
            // own left edge and each card group is already boxed, which is how
            // HDT's BattlegroundsMinions looks without the tabs around it.
            .overlay(standAloneBorder)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self, value: [proxy.frame(in: .rootOverlayCanvas)])
                }
            )
        }
    }

    @ViewBuilder
    private var standAloneBorder: some View {
        if !viewModel.isStandAlone {
            ThreeSidedBorder().stroke(Color(hex: "#3f4346"), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func tabContent(_ activeTab: GuidesTab) -> some View {
        content(for: activeTab)
                        // Pin content to the panel width so no tab's content can
                        // widen the panel out from under the tab strip. The Minions
                        // tier row used to do exactly that (measured 264pt inside
                        // this 249pt panel), which pushed the tab strip 7.5pt off
                        // centre and spilled rows past the border drawn below.
                        .frame(width: Self.width)
                        // Cap at (canvas height − tab strip) so the panel grows to
                        // fill the window bottom for long lists while still shrinking
                        // for short ones (fixedSize below handles the shrink side).
                        //
                        // alignment: .top is required, not cosmetic: with the
                        // default .center, content shorter than this box gets
                        // centred and the slack is split above and below it.
                        // Selecting a tier in the Minions tab did that - the tier
                        // row measured 7.5pt below the tab strip instead of flush
                        // against it, exposing the transparent game board through
                        // the gap. Pinning to .top keeps it flush in every state.
                        .frame(maxHeight: 1080 - 49, alignment: .top)
                        // Minions content manages its own per-group backgrounds so the
                        // gaps between groups are transparent (showing the game window).
                        // Comps and Heroes content views need the panel fill.
                        .background(activeTab == .minions ? Color.clear : Color(hex: "#23272A"))
    }

    private var tabStrip: some View {
        HStack(spacing: 0) {
            // Tab order mirrors GuidesTabs.xaml: Minions first, then Comps, then Heroes.
            // icon_card from Icons.xaml: Canvas 20×27, displayed at 18.2×23 pt with
            // a white VisualBrush OpacityMask in XAML — matched here by the SVG asset.
            GuidesTabButton(imageName: "icon-card", iconSize: CGSize(width: 18.2, height: 23), isActive: viewModel.activeTab == .minions) {
                viewModel.toggleMinions()
            }
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
        case .minions:
            BattlegroundsMinionsView(viewModel: minionsGuide, isStandAlone: viewModel.isStandAlone)
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
            // ZStack + a single outer frame, matching MinionsViewTierButton's
            // pattern, rather than two chained .frame() calls on the Image
            // itself - equivalent in practice, just more consistent with the
            // rest of this file.
            ZStack {
                backgroundColor
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize.width, height: iconSize.height)
            }
            .frame(width: Self.buttonWidth, height: Self.buttonHeight)
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

// Outline stroke omitting the left edge - see GuidesTabsView.body's outer
// overlay for why (a full 4-sided stroke left an unwanted seam on the left).
@available(macOS 10.15, *)
private struct ThreeSidedBorder: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}
