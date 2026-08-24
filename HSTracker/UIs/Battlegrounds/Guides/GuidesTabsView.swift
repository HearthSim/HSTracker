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
    // Carried through to the browser rows and the comp guide's "pin all" button
    // (HDT reaches Core.Overlay.BattlegroundsMinionPinningViewModel statically
    // from both; there is no such global here).
    @ObservedObject var minionPinning: BattlegroundsMinionPinningViewModel

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
            // No panel-level border: HDT has none either. The outline is drawn
            // piece by piece - the tab buttons and each content root carry
            // their own left/bottom edges (see GuidesPanelBorder), which line
            // up into one continuous left edge down the column.
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: InteractiveRegionPreferenceKey.self, value: [proxy.frame(in: .rootOverlayCanvas)])
                }
            )
        }
    }

    // Ports OverlayWindow.Update's cap on the browser's height:
    //
    //   TabsContent.MaxHeight        = max(0, (H - 54 + buttonSpace) * 0.95 / scaling - pinningHeight)
    //   BattlegroundsMinions.MaxHeight = max(0, (H      + buttonSpace) * 0.95 / scaling - pinningHeight)
    //
    // with buttonSpace = 20 and pinningHeight = the Tavern Pinning control's
    // rendered height, both only while that panel is up. The two forms differ by
    // the 54pt the tab strip occupies, which stand-alone mode does not have.
    //
    // Every term matters, and the 0.95 most of all: it is a 5% bottom margin,
    // and it is what actually produces clearance. At 1080 the content bottom
    // lands at 49 + (1080 - 34) * 0.95 - h = 1042.7 - h against a cluster top of
    // 1080 - h, i.e. 37pt clear. Keeping the old `1080 - 49` base and only
    // subtracting the pinning height leaves the browser 20pt *into* the panel -
    // the +20 give-back is not clearance, it is a partial refund of the 54pt
    // button row.
    //
    // The one thing not reproduced: HDT subtracts its constants in window pixels
    // before dividing by the top bar's AutoScaling, which is clamped to
    // [0.8, 1.3], where this canvas scales uniformly by Height/1080. The two
    // agree exactly at 1080 and drift by a few points at the extremes.
    private var contentMaxHeight: CGFloat {
        let buttonSpace: CGFloat = minionPinning.isShown ? 20 : 0
        let pinningHeight: CGFloat = minionPinning.isShown ? minionPinning.panelHeight : 0
        let tabStripAllowance: CGFloat = viewModel.isStandAlone ? 0 : 54
        return max(0, (1080 - tabStripAllowance + buttonSpace) * 0.95 - pinningHeight)
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
                        // Cap so the panel grows toward the window bottom for long
                        // lists while still shrinking for short ones (fixedSize
                        // below handles the shrink side) - see contentMaxHeight.
                        //
                        // alignment: .top is required, not cosmetic: with the
                        // default .center, content shorter than this box gets
                        // centred and the slack is split above and below it.
                        // Selecting a tier in the Minions tab did that - the tier
                        // row measured 7.5pt below the tab strip instead of flush
                        // against it, exposing the transparent game board through
                        // the gap. Pinning to .top keeps it flush in every state.
                        .frame(maxHeight: contentMaxHeight, alignment: .top)
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
                CompGuideDetailView(viewModel: compsGuides, comp: comp, pinning: minionPinning)
            } else {
                CompGuideListView(viewModel: compsGuides)
            }
        case .heroes:
            // Two independently-bordered panels stacked, matching HDT's
            // Heroes tab template (HeroGuide + QuestGuide as separate
            // UserControls, not one shared scroll region).
            VStack(spacing: 0) {
                HeroGuideView(viewModel: heroGuides, hasQuests: questGuides.hasQuests)
                QuestGuideView(viewModel: questGuides)
            }
        case .minions:
            BattlegroundsMinionsView(viewModel: minionsGuide, pinning: minionPinning, isStandAlone: viewModel.isStandAlone)
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
            // BorderThickness "1,0,0,1", dropping to "1,0,0,0" on the active
            // tab: the left edge is drawn on every button - including the
            // leftmost, whose line separates the strip from the turn counter
            // beside it - while the bottom edge is dropped on the active tab,
            // which sits flush against the content panel below (same #23272A).
            .overlay(leftBorder, alignment: .leading)
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

    private var leftBorder: some View {
        Rectangle().frame(width: 1).foregroundColor(Color(hex: "#3f4346"))
    }

    @ViewBuilder
    private var bottomBorder: some View {
        if !isActive {
            Rectangle().frame(height: 1).foregroundColor(Color(hex: "#3f4346"))
        }
    }
}

// MARK: - Panel outline
//
// HDT never frames the guides column as a whole - every piece draws its own
// edges, all in #3f4346: GuidesTabs.xaml's buttons at BorderThickness
// "1,0,0,1", and each content root (CompGuideList, HeroGuide, QuestGuide, and
// BattlegroundsMinions' tier strip) at "1,0,0,1" with CornerRadius "0,0,0,3".
// Stacked, those left edges read as one line running the height of the column,
// closed off by a bottom edge with a rounded bottom-left corner.
//
// Nothing draws a top or right edge: the column is flush against the top-right
// corner of the game window, where neither would be visible.
//
// The Minions tab deliberately stops the left edge at the tier strip - the card
// groups below it are right-aligned 196pt boxes with transparent gaps between
// them, so HDT carries no line down past the strip. That is why this is applied
// per content view rather than once around the whole panel.
@available(macOS 10.15, *)
struct GuidesPanelBorder: Shape {
    // Whether this panel ends the column. HDT drops CornerRadius to 0 on a
    // panel that has another bordered one below it (HeroGuide once quests are
    // showing) - the rounded corner belongs to whichever panel ends the column.
    var isBottomRounded = true

    private static let cornerRadius: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        // Half a point in from each edge, matching TierStripBorder: the stroke
        // then lands inside the panel instead of straddling its bounds, so it
        // lines up with the tab strip's separators rather than sitting half a
        // point off them.
        let left = rect.minX + 0.5
        let bottom = rect.maxY - 0.5
        let radius = isBottomRounded ? Self.cornerRadius : 0

        var path = Path()
        path.move(to: CGPoint(x: left, y: rect.minY))
        path.addLine(to: CGPoint(x: left, y: bottom - radius))
        if radius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: left + radius, y: bottom),
                control: CGPoint(x: left, y: bottom)
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: bottom))
        return path
    }
}

@available(macOS 10.15, *)
extension View {
    /// HDT's "1,0,0,1" / #3f4346 / "0,0,0,3" content-root border - see GuidesPanelBorder.
    func guidesPanelBorder(isBottomRounded: Bool = true) -> some View {
        // maxWidth so the edges span the full 249pt panel even when the content
        // itself measures narrower - GuidesTabsView.tabContent centres content
        // in the panel width, which would otherwise inset the border with it.
        frame(maxWidth: .infinity)
            .overlay(
                GuidesPanelBorder(isBottomRounded: isBottomRounded)
                    .stroke(Color(hex: "#3f4346"), lineWidth: 1)
            )
    }
}
