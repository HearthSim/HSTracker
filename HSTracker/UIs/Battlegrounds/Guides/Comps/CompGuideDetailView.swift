//
//  CompGuideDetailView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's CompGuide.xaml.
@available(macOS 10.15, *)
struct CompGuideDetailView: View {
    @ObservedObject var viewModel: BattlegroundsCompsGuidesViewModel
    let comp: BattlegroundsCompGuideViewModel
    @ObservedObject var pinning: BattlegroundsMinionPinningViewModel

    @SwiftUI.State private var isInspirationHovering = false
    @SwiftUI.State private var isHeaderHovering = false
    @SwiftUI.State private var isPinButtonHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            backButton
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if !comp.howToPlay.isEmpty {
                                howToPlaySection
                            }
                            if !comp.coreCards.isEmpty {
                                cardSection(title: "Core Cards", minions: comp.coreCards, showInspirationButton: true)
                            }
                            if !comp.addonCards.isEmpty {
                                cardSection(title: "Addon Cards", minions: comp.addonCards, showInspirationButton: false)
                            }
                            if !comp.whenToCommitLines.isEmpty {
                                pillSection(title: "When to Commit", lines: comp.whenToCommitLines)
                            }
                            if !comp.commonEnablerLines.isEmpty {
                                pillSection(title: "Common Enablers", lines: comp.commonEnablerLines)
                            }
                        }
                    }
                    .background(Color(hex: "#2e3235"))
                }
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#4F565B"), lineWidth: 1))
                .cornerRadius(3)
                .background(Color(hex: "#292d30"))

                footer
            }
        }
        .padding(9)
        .background(Color(hex: "#292d30"))
    }

    private var backButton: some View {
        Button {
            viewModel.selectedComp = nil
        } label: {
            HStack(spacing: 5) {
                Text("\u{2039}")
                    .font(.system(size: 12, weight: .bold))
                Text("All Comp Guides")
                    .font(.system(size: 10))
            }
            .foregroundColor(.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 30, alignment: .leading)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(comp.compGuide.name)
                .chunkFive(size: 13)
                .outlinedText()
                .lineLimit(1)
                // Without this, the Text's reported ideal width comes from
                // .outlinedText()'s internal ZStack (which stacks 9 offset
                // copies for the outline effect) rather than negotiating
                // directly with the Spacer below the way a bare Text would -
                // it was truncating well short of the space actually
                // available, leaving a visible gap before the pin/tier badge.
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            pinAllButton

            tierBadge(text: comp.tierText, colors: comp.tierColors)
        }
        // Grid_OnMouseEnter / Grid_OnMouseLeave on the header: the pin button
        // springs in on hover, and stays put once everything is pinned.
        .trackHover { hovering in
            withAnimation(Self.pinButtonAnimation(hovering)) {
                isHeaderHovering = hovering
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Matches HDT's CompGuide.xaml header: the comp's representative-
        // card art, faded, always visible (not hover-gated like the list
        // row), spanning the header's full width, with a bottom border and
        // rounded top corners matching the outer container's own radius.
        .background(GuideCardArtBackground(card: comp.representativeCard, opacity: 0.4, gradientEnd: 0.80))
        .background(Color(hex: "#141617"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .bottom)
        .cornerRadius(3, corners: [.topLeft, .topRight])
        .clipped()
    }

    // BtnPinAllCompCards: a 30x30 PinIconButtonStyle button carrying a 22pt
    // pin.png, Margin="0,0,6,0", wrapped in the same BgsMinionPinningVisibility
    // gate the browser's per-row button uses. #23272a idle, #43474a hovered,
    // and #141617 once every card in the guide is pinned.
    //
    // PinButtonIn / PinButtonUnpinned / PinButtonPinned: opacity 0->1 with a
    // 0.7->1 ElasticEase scale, held open while everything is pinned.
    private static func pinButtonAnimation(_ appearing: Bool) -> Animation {
        appearing ? .spring(response: 0.5, dampingFraction: 0.55).delay(0.1)
                  : .easeOut(duration: 0.2)
    }

    private var isAllPinned: Bool { comp.areAllCompCardsPinned(pinning) }
    private var isPinButtonShown: Bool { isAllPinned || isHeaderHovering || isPinButtonHovering }

    @ViewBuilder
    private var pinAllButton: some View {
        if pinning.isShown {
            Button {
                comp.togglePinAllCompCards(pinning)
            } label: {
                Group {
                    if let pin = MinionPinningImages.pin {
                        Image(nsImage: pin)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 22, height: 22)
                .frame(width: 30, height: 30)
                .background(Color(hex: pinBackgroundHex))
                .cornerRadius(3)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#141617"), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)
            .opacity(isPinButtonShown ? 1 : 0)
            .scaleEffect(isPinButtonShown ? 1 : 0.7)
            .allowsHitTesting(isPinButtonShown)
            .trackHover { hovering in
                withAnimation(Self.pinButtonAnimation(hovering)) {
                    isPinButtonHovering = hovering
                }
            }
        }
    }

    private var pinBackgroundHex: String {
        if isPinButtonHovering { return "#43474a" }
        return isAllPinned ? "#141617" : "#23272a"
    }

    private func badge(text: String, colors: [Color]) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(3)
    }

    // Matches HDT's CompGuide.xaml tier badge exactly - it's a distinct
    // style from the difficulty badge above (FontSize 12/FontWeight Black,
    // asymmetric 8,2,8,5 padding vs. the difficulty badge's 10/Bold and
    // uniform 8x4 padding), not a shared style.
    private func tierBadge(text: String, colors: [Color]) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black))
            .foregroundColor(.white)
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .padding(.top, 2)
            .padding(.bottom, 5)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(3)
    }

    private var howToPlaySection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("How to Play")
                    .chunkFive(size: 12)
                    .outlinedText()
                Spacer()
                badge(text: difficultyLabel(comp.difficulty), colors: [comp.difficultyColor, comp.difficultyColor])
            }
            // FontSize 11 / LineHeight 17 in CompGuide.xaml.
            GuideText(text: comp.howToPlay, fontSize: 11, color: .white.opacity(0.7), lineSpacing: 6)
        }
        .padding(9)
    }

    // Plain HStack rows rather than LazyVGrid: this module's baseline is
    // macOS 10.15 (LazyVGrid needs 11.0), and a comp's core/addon list is
    // short enough that laziness wouldn't matter anyway. HDT's own layout is
    // a WrapPanel (auto-flow, not a fixed column count), but at HDT's actual
    // BattlegroundsMinion size (70x70 - was wrongly 36x36 here, roughly half
    // HDT's real size) exactly 3 fit per row within this panel's width, so a
    // fixed 3-column chunk is a faithful stand-in without building a real
    // flow layout.
    private static let cardColumns = 3

    private func cardSection(title: String, minions: [BattlegroundsCompGuideViewModel.GuideMinion], showInspirationButton: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .chunkFive(size: 12)
                .outlinedText()
            VStack(alignment: .center, spacing: 10) {
                ForEach(Array(minions.chunks(Self.cardColumns).enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(row) { minion in
                            BattlegroundsMinionArtView(minion: minion)
                                .scaledToFrame(width: 70, height: 70)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            if showInspirationButton {
                inspirationButton
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#1c1f22"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .top)
    }

    // HDT's InspirationButtonStyle: bold 11pt on #F1C040 (#CCCCCC on hover) with
    // #26200F text, CornerRadius 3, 4pt of padding on both the Button and its
    // template Border, and a 14x14 black Tier7 logo 4pt before the label.
    //
    // Disabled - the account owns neither Tier7 nor an active trial - keeps
    // HDT's disabled trigger: background and foreground at 0.08/0.2 opacity.
    @ViewBuilder
    private var inspirationButton: some View {
        let enabled = comp.exampleBoardsButtonEnabled
        Button {
            showExampleLineups()
        } label: {
            HStack(spacing: 0) {
                Image("tier7-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    // LogoBrush="Black" on the button's Tier7Logo. colorMultiply
                    // rather than a template rendering mode - the asset is an SVG
                    // that is not marked as a template image.
                    .colorMultiply(enabled ? .black : .white)
                    .opacity(enabled ? 1 : 0.2)
                    .padding(.trailing, 4)
                    .padding(.bottom, -2)
                Text(BattlegroundsInspirationViewModel.localized("Battlegrounds_CompGuide_Inspiration_Button",
                                                                fallback: "Show Example Lineups"))
                    .font(.system(size: 11, weight: .bold))
                    // Only the background changes on hover in HDT.
                    .foregroundColor(enabled ? Color(hex: "#26200F") : .white.opacity(0.2))
            }
            .padding(8)
            .background(enabled
                        ? Color(hex: isInspirationHovering ? "#CCCCCC" : "#F1C040")
                        : Color.white.opacity(0.08))
            .cornerRadius(3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .trackHover { isInspirationHovering = $0 }
    }

    // ShowExampleBoardsCommand: the comp's core cards, narrowed to what this
    // lobby actually offers, keyed by the comp's own name rather than a minion's.
    private func showExampleLineups() {
        guard let inspiration = AppDelegate.instance().coreManager?.game
            .windowManager.rootOverlay?.viewModel.battlegroundsInspiration else { return }
        let cards = comp.coreCards.filter { $0.isAvailable }.map { $0.card }
        inspiration.setKeyMinion(title: comp.compGuide.name, cards: cards)
        inspiration.show()
    }

    private func pillSection(title: String, lines: [[GuideTextSegment]]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .chunkFive(size: 12)
                .outlinedText()
            VStack(spacing: 3) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, segments in
                    pill(segments)
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .top)
    }

    private func pill(_ segments: [GuideTextSegment]) -> some View {
        // GuideFlowParagraph (not a single concatenated Text) so each card
        // reference inside the pill gets its own CardTooltip on hover, per
        // ReferencedCardRun's style in CompGuide.xaml.
        GuideFlowParagraph(segments: segments, fontSize: 11, color: .white.opacity(0.8), alignment: .center)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.36))
            .cornerRadius(3)
    }

    private var footer: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Created by")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
                // Matches HDT's CompGuide.xaml exactly: a hardcoded author
                // name, not part of the API response.
                Text("JeefHS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            if let lastUpdatedText = comp.lastUpdatedText {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last updated")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.8))
                    Text(lastUpdatedText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(7)
        .background(Color(hex: "#141617"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#4A5256")), alignment: .top)
    }

    private func difficultyLabel(_ difficulty: Int) -> String {
        switch difficulty {
        case 1: return "Hard"
        case 2: return "Medium"
        case 3: return "Easy"
        default: return "Unknown"
        }
    }
}
