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
    // BattlegroundsCardsGroup.xaml.cs sets CardsList.ShowPinButton = true
    // unconditionally; whether the button actually shows is the pinning feature's
    // own visibility, which is what this carries down.
    @ObservedObject var pinning: BattlegroundsMinionPinningViewModel
    let onTribeSelected: ((Race) -> Void)?

    // Width="196" on the XAML's outer Border. Narrower than the 249pt panel on
    // purpose: the ItemsControl holding the groups is HorizontalAlignment="Right",
    // so the groups hug the right edge and leave a 53pt gutter down the left.
    // That gutter is what the extra-filters panel slides over - its 20pt of
    // overlap with the panel lands in empty space rather than on the cards.
    static let width: CGFloat = 196

    @SwiftUI.State private var isHeaderHovering = false

    // Mirrors BattlegroundsCardsGroup.HeaderCursor: header is clickable ("Hand")
    // only in tier mode (grouped by tribe) and only for a real filterable race —
    // not spells, not neutral/invalid, and never in the type- or keyword-grouped
    // views, whose headers name a tavern tier rather than a type.
    private var canFilterByTribe: Bool {
        !group.groupedByMinionType
            && !group.groupedByKeyword
            && group.minionType?.isFilterableFromGroupHeader == true
    }

    var body: some View {
        VStack(spacing: 0) {
            groupHeader
            ForEach(Array(group.cards.enumerated()), id: \.offset) { _, card in
                // AnimatedCardList.Update passes `ShowTier7InspirationButton &&
                // card.IsBaconMinion` down to each AnimatedCard. IsBaconMinion is
                // `BaconCard && TypeEnum == MINION`; every card in these groups is
                // already out of the Battlegrounds pool, and HSTracker's own
                // `baconCard` flag is only populated for counters rather than by
                // the card DB, so the type check alone carries the distinction
                // that matters here - minions and buddies get the indicator,
                // tavern spells do not.
                MinionCardRow(card: card,
                              showInspiration: group.isInspirationEnabled && card.type == .minion,
                              pinning: pinning)
            }
        }
        .frame(width: Self.width)
        .background(Color(hex: "#23272a"))
        .overlay(Rectangle().stroke(Color(hex: "#141617"), lineWidth: 1))
        // Margin="0,5,0,0" on that same Border - carried per group rather than
        // as VStack spacing, so the *first* group is inset from the tier strip
        // too. Spacing alone left it flush against the strip's bottom border.
        .padding(.top, 5)
    }

    // MARK: - Group header

    // Matches BattlegroundsCardsGroup.xaml header Border:
    // Background=HeaderBackground (#1d3657), bottom border #141617.
    // Wrapped in a Button (not .onTapGesture) so it reliably fires inside
    // a ScrollView on macOS.
    private var groupHeader: some View {
        Button {
            if canFilterByTribe, case .race(let race) = group.minionType {
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

                // Subtitle tab on the right edge of the header, mirroring
                // BattlegroundsCardsGroup.SubTitle: the keyword name in keyword
                // mode, the type name in type mode, nothing in tier mode (where
                // the title already carries the type).
                //
                // No filter icon rides along here any more - drilling into a type
                // now goes through the extra-filters panel's slide-out button
                // (see BattlegroundsMinionsExtraFiltersView). The header itself
                // stays clickable, as in HDT.
                if !groupSubtitle.isEmpty {
                    subtitleBadge
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
        isHeaderHovering && canFilterByTribe ? "#24436c" : "#1d3657"
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

            // SubTitle binding in XAML; text only, no icon, matching HDT.
            Text(groupSubtitle)
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
    //   grouped by type, or by keyword and not the spells group → "Tavern Tier N"
    //   spells   → localized "spells"
    //   INVALID  → localized "neutral"
    //   otherwise → localized type name
    //
    // The keyword view's trailing spells group carries tier 0 precisely so it
    // lands in the second branch and titles itself "spells", not "Tavern Tier 0".
    private var groupTitle: String {
        if group.groupedByMinionType || (group.groupedByKeyword && group.minionType != .spells) {
            return "Tavern Tier \(group.tier)"
        }
        // HDT titles this group from Battlegrounds_Spells - plural - while the
        // subtitle and the Card Types button use the singular GameTag_BGSpell.
        if group.minionType == .spells { return BattlegroundsMinionType.spellsGroupTitle }
        return group.minionType?.displayName ?? ""
    }

    // Mirrors BattlegroundsCardsGroup.SubTitle.
    private var groupSubtitle: String {
        if group.groupedByKeyword { return group.keyword?.name ?? "" }
        if group.groupedByMinionType { return group.minionType?.displayName ?? "" }
        return ""
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
//   7. Tier7 inspiration button (hover only; see inspirationButton)
@available(macOS 10.15, *)
struct MinionCardRow: View {
    let card: Card
    // AnimatedCard.Update's showTier7InspirationBtn.
    let showInspiration: Bool
    @ObservedObject var pinning: BattlegroundsMinionPinningViewModel

    @SwiftUI.State private var tile: NSImage?
    @SwiftUI.State private var isRowHovering = false
    @SwiftUI.State private var isButtonHovering = false
    @SwiftUI.State private var isPinButtonHovering = false

    private static let rowH: CGFloat = CGFloat(kRowHeight)   // 34 pt
    private static let nameX: CGFloat = 8
    // coinRect in CardBar: NSRect(x: 217-25, y: 4, width: 25, height: 25)
    private static let coinW: CGFloat = 25
    // BtnTier7Inspiration: Width/Height 30, Margin="0,2,34,2". The 34pt right
    // inset is one 30pt button plus its 2pt margins - it keeps the rightmost
    // slot free for the pin button, which HDT docks there. HDT applies the same
    // inset whether or not that button is showing.
    private static let inspirationSize: CGFloat = 30
    private static let inspirationTrailing: CGFloat = 34

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
        .overlay(Rectangle().frame(width: 1).foregroundColor(.black.opacity(0.6)), alignment: .leading)
        // Outside the .clipped() ZStack so the button keeps its own hit area and
        // is never trimmed by the row's clip.
        .overlay(inspirationOverlay, alignment: .trailing)
        .overlay(pinOverlay, alignment: .trailing)
        // CardTile.xaml attaches its CardTooltip without a Placement, which
        // SetTooltip folds into Right - so the default is already correct here.
        .cardImageTooltip(cardId: card.id)
        // AnimatedCard's Grid_OnMouseEnter / Grid_OnMouseLeave, which run
        // InspirationButtonIn / InspirationButtonOut. Uses trackHover for the
        // same reason the group header does - see HoverTrackingNSView.
        // AnimateButtonsIn / AnimateButtonsOut run both buttons off this one
        // hover, so the guard the inspiration button used to carry moved inside
        // its own overlay - the pin button needs the hover even when there is no
        // inspiration button to show.
        .trackHover { hovering in
            withAnimation(Self.buttonAnimation(hovering)) {
                isRowHovering = hovering
            }
        }
        .onAppear(perform: loadTile)
    }

    // MARK: - Tier7 inspiration button
    //
    // Mirrors AnimatedCard.xaml's BtnTier7Inspiration Border: 30x30, CornerRadius
    // 3, 1pt #141617 border, #23272a background going to #43474a on hover, with a
    // 22x22 icon_inspiration glyph inset by 4.
    //
    // Only rendered when the group says inspiration is enabled and only visible
    // while the row is hovered, exactly as in HDT.

    // InspirationButtonIn: opacity 0->1 and scale 0.7->1 over 0.5s after a 0.1s
    // delay, on an ElasticEase(EaseOut, Oscillations=1, Springiness=3) - a spring
    // is the closest SwiftUI equivalent. InspirationButtonOut fades out over 0.1s
    // (HDT snaps the scale back in the same beat).
    private static func buttonAnimation(_ appearing: Bool) -> Animation {
        appearing ? .spring(response: 0.5, dampingFraction: 0.55).delay(0.1)
                  : .easeOut(duration: 0.1)
    }

    // The row's tracking area and the button's overlap, so take either as
    // "shown" - otherwise the button could fade out from under the cursor that
    // is resting on it.
    private var isInspirationShown: Bool { isRowHovering || isButtonHovering }

    // MARK: - Pin button
    //
    // Mirrors AnimatedCard.xaml's BtnPinMinion: a 30x30 Border in the row's
    // rightmost slot (Margin="0,2,2,2"), CornerRadius 3 on a 1pt #141617 border,
    // #23272a going to #43474a on hover - and to #141617 while the card is
    // pinned, so a pinned row reads as "filled in".
    //
    // The whole thing is wrapped in a Border bound to BgsMinionPinningVisibility,
    // hence the isShown gate.

    private var isPinned: Bool { pinning.isCardPinned(card.id) }

    // AnimateButtonsIn/Out: a pinned card's button is pinned open (PinButtonPinned
    // runs on both enter *and* leave), an unpinned one springs in on hover and
    // fades back out.
    private var isPinButtonShown: Bool { isPinned || isRowHovering || isPinButtonHovering }

    @ViewBuilder
    private var pinOverlay: some View {
        if pinning.isShown {
            pinButton
                .opacity(isPinButtonShown ? 1 : 0)
                .scaleEffect(isPinButtonShown ? 1 : 0.7)
                .allowsHitTesting(isPinButtonShown)
                .padding(.trailing, 2)
        }
    }

    private var pinButton: some View {
        Group {
            if let pin = MinionPinningImages.pin {
                Image(nsImage: pin)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        // Image Height/Width 20 with Margin="4" inside the 30pt border.
        .frame(width: 20, height: 20)
        .padding(4)
        .background(Color(hex: pinBackgroundHex))
        .cornerRadius(3)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#141617"), lineWidth: 1))
        .frame(width: Self.inspirationSize, height: Self.inspirationSize)
        .contentShape(Rectangle())
        .trackHover { hovering in
            withAnimation(Self.buttonAnimation(hovering)) {
                isPinButtonHovering = hovering
            }
        }
        // BtnPinMinion_OnMouseUp.
        .onTapGesture {
            pinning.togglePinCard(card.id)
        }
    }

    // The DataTriggers fire in XAML order, so IsMouseOver wins over IsPinned.
    private var pinBackgroundHex: String {
        if isPinButtonHovering { return "#43474a" }
        return isPinned ? "#141617" : "#23272a"
    }

    @ViewBuilder
    private var inspirationOverlay: some View {
        if showInspiration {
            inspirationButton
                .opacity(isInspirationShown ? 1 : 0)
                .scaleEffect(isInspirationShown ? 1 : 0.7)
                // Collapsed in XAML until Update makes it Visible; hidden here
                // means it also stops taking clicks while faded out.
                .allowsHitTesting(isInspirationShown)
                .padding(.trailing, Self.inspirationTrailing)
        }
    }

    private var inspirationButton: some View {
        Image("icon_inspiration")
            .resizable()
            .frame(width: 22, height: 22)
            .padding(4)
            .background(Color(hex: isButtonHovering ? "#43474a" : "#23272a"))
            .cornerRadius(3)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#141617"), lineWidth: 1))
            .frame(width: Self.inspirationSize, height: Self.inspirationSize)
            .contentShape(Rectangle())
            .trackHover { hovering in
                withAnimation(Self.buttonAnimation(hovering)) {
                    isButtonHovering = hovering
                }
            }
            // AnimatedCard's BtnBgsInspiration_OnMouseUp: SetKeyMinion(Card)
            // then ShowBgsInspiration().
            .onTapGesture {
                guard let inspiration = Self.inspirationViewModel else { return }
                inspiration.setKeyMinion([card])
                inspiration.show()
            }
    }

    private static var inspirationViewModel: BattlegroundsInspirationViewModel? {
        AppDelegate.instance().coreManager?.game.windowManager.rootOverlay?.viewModel.battlegroundsInspiration
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
