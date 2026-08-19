//
//  BattlegroundsCardsGroupView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Mirrors HDT's BattlegroundsCardsGroup UserControl: a bordered panel with a
// dark blue (#1d3657) header and a list of tracker-style card rows below.
// The outer border (1pt #141617, background #23272a) and 5pt top margin match
// the XAML's outer Border element exactly.
//
// Used from BattlegroundsMinionsView for every group (by-tier or by-tribe).
@available(macOS 10.15, *)
struct BattlegroundsCardsGroupView: View {
    let group: BattlegroundsMinionsViewModel.MinionGroup
    let onTribeSelected: ((Race) -> Void)?

    @SwiftUI.State private var isHeaderHovering = false

    // Mirrors BattlegroundsCardsGroup.HeaderCursor: header is clickable ("Hand")
    // only when viewing the tier mode (grouped by tribe) and the tribe is a real
    // filterable race — not spells (-1), not neutral/invalid.
    private var canFilterByTribe: Bool {
        !group.groupedByMinionType
            && group.minionType != -1
            && group.minionType != Race.lookup(.invalid)
            && Race(rawValue: group.minionType) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            groupHeader
            ForEach(Array(group.cards.enumerated()), id: \.offset) { _, card in
                MinionCardRow(card: card)
            }
        }
        .background(Color(hex: "#23272a"))
        .overlay(Rectangle().stroke(Color(hex: "#141617"), lineWidth: 1))
        .padding(.top, 5)
    }

    // MARK: - Group header

    // Matches BattlegroundsCardsGroup.xaml header Border:
    // Background=HeaderBackground (#1d3657), bottom border #141617.
    // Wrapped in a Button (not .onTapGesture) so it reliably fires inside
    // a ScrollView on macOS.
    private var groupHeader: some View {
        Button {
            if canFilterByTribe, let race = Race(rawValue: group.minionType) {
                onTribeSelected?(race)
            }
        } label: {
            ZStack(alignment: .trailing) {
                HStack(spacing: 0) {
                    Text(groupTitle)
                        .chunkFive(size: 14)
                        .outlinedText()
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Subtitle tab: shown in tribe mode (GroupedByMinionType=true) to
                // display the race name on the right edge of the header.
                if group.groupedByMinionType && !group.raceName.isEmpty {
                    subtitleBadge
                }

                // Drill-down filter icon: shown when the header can be tapped to
                // filter by this tribe (BattlegroundsCardsGroup.HeaderCursor="Hand").
                if canFilterByTribe {
                    Image("appbar_filter_white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .opacity(0.7)
                        .padding(.trailing, 5)
                }
            }
            .frame(height: 24)
            // Explicit maxWidth here (not just on the HStack above) - see
            // CompGuideRow's identical fix: without it, hover/click hit-testing
            // on macOS derives the Button's region from its label's own opaque
            // content rather than the full frame, leaving only a small area
            // (roughly the Text glyph) actually responsive.
            .frame(maxWidth: .infinity)
            .background(Color(hex: headerBackgroundHex))
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#141617")), alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // SwiftUI's .onHover on a Button only tracked roughly the top half of
        // this header vertically (a known SwiftUI-on-macOS hit-testing quirk
        // with Button + ZStack content) - trackHover uses a real AppKit
        // NSTrackingArea sized to the actual rendered bounds instead, matching
        // the fix already used for the minion-tile hover effect (see
        // CardImageTooltip.swift's HoverTrackingNSView).
        .trackHover { hovering in
            isHeaderHovering = hovering
        }
    }

    // Lighter blue on hover, but only while the header is actually clickable
    // (tribe mode) — matches HDT's hover trigger, which only fires when
    // GroupedByMinionType is false.
    private var headerBackgroundHex: String {
        isHeaderHovering && !group.groupedByMinionType ? "#24436c" : "#1d3657"
    }

    // Slanted subtitle panel — mirrors BattlegroundsCardsGroup.xaml's right-docked
    // DockPanel with a 15° RotateTransform on the left edge border and a TextBlock
    // showing SubTitle (localized race name, text only — no icon in HDT's XAML).
    private var subtitleBadge: some View {
        HStack(spacing: 0) {
            // Slanted left edge: a tall rectangle rotated 15° and clipped so only
            // the angled portion is visible, producing the diagonal seam.
            ZStack(alignment: .leading) {
                Color(hex: "#23272a")
                Color(hex: "#141617").frame(width: 1)
            }
            .frame(width: 20, height: 44)
            .rotationEffect(.degrees(15), anchor: .center)
            .frame(width: 12, height: 24)
            .clipped()

            // Race name text (SubTitle binding in XAML; no icon, matching HDT).
            Text(group.raceName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "#dcddde"))
                .lineLimit(1)
                .padding(.horizontal, 5)
                .frame(maxWidth: 70, minHeight: 20)
                .background(Color(hex: "#23272a"))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#141617")), alignment: .top)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    // Mirrors BattlegroundsCardsGroup.Title:
    //   GroupedByMinionType → "Tavern Tier N"
    //   minionType == -1    → localized "spells"
    //   minionType == INVALID → localized "neutral"
    //   otherwise           → localized race name
    private var groupTitle: String {
        if group.groupedByMinionType { return "Tavern Tier \(group.tier)" }
        if group.minionType == -1 { return String.localizedString("spells", comment: "") }
        if group.minionType == Race.lookup(.invalid) { return String.localizedString("neutral", comment: "") }
        return group.raceName
    }
}

// MARK: - Tracker-style card row (SwiftUI port of CardBar isBattlegrounds=true)
//
// Replicates CardBar.draw() visual at kRowHeight (34 pt), omitting the
// mana-cost gem (IsCostVisible = !Card.BaconCard = false for all BG cards).
// For battleground_spell cards, overlays the gold coin-cost badge on the right,
// matching CardTile.xaml's IsBaconSpell branch (DockPanel.Dock="Right" coin +
// HearthstoneTextBlock cost) and CardBar's addCoinCost() at coinRect(x=192).
//
// Layer order (matches CardBar.draw()):
//   1. Dark background
//   2. Tile art (imageRectBG = full width)
//   3. Fade overlay (fade.png from x=0)
//   4. Frame overlay (frame.png full width)
//   5. Card name (ChunkFive/Belwe, 15pt)
//   6. Spell coin badge (coin-cost.png + cost number, right-aligned; spells only)
@available(macOS 10.15, *)
struct MinionCardRow: View {
    let card: Card

    @SwiftUI.State private var tile: NSImage?

    private static let rowH: CGFloat = CGFloat(kRowHeight)   // 34 pt
    private static let nameX: CGFloat = 8
    // coinRect in CardBar: NSRect(x: 217-25, y: 4, width: 25, height: 25)
    private static let coinW: CGFloat = 25

    private var isSpell: Bool { card.type == .battleground_spell }

    var body: some View {
        ZStack(alignment: .leading) {
            Color(red: 0x1a/255, green: 0x1c/255, blue: 0x1e/255)

            if let tile {
                Image(nsImage: tile)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: Self.rowH)
                    .clipped()
            }

            if let fade = BarThemeImages.image("fade") {
                Image(nsImage: fade)
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.rowH)
            }

            if let frame = BarThemeImages.image("frame") {
                Image(nsImage: frame)
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.rowH)
            }

            // Name + optional spell coin in a single HStack so the name
            // naturally truncates before the coin without needing explicit widths.
            HStack(spacing: 0) {
                Text(card.name)
                    .font(.custom(BarThemeImages.cardNameFont, size: 15))
                    .outlinedText()
                    .lineLimit(1)
                    .padding(.leading, Self.nameX)
                Spacer(minLength: 0)
                if isSpell { spellCoin }
            }
            .frame(height: Self.rowH)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.rowH)
        .clipped()
        .cardImageTooltip(cardId: card.id)
        .onAppear(perform: loadTile)
    }

    // Coin-cost badge: coin image with cost number centered on top.
    // Size = coinRect.width = 25pt (CardBar reference). The 17pt ChunkFive number
    // matches CardBar's countFontSize (17) and CardTile's HearthstoneTextBlock FontSize="17".
    private var spellCoin: some View {
        ZStack {
            Image("coin-cost")
                .resizable()
                .frame(width: Self.coinW, height: Self.coinW)
            if card.cost > 0 {
                Text("\(card.cost)")
                    .chunkFive(size: 17)
                    .outlinedText()
            }
        }
        .frame(width: Self.coinW, height: Self.coinW)
    }

    private func loadTile() {
        if let cached = ImageUtils.cachedTile(cardId: card.id) {
            tile = cached; return
        }
        ImageUtils.tile(for: card.id) { img in
            DispatchQueue.main.async { self.tile = img }
        }
    }
}

// MARK: - Theme image cache

// Loads and caches frame/fade theme PNGs from Resources/Themes/Bars/{theme}/.
// Keyed by "{theme}/{name}" so a theme switch invalidates cached entries.
// All access is on the main thread (SwiftUI body + onAppear).
enum BarThemeImages {
    private static var cache: [String: NSImage?] = [:]

    static func image(_ name: String) -> NSImage? {
        let key = "\(Settings.theme)/\(name)"
        if let cached = cache[key] { return cached }
        let img = load(name)
        cache[key] = img
        return img
    }

    private static func load(_ name: String) -> NSImage? {
        guard let rp = Bundle.main.resourcePath else { return nil }
        let theme = Settings.theme.isEmpty ? "classic" : Settings.theme
        return NSImage(contentsOfFile: "\(rp)/Resources/Themes/Bars/\(theme)/\(name).png")
    }

    // ClassicBar overrides to "Belwe Bd BT"; all other themes use "ChunkFive".
    static var cardNameFont: String {
        Settings.theme == "classic" ? "Belwe Bd BT" : "ChunkFive"
    }
}
