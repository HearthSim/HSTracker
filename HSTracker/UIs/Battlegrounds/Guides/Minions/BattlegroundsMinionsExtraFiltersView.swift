//
//  BattlegroundsMinionsExtraFiltersView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/19/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsMinionsExtraFilters.xaml: a 200pt panel that slides
// in from the left of the tier strip, holding two sections —
//
//   Card Types — a grid of 34pt tribe icon buttons, one per available race plus
//                Spells and Buddies.
//   Mechanics  — a stacked list of keyword buttons.
//
// Selecting from either is mutually exclusive with the tier strip's own filter
// (see BattlegroundsMinionsViewModel's three-way filter state).
@available(macOS 10.15, *)
struct BattlegroundsMinionsExtraFiltersView: View {
    @ObservedObject var viewModel: BattlegroundsMinionsViewModel

    // Border Width="200" in the XAML.
    static let width: CGFloat = 200

    // WrapPanel ItemWidth="38" ItemHeight="40" inside a 4pt margin: 192pt of
    // usable width fits exactly 5 cells. LazyVGrid would express this directly
    // but needs macOS 11, and this module's baseline is 10.15 (same reason
    // CompGuideDetailView hand-rolls its rows), so the columns are chunked here.
    private static let columns = 5
    private static let cellWidth: CGFloat = 38
    private static let cellHeight: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader(String.localizedString("Card Types", comment: ""), isFirst: true)
            minionTypeGrid
            sectionHeader(String.localizedString("Mechanics", comment: ""), isFirst: false)
            keywordList
        }
        .frame(width: Self.width)
        .background(Color(hex: "#23272A"))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3f4346"), lineWidth: 1))
        .cornerRadius(3)
    }

    // MARK: - Section headers

    // Border Background="#141617" Padding="0,9,0,9" with a single #4A5256 edge:
    // the Card Types header carries it on the bottom, Mechanics on the top.
    private func sectionHeader(_ title: String, isFirst: Bool) -> some View {
        Text(title)
            .chunkFive(size: 13)
            .outlinedText()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Color(hex: "#141617"))
            .overlay(
                Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")),
                alignment: isFirst ? .bottom : .top
            )
    }

    // MARK: - Card Types

    private var minionTypeGrid: some View {
        let buttons = viewModel.minionTypeButtons
        let rows = stride(from: 0, to: buttons.count, by: Self.columns).map { start in
            Array(buttons[start ..< min(start + Self.columns, buttons.count)])
        }
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(row) { button in
                        BattlegroundsMinionTypeButton(button: button) {
                            viewModel.selectMinionType(button.minionType)
                        }
                        .frame(width: Self.cellWidth, height: Self.cellHeight)
                    }
                }
                // Items flow from the left within the WrapPanel, so a short final
                // row is left-aligned - only the panel itself is centred by its
                // HorizontalAlignment="Center". Centring the row instead left the
                // second row's icons out of line with the first's.
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Mechanics

    private var keywordList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.keywordButtons) { button in
                MinionsKeywordButton(button: button) {
                    viewModel.selectKeyword(button.keyword)
                }
            }
        }
    }
}

// The filter tab and the filters panel both draw outside GuidesTabsView's own
// frame, so neither is covered by the region it reports, and the overlay window
// would stay click-through over exactly their pixels.
//
// Order matters: .offset is a geometry effect applied to whatever is already
// beneath it, so a GeometryReader attached *after* an offset measures the
// un-offset layout frame. This must therefore be applied before any offset that
// positions the view, and the callers do.
@available(macOS 10.15, *)
extension View {
    func reportInteractiveRegion(when isActive: Bool) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: InteractiveRegionPreferenceKey.self,
                    value: isActive ? proxy.frame(in: .rootOverlayCanvas) : nil
                )
            }
        )
    }
}

// MARK: - Card type button
//
// Mirrors BattlegroundsMinionTypeButton.xaml: a circular tribe portrait ringed
// by a thin grey gradient, a gold glow ring when active or hovered, a tier-x
// overlay previewing deselection, and a small name plate overhanging the bottom.
@available(macOS 10.15, *)
struct BattlegroundsMinionTypeButton: View {
    let button: BattlegroundsMinionsViewModel.MinionTypeButton
    let action: () -> Void

    @SwiftUI.State private var isHovering = false

    // Width/Height="{Binding Size}" with Size = 34 for every type button.
    private static let size: CGFloat = 34
    // Border Height="12" Margin="0,0,0,-3": the plate overhangs the circle.
    private static let plateHeight: CGFloat = 12
    private static let plateOverhang: CGFloat = 3

    // Mirrors the XAML's IconOpacity. `Available` is dropped: HDT derives it
    // from the very list it is building (`races.Contains(x)`), so it is always
    // true — the unavailable-type branch there is unreachable.
    private var iconOpacity: Double {
        if button.isActive { return 1 }
        if button.isFaded && !isHovering { return 0.3 }
        return 1
    }

    var body: some View {
        Button(action: action) {
            // Border Height="12" Margin="0,0,0,-3" VerticalAlignment="Bottom":
            // the plate is bottom-aligned *over* the icon and hangs 3pt past it,
            // so the button occupies 34 + 3 = 37pt and fits the 40pt cell.
            //
            // Stacking icon and plate in a VStack instead made the button 43pt
            // tall (34 + 12 - 3), overflowing the cell and letting each row's
            // plates collide with the icons of the row below.
            ZStack(alignment: .bottom) {
                ZStack {
                    portrait
                    ring.opacity(iconOpacity)
                    if button.isActive || isHovering {
                        glowRing.opacity(button.isActive ? 1 : 0.5)
                    }
                    // Hovering the already-selected type previews a deselect,
                    // the same affordance the tier badges use.
                    if button.isActive && isHovering, let tierX = MinionsFilterImages.tierX {
                        Image(nsImage: tierX)
                            .resizable()
                            .frame(width: Self.size, height: Self.size)
                    }
                }
                .frame(width: Self.size, height: Self.size)

                namePlate
                    .offset(y: Self.plateOverhang)
            }
            .frame(width: Self.size, height: Self.size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
    }

    // Ellipse.Fill = ImageBrush clipped to a circle, scaled 1.1 about a centre
    // below the icon — which nudges the art up slightly as it grows.
    private var portrait: some View {
        Image(button.minionType.iconName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: Self.size, height: Self.size)
            .scaleEffect(1.1)
            .offset(y: -1.8)
            .clipShape(Circle())
            .opacity(iconOpacity)
    }

    // RadialGradientBrush: transparent out to 0.85, a thin #4A5256 band from
    // 0.86 to 0.92, transparent again past 0.93.
    private var ring: some View {
        Circle().fill(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.85),
                    .init(color: Color(hex: "#4A5256"), location: 0.86),
                    .init(color: Color(hex: "#4A5256"), location: 0.92),
                    .init(color: .clear, location: 0.93),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: Self.size / 2
            )
        )
        .frame(width: Self.size, height: Self.size)
    }

    // The active/hover gold ring, plus the XAML's DropShadowEffect (colour
    // #f6f601, BlurRadius 5, ShadowDepth 0) as a matching SwiftUI shadow.
    private var glowRing: some View {
        Circle().fill(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.89),
                    .init(color: Color(hex: "#f6f601"), location: 0.92),
                    .init(color: Color(hex: "#cdcb08"), location: 0.95),
                    .init(color: Color(hex: "#cdcb08"), location: 0.97),
                    .init(color: Color(hex: "#f6f601"), location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: Self.size / 2
            )
        )
        .frame(width: Self.size, height: Self.size)
        .shadow(color: Color(hex: "#f6f601"), radius: 2.5)
    }

    // Two stacked Borders in the XAML: an opaque #23272a plate so the circle
    // never shows through, and the bordered #141617 label on top of it, which
    // is the one that fades with IconOpacity.
    private var namePlate: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "#23272a"))
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "#141617"))
                .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color(hex: "#4A5256"), lineWidth: 1))
                .overlay(
                    // Viewbox Stretch="Uniform" StretchDirection="DownOnly":
                    // long type names shrink to fit, short ones stay at 10pt.
                    Text(button.minionType.buttonLabel)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#dcddde"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 2)
                )
                .opacity(iconOpacity)
        }
        .frame(width: BattlegroundsMinionTypeButton.size, height: Self.plateHeight)
    }
}

// MARK: - Mechanic button
//
// Mirrors the Button ControlTemplate in BattlegroundsMinionsExtraFilters.xaml:
// a 30pt row with a #3f4346 top border, centred bold 11pt label, and — when
// active — a #36393f fill, #ffffcc text, and a chevron pointing in from each side.
@available(macOS 10.15, *)
struct MinionsKeywordButton: View {
    let button: BattlegroundsMinionsViewModel.KeywordButton
    let action: () -> Void

    @SwiftUI.State private var isHovering = false

    private static let height: CGFloat = 30

    var body: some View {
        Button(action: action) {
            ZStack {
                background
                Text(button.keyword.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(button.isActive ? Color(hex: "#ffffcc") : Color(hex: "#dcddde"))
                    .lineLimit(1)
                if button.isActive {
                    selectionChevrons
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .overlay(
                Rectangle().frame(height: 1).foregroundColor(Color(hex: "#3f4346")),
                alignment: .top
            )
            .contentShape(Rectangle())
            // MultiDataTrigger Active + IsMouseOver: the whole row dims, which
            // reads as "click again to clear".
            .opacity(button.isActive && isHovering ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
    }

    @ViewBuilder
    private var background: some View {
        if button.isActive {
            Color(hex: "#36393f")
        } else if isHovering {
            Color(hex: "#2C3135")
        } else {
            Color.clear
        }
    }

    // Path Data="M 0,14 L 7,7 L 0,0 Z" on the left and its mirror on the right,
    // both 7x14 and vertically centred.
    private var selectionChevrons: some View {
        HStack(spacing: 0) {
            Triangle(pointingRight: true)
                .fill(Color(hex: "#ffffcc"))
                .frame(width: 7, height: 14)
            Spacer(minLength: 0)
            Triangle(pointingRight: false)
                .fill(Color(hex: "#ffffcc"))
                .frame(width: 7, height: 14)
        }
        .opacity(isHovering ? 0.3 : 1)
    }
}

@available(macOS 10.15, *)
private struct Triangle: Shape {
    let pointingRight: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointingRight {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Slide-out filter button
//
// Mirrors the "Extra Filters Button" Grid in BattlegroundsMinions.xaml: a tab
// that slides out past the left edge of the tier strip whenever a type or
// keyword filter is set, the filter region is hovered, or the panel is open.
//
// HDT animates the tab's Width 10 → 48 together with a TranslateTransform of
// 0 → -41, which keeps its right edge pinned just inside the panel while the
// body grows leftwards. Since the tab is invisible in its collapsed state, the
// same motion is expressed here as one offset on a fixed-width tab.
@available(macOS 10.15, *)
struct MinionsExtraFiltersButton: View {
    @ObservedObject var viewModel: BattlegroundsMinionsViewModel
    /// HDT's IsStandAloneMode - see the DataTriggers on this tab's Border style.
    var isStandAlone = false

    @SwiftUI.State private var isHovering = false

    // Border Width (expanded) ="48", Padding="6,0,0,0". HDT also fixes
    // Height="58" against a 57pt strip; here the tab instead stretches to
    // whatever the tier strip actually measures (see the frame below).
    private static let tabWidth: CGFloat = 48
    private static let expandedOffset: CGFloat = -41
    // How much of the tab ends up on top of the panel once it slides out. The
    // backgrounds match there, so the overlap is invisible - but the tab's top
    // border is not, hence topTrailingInset on TabBorder below.
    private static let panelOverlap: CGFloat = tabWidth + expandedOffset
    private static let buttonSize: CGFloat = 32
    // Rectangle Height="8" Width="14" masked with the bar_filter visual.
    private static let iconSize = CGSize(width: 14, height: 8)

    private var isVisible: Bool { viewModel.isFilterButtonVisible }

    var body: some View {
        HStack(spacing: 0) {
            filterButton
            Spacer(minLength: 0)
        }
        .padding(.leading, 6)
        // Height comes from the tier strip this is overlaid on, rather than a
        // constant. A fixed 58 was 4pt taller than the strip actually renders
        // (a 36pt badge inside 9pt padding = 54), so the tab hung below the
        // strip's bottom edge and its 32pt button - centred in 58, not 54 -
        // sat 2pt lower than the tier badges beside it.
        .frame(width: Self.tabWidth)
        .frame(maxHeight: .infinity)
        // Stand-alone flattens the tab the same way it flattens the tier strip:
        // #141617 fill, no corner radius, and BorderThickness "1,0,0,0" - the
        // left edge only, with the top and bottom dropped.
        .background(Color(hex: isStandAlone ? "#141617" : "#23272A"))
        .overlay(tabBorder)
        // Ahead of the offset below - see reportInteractiveRegion.
        .reportInteractiveRegion(when: isVisible)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? Self.expandedOffset : 0)
        // Collapsed the tab sits under the panel, where it must not swallow
        // clicks meant for the tier strip.
        .allowsHitTesting(isVisible)
    }

    @ViewBuilder
    private var tabBorder: some View {
        if isStandAlone {
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(hex: "#3f4346"))
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            TabBorder(topTrailingInset: Self.panelOverlap).stroke(Color(hex: "#3f4346"), lineWidth: 1)
        }
    }

    private var filterButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleFilters()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(buttonBackground)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3f4346"), lineWidth: 1))

                Image("icon-bar-filter")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.iconSize.width, height: Self.iconSize.height)

                // The gold "a filter is set" ring, drawn over the button rather
                // than replacing its border (BorderThickness="1.5" in the XAML).
                if viewModel.isExtraFilterSelected {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#f6f601"), Color(hex: "#cdcb08")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .shadow(color: Color(hex: "#f6f601"), radius: 2.5)
                }
            }
            .frame(width: Self.buttonSize, height: Self.buttonSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Storyboard on IsFilterButtonVisible: opacity 0 → 1 and a 0.25 → 0.9
        // scale, so the button pops in slightly after the tab starts extending.
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 0.9 : 0.25)
        .onHover { hovering in isHovering = hovering }
    }

    // Hover and open states are shared; only the idle fill differs, since
    // #141617 would vanish into the stand-alone tab behind it.
    private var buttonBackground: Color {
        if viewModel.isFiltersOpen { return Color(hex: "#36393f") }
        if isHovering { return Color(hex: "#2C3135") }
        return Color(hex: isStandAlone ? "#202325" : "#141617")
    }
}

// BorderThickness="1,1,0,1" CornerRadius="0,0,0,3": the tab is open on its
// right edge, where it meets the panel, and rounded only at the bottom left.
@available(macOS 10.15, *)
private struct TabBorder: Shape {
    // Stops the *top* stroke short of the trailing edge by the width of the
    // tab's overlap with the panel. The tier strip has no top border of its own
    // (BorderThickness="1,0,0,1"), so running this one to maxX drew a stray lit
    // segment across the strip past the panel edge.
    //
    // The bottom stroke deliberately does run the full width. The strip's own
    // bottom border is the same #3f4346, and it curves up into a rounded corner
    // over the tab's last few points - so stopping the tab's bottom stroke at
    // the panel edge left a notch where neither border covered the join.
    // Running it through to maxX bridges that corner and meets the strip's
    // bottom border on its straight section.
    let topTrailingInset: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 3
        // Inset by half the line width, matching TierStripBorder - without it
        // the two bottom borders sit half a point apart vertically and the join
        // reads as a step.
        let left = rect.minX + 0.5
        let top = rect.minY + 0.5
        let bottom = rect.maxY - 0.5
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX - topTrailingInset, y: top))
        path.addLine(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: left, y: bottom - radius))
        path.addQuadCurve(
            to: CGPoint(x: left + radius, y: bottom),
            control: CGPoint(x: left, y: bottom)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: bottom))
        return path
    }
}

// Shared one-off images for the filter controls, loaded from
// Resources/Battlegrounds rather than the asset catalog (same as the tier
// badges in BattlegroundsMinionsView).
enum MinionsFilterImages {
    static let tierX: NSImage? = {
        guard let rp = Bundle.main.resourcePath else { return nil }
        return NSImage(contentsOfFile: "\(rp)/Resources/Battlegrounds/tier-x.png")
    }()
}
