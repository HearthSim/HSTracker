//
//  BattlegroundsMinionPinningView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsMinionPinning.xaml: the "Tavern Pinning" panel in
// the overlay's bottom-right corner, plus the two 55x54.2 buttons docked below
// it (toggle the key-piece recommendations, collapse/expand the panel) and the
// hover-only explainer popups that open to their left.
//
// Everything here is authored at the 1080-tall reference and anchored
// bottom-trailing, matching the XAML: HDT puts the control in a canvas-sized
// Grid with a LayoutTransform of Height/1080, which is exactly what
// RootOverlayView's scaled subtree already provides.
@available(macOS 10.15, *)
struct BattlegroundsMinionPinningView: View {
    @ObservedObject var viewModel: BattlegroundsMinionPinningViewModel
    let canvasWidth: CGFloat

    // Border Width="249" - the same width as the guides panel opposite it.
    private static let panelWidth: CGFloat = 249
    // Margin="0,0,0,53" on the panel, so it clears the button row below.
    private static let panelBottomInset: CGFloat = 53
    // Button Width="55" Height="54.2", right-inset by 194 (expand) and 248
    // (recommend) - the expand button lines up with the panel's left edge
    // (194 + 55 = 249) and the recommend button sits immediately left of it.
    private static let buttonWidth: CGFloat = 55
    private static let buttonHeight: CGFloat = 54.2
    private static let expandButtonInset: CGFloat = 194
    private static let recommendButtonInset: CGFloat = 248

    var body: some View {
        if viewModel.isShown {
            ZStack(alignment: .bottomTrailing) {
                Color.clear

                // The panel and its two buttons: one hit-testable region,
                // matching the single OverlayExtensions.IsOverlayHitTestVisible
                // on the outer Border in the XAML.
                ZStack(alignment: .bottomTrailing) {
                    if viewModel.isExpanded {
                        panel
                            .padding(.bottom, Self.panelBottomInset)
                    }
                    recommendButton
                        .padding(.trailing, Self.recommendButtonInset)
                    expandButton
                        .padding(.trailing, Self.expandButtonInset)
                }
                .reportInteractiveRegion(when: true)
                // Panel_MouseEnter / Panel_MouseLeave: the help and settings
                // buttons in the header only appear while the cursor is on the
                // panel. HDT hooks this on the panel Border itself; hooking the
                // whole cluster keeps them up while the cursor crosses to the
                // buttons below.
                .onHover { hovering in viewModel.isCogVisible = hovering }

                // Sibling of the panel in HDT's root Grid, at Margin="0,0,257,54"
                // - clear of both the panel's left edge and the button row.
                compGuidesMarkerSection
                    .padding(.trailing, 257)
                    .padding(.bottom, 54)
                    .reportInteractiveRegion(when: viewModel.isCompGuidesMarkerPanelVisible)
            }
            .frame(width: canvasWidth, height: 1080)
        }
    }

    // MARK: - Panel

    private var panel: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 0) {
                if !viewModel.quickGuideDismissed {
                    quickGuide
                        .padding(.bottom, 8)
                }
                minionTypesBox
                pinnedGrid
            }
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
        .frame(width: Self.panelWidth)
        .background(Color(hex: "#23272A"))
        .overlay(
            RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3f4346"), lineWidth: 1)
        )
        // CornerRadius="3,0,0,0": only the top-left corner is rounded, the
        // panel runs flush off the right edge of the screen.
        .cornerRadius(3, corners: [.topLeft])
    }

    // Border Background="#1C2022" with a #4A5256 bottom edge and
    // Padding="8,0,0,0"; the title's own Margin is "6,6,0,6".
    private var header: some View {
        HStack(spacing: 0) {
            Image("tier7-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14)
            Text(String.localizedString("Tavern Pinning", comment: ""))
                .chunkFive(size: 11)
                .outlinedText()
                .padding(.leading, 6)
                .padding(.vertical, 6)
            Spacer(minLength: 0)
            headerTrailing
        }
        .padding(.leading, 8)
        .background(Color(hex: "#1C2022"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
        .cornerRadius(3, corners: [.topLeft])
    }

    // The tag and the button pair share one slot: HDT shows the "Tier7 Feature"
    // tag only while the cursor is away (CogBtnVisibility == Hidden) and the
    // user is not a Tier7 subscriber, and swaps in the help/settings buttons on
    // hover.
    @ViewBuilder
    private var headerTrailing: some View {
        if viewModel.isCogVisible {
            HStack(spacing: 0) {
                HeaderIconButton(action: { viewModel.toggleQuickGuide() }) { helpGlyph }
                HeaderIconButton(action: {
                    // MouseBinding Command="commands:GlobalCommands.ShowSettings"
                    // CommandParameter="Battlegrounds".
                    AppDelegate.instance().openPreferences(pane: .battlegrounds)
                }) { settingsGlyph }
            }
        } else if viewModel.isOnTrial {
            Text(String.localizedString("Tier7 Feature", comment: ""))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "#FFB00D"))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .padding(4)
        }
    }

    // HDT draws appbar_question and appbar_settings from its own icon resource
    // dictionary. HSTracker ships neither, and SF Symbols need macOS 11 while
    // this module's baseline is 10.15 - so the help glyph is drawn as text and
    // the cog uses AppKit's own gear template image.
    private var helpGlyph: some View {
        Text(verbatim: "?")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 12, height: 14)
    }

    @ViewBuilder
    private var settingsGlyph: some View {
        if let gear = NSImage(named: NSImage.actionTemplateName) {
            Image(nsImage: gear)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(width: 14, height: 14)
        }
    }

    // MARK: - Quick guide

    // Border Background="#141617" CornerRadius="3" Padding="8", shown until the
    // user dismisses it (or re-armed from the Battlegrounds settings pane).
    private var quickGuide: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String.localizedString("Quick Guide", comment: ""))
                .chunkFive(size: 13)
                .outlinedText()
                .padding(.bottom, 8)

            Text(String.localizedString("Ever accidentally rolled past that minion you were looking for?", comment: ""))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            separator

            Text(String.localizedString("In the Tavern", comment: ""))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            // The three marker styles, labelled in place over a screenshot of
            // a shop minion. Label positions are the XAML's own margins.
            exampleImage("minion-example", height: 121)
                .overlay(
                    ZStack(alignment: .topLeading) {
                        Color.clear
                        exampleLabel("Manual Pin", x: 80, y: 22)
                        exampleLabel("Minion Type Pin", x: 87, y: 41)
                        exampleLabel("Key Piece Pin", x: 89, y: 61)
                    }
                )

            separator

            Text(String.localizedString("Pin cards from:", comment: ""))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            bulletText("● The Minion Browser")
            exampleImage("browser-pin-example", height: 123)
                .padding(.top, 4)
                .padding(.bottom, 8)

            bulletText("● Comp Guides")
            exampleImage("comp-pin-example", height: 108)
                .padding(.top, 4)
                .padding(.bottom, 8)

            bulletText("● Or pin entire minion types below")

            gotItButton { viewModel.dismissGuide() }
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(8)
        .background(Color(hex: "#141617"))
        .cornerRadius(3)
    }

    // Separator Margin="0,8" Height="3" Background="#4A5256".
    private var separator: some View {
        Rectangle()
            .fill(Color(hex: "#4A5256"))
            .frame(height: 3)
            .padding(.vertical, 8)
    }

    private func bulletText(_ text: String) -> some View {
        Text(String.localizedString(text, comment: ""))
            .font(.system(size: 11))
            .foregroundColor(.white)
            .opacity(0.8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Border BorderBrush="#3f4346" BorderThickness="1" CornerRadius="3" at a
    // fixed height, centred, holding the screenshot Stretch="Uniform".
    //
    // HDT's Border is HorizontalAlignment="Center" and hugs a Grid sized by a
    // hidden Stretch="Uniform" Image, so the border tracks the art's natural
    // width at the given height. Every one of these heights was picked to make
    // that width fill the row: 121 x 1.794 = 217, 123 x 1.771 = 218,
    // 108 x 2.013 = 217, and 181 x 0.918 = 166 in the 200pt popup.
    //
    // Here the border stretches to the full row instead and the art letterboxes
    // inside it. That lands closer to HDT than it sounds: WPF's
    // BorderThickness="1" insets its content, leaving HDT 215pt of usable width
    // (so its 217pt-wide art actually overhangs by ~1pt a side), while a SwiftUI
    // .overlay(stroke) paints over the content without insetting it, leaving
    // 217pt here - measured, not derived. The art therefore fills this row to
    // within half a point, and unlike HDT's it can never overhang the panel.
    private func exampleImage(_ name: String, height: CGFloat) -> some View {
        Group {
            if let image = MinionPinningImages.guideExample(name) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3f4346"), lineWidth: 1))
        .cornerRadius(3)
    }

    private func exampleLabel(_ text: String, x: CGFloat, y: CGFloat) -> some View {
        Text(String.localizedString(text, comment: ""))
            .chunkFive(size: 12)
            .outlinedText()
            .offset(x: x, y: y)
    }

    // The shared "Got it" button: Padding="16,6" on #4A5256 (#5A6266 on hover),
    // CornerRadius 3, 11pt SemiBold.
    private func gotItButton(action: @escaping () -> Void) -> some View {
        PinningTextButton(
            title: String.localizedString("Got it", comment: ""),
            background: "#4A5256",
            hoverBackground: "#5A6266",
            fontSize: 11,
            weight: .semibold,
            horizontalPadding: 16,
            verticalPadding: 6,
            action: action
        )
    }

    // MARK: - Minion type pins

    // Border Background="#2E3235" CornerRadius="3" Padding="4" Margin="0,0,0,4"
    // over a WrapPanel with ItemWidth="42" ItemHeight="40". The panel's 231pt of
    // inner width leaves room for exactly five 42pt cells.
    private var minionTypesBox: some View {
        let buttons = viewModel.minionTypeButtons
        let columns = 5
        let rows = stride(from: 0, to: buttons.count, by: columns).map { start in
            Array(buttons[start ..< min(start + columns, buttons.count)])
        }
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(row) { button in
                        BattlegroundsMinionTypeButton(button: button) {
                            viewModel.toggleMinionType(button.minionType)
                        }
                        .frame(width: 42, height: 40)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(4)
        .background(Color(hex: "#2E3235"))
        .cornerRadius(3)
        .padding(.bottom, 4)
    }

    // MARK: - Pinned cards

    // UniformGrid Columns="5" with a 2,4,2,4 margin around each 42x42 cell, and
    // the "No cards pinned" label floating over it (Panel.ZIndex="100") while
    // nothing is pinned.
    private var pinnedGrid: some View {
        let slots = viewModel.pinnedSlots
        let columns = 5
        let rows = stride(from: 0, to: slots.count, by: columns).map { start in
            Array(slots[start ..< min(start + columns, slots.count)])
        }
        return ZStack {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(row) { slot in
                            PinnedSlotView(slot: slot) {
                                viewModel.activatePinnedSlot(slot)
                            }
                            .padding(.horizontal, 2)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if !viewModel.hasPins {
                Text(String.localizedString("No cards pinned", comment: ""))
                    .chunkFive(size: 11)
                    .outlinedText()
                    .opacity(0.75)
            }
        }
    }

    // MARK: - Footer buttons

    // Button Command="{Binding ToggleRecommendedCommand}" Margin="0,0,248,0"
    // BorderThickness="1,1,0,0" - no right edge, since the expand button's own
    // left edge sits against it.
    private var recommendButton: some View {
        PinningFooterButton(
            background: "#141617",
            hoverBackground: "#2C3135",
            edges: [.top, .leading, .trailing],
            action: { viewModel.toggleRecommended() }
        ) {
            ZStack {
                Group {
                    if let key = MinionPinningImages.key {
                        Image(nsImage: key)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                    }
                }
                .opacity(viewModel.enableRecommended ? 1 : 0.7)

                Text(viewModel.enableRecommended ? "ON" : "OFF")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color(hex: viewModel.enableRecommended ? "#4CAF50" : "#FF5252"))
                    .cornerRadius(3)
                    .opacity(0.8)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 6)
            }
        }
        // RecommendComp_MouseEnter / _MouseLeave on this button and on the
        // explainer panel itself, so moving between the two keeps it open.
        .onHover { hovering in viewModel.setRecommendCompHovered(hovering) }
    }

    // The expand toggle. Expanded it takes the panel's own #23272A and loses
    // its bottom-left/right edges so it reads as part of the panel; collapsed it
    // matches the recommend button.
    private var expandButton: some View {
        PinningFooterButton(
            background: viewModel.isExpanded ? "#23272A" : "#141617",
            hoverBackground: "#2C3135",
            edges: viewModel.isExpanded ? [.leading, .trailing] : [.top, .leading, .trailing],
            action: { viewModel.isExpanded.toggle() }
        ) {
            Group {
                if let pin = MinionPinningImages.pin {
                    Image(nsImage: pin)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                }
            }
        }
    }

    // MARK: - Explainer popups

    // Mirrors the "Comp Guides Marker Section" Border: a 200pt column holding
    // the "Key Comp Pieces" quick guide and the auto-enable prompt, either of
    // which can be up on its own.
    @ViewBuilder
    private var compGuidesMarkerSection: some View {
        if viewModel.isCompGuidesMarkerPanelVisible {
            VStack(spacing: 0) {
                if viewModel.isQuickCompGuideVisible {
                    keyPiecesQuickGuide
                        .padding(.bottom, 8)
                }
                if viewModel.isAutoEnableMessageVisible {
                    autoEnablePopup
                        .padding(.bottom, 8)
                }
            }
            .frame(width: 200)
            // Background="#01000000": a nearly-transparent fill so the whole
            // column, gaps included, still takes hover.
            .background(Color.black.opacity(0.004))
            .onHover { hovering in viewModel.setRecommendCompHovered(hovering) }
        }
    }

    private var keyPiecesQuickGuide: some View {
        VStack(spacing: 0) {
            popupHeader(String.localizedString("Key Comp Pieces", comment: ""))
            if !viewModel.compGuidesMarkerQuickGuideDismissed {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String.localizedString("Quick Guide", comment: ""))
                        .chunkFive(size: 13)
                        .outlinedText()
                        .padding(.bottom, 6)

                    Text(String.localizedString("Automatically pin cards which are key pieces for comps available in the current lobby. These are based on “Enablers” and “When to commit” from our comp guides.", comment: ""))
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .opacity(0.8)
                        .fixedSize(horizontal: false, vertical: true)

                    exampleImage("comp-recommendation-example-guide", height: 181)
                        .padding(.vertical, 12)

                    gotItButton { viewModel.dismissCompGuidesMarkerQuickGuide() }
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(8)
                .background(Color(hex: "#141617"))
                .cornerRadius(3)
                .padding(8)
            }
        }
        .background(Color(hex: "#23272A"))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3f4346"), lineWidth: 1))
        .cornerRadius(3)
    }

    private var autoEnablePopup: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Text(String.localizedString("Enable Key Comp Pieces when a new game starts?", comment: ""))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .opacity(0.8)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)

                HStack(spacing: 8) {
                    PinningTextButton(title: "NO", background: "#4A5256", hoverBackground: "#5A6266",
                                      fontSize: 10, weight: .bold,
                                      horizontalPadding: 16, verticalPadding: 4) {
                        viewModel.answerAutoEnable(false)
                    }
                    PinningTextButton(title: "YES", background: "#CC4CAF50", hoverBackground: "#5CB860",
                                      fontSize: 10, weight: .semibold,
                                      horizontalPadding: 16, verticalPadding: 4) {
                        viewModel.answerAutoEnable(true)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#141617"))
            .cornerRadius(3)

            Text(String.localizedString("This behavior can be changed any time in the settings.", comment: ""))
                .font(.system(size: 10, weight: .semibold))
                .italic()
                .foregroundColor(.white)
                .opacity(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
        }
        .padding(8)
        .background(Color(hex: "#23272A"))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3f4346"), lineWidth: 1))
        .cornerRadius(3)
    }

    // The popups' own title bar, same recipe as the panel header but rounded on
    // both top corners (CornerRadius="3,3,0,0") since they float free.
    private func popupHeader(_ title: String) -> some View {
        HStack(spacing: 0) {
            Image("tier7-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14)
            Text(title)
                .chunkFive(size: 11)
                .outlinedText()
                .padding(.leading, 6)
                .padding(.vertical, 6)
            Spacer(minLength: 0)
        }
        .padding(.leading, 8)
        .background(Color(hex: "#1C2022"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
        .cornerRadius(3, corners: [.topLeft, .topRight])
    }
}

// MARK: - Pinned slot cell

// The DataTemplate on the PinnedSlots ItemsControl: a 42x42 rounded cell that
// is either a pinned card (portrait art, tier badge, an "unpin" X on hover) or
// the Clear button that ends the list.
@available(macOS 10.15, *)
private struct PinnedSlotView: View {
    let slot: BattlegroundsMinionPinningViewModel.PinnedSlot
    let action: () -> Void

    @SwiftUI.State private var isHovering = false
    @SwiftUI.State private var art: NSImage?

    private static let size: CGFloat = 42

    var body: some View {
        Button(action: action) {
            ZStack {
                if slot.isClearButton {
                    clearContent
                } else {
                    cardContent
                }
            }
            .frame(width: Self.size, height: Self.size)
            .background(Color(hex: slot.isClearButton ? "#2E3235" : "#1e2124"))
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(hex: isHovering ? "#22FFFFFF" : "#141617"), lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
        .onAppear(perform: loadArt)
    }

    // Image Stretch="UniformToFill" Width/Height 80 pulled up by 10 inside the
    // 42pt cell, so the portrait's face rather than its centre shows.
    @ViewBuilder
    private var cardContent: some View {
        ZStack {
            if let art {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .offset(y: -10)
                    .frame(width: Self.size, height: Self.size, alignment: .top)
                    .clipped()
            }

            if slot.hasCard {
                // Viewbox Width/Height 21 Margin="0,-8,0,0" at the top: the tier
                // badge overhangs the cell's top edge.
                MinionsViewTierBadge(tier: slot.tier, badgeSize: 21)
                    .opacity(0.95)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: -8)

                // Hovering a pinned card previews the unpin, the same tier-x
                // affordance the browser's tier badges use.
                if isHovering, let tierX = MinionsFilterImages.tierX {
                    Image(nsImage: tierX)
                        .resizable()
                        .frame(width: Self.size, height: Self.size)
                }
            }
        }
        .frame(width: Self.size, height: Self.size)
    }

    private var clearContent: some View {
        ZStack {
            if let tierX = MinionsFilterImages.tierX {
                Image(nsImage: tierX)
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            Text(String.localizedString("Clear", comment: ""))
                .chunkFive(size: 10)
                .outlinedText()
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 2)
        }
        .opacity(0.8)
        .frame(width: Self.size, height: Self.size)
    }

    private func loadArt() {
        guard let cardId = slot.cardId else { return }
        if let cached = ImageUtils.cachedArt(cardId: cardId) {
            art = cached
            return
        }
        ImageUtils.art(for: cardId) { img in
            DispatchQueue.main.async { self.art = img }
        }
    }
}

// MARK: - Shared button chrome

// The 55x54.2 footer buttons: #141617 going to #2C3135 on hover, with a
// #3f4346 border on only some edges so the pair reads as one strip attached to
// the panel (BorderThickness="1,1,1,0" / "1,1,0,0" / "1,0,1,0" in the XAML).
@available(macOS 10.15, *)
private struct PinningFooterButton<Content: View>: View {
    let background: String
    let hoverBackground: String
    let edges: Edge.Set
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: action) {
            content()
                .frame(width: 55, height: 54.2)
                .background(Color(hex: isHovering ? hoverBackground : background))
                .overlay(borderOverlay)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
    }

    private var borderOverlay: some View {
        ZStack {
            if edges.contains(.top) {
                Rectangle().frame(height: 1).foregroundColor(Color(hex: "#3f4346"))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            if edges.contains(.leading) {
                Rectangle().frame(width: 1).foregroundColor(Color(hex: "#3f4346"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if edges.contains(.trailing) {
                Rectangle().frame(width: 1).foregroundColor(Color(hex: "#3f4346"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// The rounded pill buttons the popups use ("Got it", "YES", "NO").
@available(macOS 10.15, *)
private struct PinningTextButton: View {
    let title: String
    let background: String
    let hoverBackground: String
    let fontSize: CGFloat
    let weight: Font.Weight
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let action: () -> Void

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: weight))
                .foregroundColor(.white)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(Color(hex: isHovering ? hoverBackground : background))
                .cornerRadius(3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
    }
}

// Border Name="BtnHelp"/"BtnOptions": 18x18, CornerRadius 3, transparent until
// hovered (#22FFFFFF), Margin="4".
@available(macOS 10.15, *)
private struct HeaderIconButton<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @SwiftUI.State private var isHovering = false

    var body: some View {
        Button(action: action) {
            content()
                .frame(width: 18, height: 18)
                .background(Color.white.opacity(isHovering ? 0.13 : 0))
                .cornerRadius(3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(4)
        .onHover { hovering in isHovering = hovering }
    }
}
