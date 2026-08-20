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

    // Adaptive sizing follows HDT's TierButton.Size logic (≤6 tiers: 38pt
    // badges at 3pt spacing; 7 tiers: 33pt at 2pt), but the badge size is
    // capped to whatever actually fits the panel rather than taken as a
    // constant. HDT's numbers assume 3pt of horizontal padding, which is
    // what makes them total exactly 249; under the 9pt padding this row
    // now uses they'd come to 261 and overflow the panel on both sides
    // (measured: the row rendered 264 wide at x=-7.5 inside a 249 frame,
    // spilling past the panel border).
    private var tierSpacing: CGFloat { viewModel.tierButtons.count >= 7 ? 2 : 3 }

    private var badgeSize: CGFloat {
        let count = viewModel.tierButtons.count
        guard count > 0 else { return 38 }
        let preferred: CGFloat = count >= 7 ? 33 : 38
        let available = GuidesTabsView.width
            - Self.horizontalPadding * 2
            - tierSpacing * CGFloat(count - 1)
        return min(preferred, (available / CGFloat(count)).rounded(.down))
    }

    // The tier strip's own rendered height. The slide-out tab matches it so
    // their centres line up, and the filters panel hangs below it.
    private var stripHeight: CGFloat { badgeSize + Self.horizontalPadding * 2 }

    var body: some View {
        VStack(spacing: 0) {
            tierStrip
                // The slide-out tab has to live outside tierStrip's own .clipped(),
                // since its whole point is to extend past the panel's left edge.
                .overlay(filterButtonTab, alignment: .topLeading)
            ScrollView {
                // Spacing 0: every group carries its own 5pt top margin, which
                // is what puts a gap under the tier strip ahead of the first one
                // as well as between groups.
                VStack(spacing: 0) {
                    ForEach(viewModel.groups) { group in
                        BattlegroundsCardsGroupView(group: group) { race in
                            viewModel.selectTribe(race)
                        }
                    }
                    // Mirrors UnavailableMinionTypesVisibility: tier mode only,
                    // with no extra filter narrowing the list further.
                    if viewModel.activeTier != nil && !viewModel.isExtraFilterSelected {
                        unavailableFooter
                    }
                }
                // Groups are narrower than the panel and right-aligned, matching
                // the GroupsControl ItemsControl's HorizontalAlignment="Right".
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        // Panel anchored to the minions content's own top-left, hanging off the
        // left edge just below the tier strip - HDT's Margin="-180,73,0,0" on
        // BattlegroundsMinionsExtraFilters.
        //
        // The 20pt of it that overlap the guides panel land in the gutter left
        // of the right-aligned card groups (see BattlegroundsCardsGroupView.width),
        // so nothing is covered. This previously clipped the leading characters
        // off card names, because the groups were still full panel width.
        //
        // The y offset is measured off the strip rather than hardcoded to 73,
        // since badgeSize (and so the strip) shrinks to fit 7 tiers.
        .overlay(extraFiltersPanel, alignment: .topLeading)
    }

    // MARK: - Extra filters

    private var filterButtonTab: some View {
        // Reports its own interactive region internally, for the ordering reason
        // spelled out on reportInteractiveRegion.
        MinionsExtraFiltersButton(viewModel: viewModel)
    }

    @ViewBuilder
    private var extraFiltersPanel: some View {
        BattlegroundsMinionsExtraFiltersView(viewModel: viewModel)
            // Ahead of the offsets, so the reported rect is where the panel is
            // actually drawn.
            .reportInteractiveRegion(when: viewModel.isFiltersOpen)
            // Storyboard on IsFiltersOpen: fade in while sliding down 10pt.
            .offset(x: -180, y: stripHeight + (viewModel.isFiltersOpen ? 16 : 6))
            .opacity(viewModel.isFiltersOpen ? 1 : 0)
            .allowsHitTesting(viewModel.isFiltersOpen)
    }

    // MARK: - Tier strip

    private var tierStrip: some View {
        let badgeSize = self.badgeSize
        return HStack(spacing: tierSpacing) {
            ForEach(viewModel.tierButtons) { button in
                MinionsViewTierButton(button: button, badgeSize: badgeSize) {
                    // Unavailable tiers stay clickable, matching HDT - its
                    // UserControl_MouseUp fires ClickTierCommand with no
                    // availability check. The tier's cards still exist in the
                    // card pool; the lobby just isn't offering that tier.
                    viewModel.selectTier(button.tier)
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
        // BorderBrush="#3f4346" BorderThickness="1,0,0,1" CornerRadius="0,0,0,3"
        // on HDT's TopBorderStyle: left and bottom edges in the panel's own
        // chrome grey - not the near-black #141617 the card groups use - meeting
        // at a rounded bottom-left corner.
        //
        // The colour mistake only showed once a tier was selected: with no groups
        // the panel collapses to the strip, so GuidesTabsView's outer border
        // (#3f4346, drawn over the top) landed on this same edge and hid it.
        // Selecting a tier grows the panel, moves that outer border down, and
        // left the dark line exposed.
        .background(TierStripShape().fill(Color(hex: "#23272A")))
        .overlay(TierStripBorder().stroke(Color(hex: "#3f4346"), lineWidth: 1))
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
                .map { BattlegroundsMinionType.raceName($0) }
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
            .frame(width: BattlegroundsCardsGroupView.width)
            .background(Color(hex: "#23272a"))
            .overlay(Rectangle().stroke(Color(hex: "#141617"), lineWidth: 1))
            .padding(.top, 5)
        }
    }

}

// The tier strip's silhouette: square except for the bottom-left corner, which
// HDT rounds by 3 (CornerRadius="0,0,0,3"). Used to fill the background so the
// corner is actually cut out of it, rather than a rounded stroke sitting on top
// of a square fill.
@available(macOS 10.15, *)
private struct TierStripShape: Shape {
    static let cornerRadius: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + Self.cornerRadius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - Self.cornerRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

// The stroked half of the same silhouette - left edge, the rounded corner, and
// the bottom edge. Top and right are left open, matching BorderThickness's 0s
// there; the panel's own chrome draws those.
//
// Inset by half the line width along the two stroked edges so the 1pt stroke
// lands fully inside the frame: it is centred on the path, and the strip's
// trailing .clipped() would otherwise shave off the outer half and leave a
// half-weight line.
@available(macOS 10.15, *)
private struct TierStripBorder: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = TierStripShape.cornerRadius
        let left = rect.minX + 0.5
        let bottom = rect.maxY - 0.5
        var path = Path()
        path.move(to: CGPoint(x: left, y: rect.minY))
        path.addLine(to: CGPoint(x: left, y: bottom - radius))
        path.addQuadCurve(
            to: CGPoint(x: left + radius, y: bottom),
            control: CGPoint(x: left, y: bottom)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: bottom))
        return path
    }
}

// MARK: - Tier button strip

@available(macOS 10.15, *)
private struct MinionsViewTierButton: View {
    let button: BattlegroundsMinionsViewModel.TierButton
    let badgeSize: CGFloat
    let action: () -> Void

    private var tier: Int { button.tier }
    private var isActive: Bool { button.isActive }

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
                    .opacity(badgeOpacity)

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

    // Ported verbatim from BattlegroundsTierButton.xaml.cs's IconOpacity.
    //
    // Supersedes the flat "inactive = 0.5" this used to apply. That was a
    // reasonable stand-in while the strip rendered nothing but available tiers
    // and had no Faded input, but it collapsed three distinct states into one:
    // now an idle strip sits at full opacity, tiers the current filter excludes
    // drop to 0.3, and tiers the lobby never offered are drawn at 0.3 whether or
    // not anything is selected - brightening to 0.6 on hover so they still feel
    // live, since they remain clickable.
    private var badgeOpacity: Double {
        if isActive { return 1 }
        if !button.isAvailable { return isHovering ? 0.6 : 0.3 }
        if button.isFaded && !isHovering { return 0.3 }
        return 1
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
