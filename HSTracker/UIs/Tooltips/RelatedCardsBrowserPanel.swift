//
//  RelatedCardsBrowserPanel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/27/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Ports HDT's Controls/Overlay/Constructed/RelatedCardsPanel/RelatedCardsPanel.xaml{,.cs} (plus
// its RelatedCardsPanelViewModel.cs, CostFilterButton.cs and KeywordFilterButton.cs): the
// "right-click to see all options" full-pool browser for a card whose related-cards pool is too
// large for RelatedCardsTooltipPanel's compact grid (see RelatedCardsManager.largePoolThreshold).
//
// Unlike RelatedCardsTooltipPanel (a click-through hover tooltip), this panel is meant to be
// interacted with - scrolled, filtered, dismissed - so its NSPanel does not set
// ignoresMouseEvents. It follows ToastWindowController's pattern for an interactive
// non-activating overlay panel instead (borderless + nonactivatingPanel + isFloatingPanel, mouse
// events NOT ignored).
//
// HDT gates its cost/keyword filter bar behind OutfinderTrial.HasAccess (a premium/trial-only
// feature) and shows a "Free Version" HSReplay-branding row when it isn't available. Neither the
// trial system nor that branding exists in HSTracker yet (see RelatedCardsTooltipPanel's own
// PoolSummaryPanelView comment), so filters are simply always available here: the cost filter
// works unconditionally, and the keyword filter naturally stays hidden until
// RelatedCardsManager.relatedCardsSummaryKeywords is ever populated.
//
// The pool itself is drawn in one of HDT's two modes, chosen by Config.Instance.OutfinderUseCardTiles
// (Settings.outfinderUseCardTiles here): off - the default - lays the pool out as full card renders,
// three per row; on lays it out as a card-tile list, which is what HDT's own checkbox label calls the
// mode that "uses less data". HSTracker already has a card-tile list in AnimatedCardList, so the tile
// mode hosts that rather than reimplementing CardTile.xaml in SwiftUI.
@available(macOS 10.15, *)
final class RelatedCardsBrowserViewModel: ObservableObject {
    @Published var cardName: String = ""
    @Published var cards: [Card] = []
    @Published var isFilterOpen: Bool = false
    // Read once per pool rather than on every body evaluation, mirroring how HDT only re-reads
    // Config.Instance.OutfinderUseCardTiles when RaiseDisplayModeChanged fires.
    @Published var useCardTiles: Bool = Settings.outfinderUseCardTiles
    @Published private(set) var activeCostFilters: Set<Int> = []
    @Published private(set) var activeKeyword: String?

    var onClose: (() -> Void)?

    var headerText: String {
        String(format: String.localizedString("TheOutfinder_Label_PoolHeader", comment: ""), cardName, cards.count)
    }

    // Only offered once the pool has more than 2 distinct costs - matches
    // RelatedCardsPanelViewModel.ShowCostFilters, avoiding a filter row for a pool where every
    // card is (say) cost 1 or 2.
    var costFilters: [Int] {
        let distinct = Set(cards.map { $0.cost }).sorted()
        return distinct.count > 2 ? distinct : []
    }

    // Mirrors RelatedCardsPanelViewModel.RebuildKeywordFilters: only keywords that actually match
    // at least one card in this specific pool are offered, sorted by match count (desc) then name.
    var keywordFilters: [(keyword: String, label: String, count: Int)] {
        guard let keywords = RelatedCardsManager.relatedCardsSummaryKeywords else { return [] }
        let cardIds = Set(cards.map { $0.id })
        return keywords.compactMap { keyword, ids -> (String, String, Int)? in
            let count = ids.intersection(cardIds).count
            guard count > 0 else { return nil }
            return (keyword, RelatedCardsManager.localizeKeywordName(keyword), count)
        }
        .sorted { $0.2 != $1.2 ? $0.2 > $1.2 : $0.0 < $1.0 }
        .map { (keyword: $0.0, label: $0.1, count: $0.2) }
    }

    var hasAnyFilter: Bool {
        !costFilters.isEmpty || !keywordFilters.isEmpty
    }

    var hasActiveFilter: Bool {
        activeKeyword != nil || !activeCostFilters.isEmpty
    }

    var filteredCards: [Card] {
        guard hasActiveFilter else { return cards }
        var matchIds: Set<String>?
        if let activeKeyword, let keywords = RelatedCardsManager.relatedCardsSummaryKeywords {
            matchIds = keywords[activeKeyword]
        }
        return cards.filter { card in
            (matchIds == nil || matchIds!.contains(card.id)) &&
                (activeCostFilters.isEmpty || activeCostFilters.contains(card.cost))
        }
    }

    var filterMatchText: String {
        "\(filteredCards.count)/\(cards.count)"
    }

    func toggleFilterDrawer() {
        isFilterOpen.toggle()
    }

    func toggleKeyword(_ keyword: String) {
        activeKeyword = activeKeyword == keyword ? nil : keyword
    }

    func toggleCost(_ cost: Int) {
        if activeCostFilters.contains(cost) {
            activeCostFilters.remove(cost)
        } else {
            activeCostFilters.insert(cost)
        }
    }

    func reset(cardName: String, cards: [Card]) {
        self.cardName = cardName
        self.cards = cards
        useCardTiles = Settings.outfinderUseCardTiles
        isFilterOpen = false
        activeCostFilters = []
        activeKeyword = nil
    }

    func close() {
        onClose?()
    }
}

@available(macOS 10.15, *)
private struct FilterChipView: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(isActive ? Color(hex: "#FFB00D") : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isActive ? Color(hex: "#201A00") : Color(hex: "#1E2426"))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? Color(hex: "#FFB00D") : Color(hex: "#3A4A52"), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Ports the CardTooltip HDT attaches to both display modes: to the grid's <Border> with
// Placement="Left", and - via CardTile.xaml itself - to each tile row with Placement="Right".
//
// CardTooltipPanel is that tooltip, already ported, but the way it is normally triggered is not
// reusable here: CardHoverRegistry is polled by RootOverlayWindow's mouse-move monitors and only
// ever sees views inside that canvas, while this browser is its own NSPanel. Hover is therefore
// detected with an NSTrackingArea - the same mechanism CardBar already uses for the deck tracker's
// own hover, and the reason it keeps working while Hearthstone is the frontmost app.
@available(macOS 10.15, *)
enum RelatedCardsBrowserTooltip {
    static func show(card: Card, placement: CardTooltipPlacement, from view: NSView) {
        guard let window = view.window else { return }
        let anchor = window.convertToScreen(view.convert(view.bounds, to: nil))
        // HDT clamps the tooltip to its overlay window; there is no overlay window in this path, so
        // the screen the browser is on plays that role.
        let bounds = (NSScreen.screens.first { $0.frame.intersects(window.frame) } ?? NSScreen.main)?.visibleFrame
        // Card.UpdateTooltip sets ShowTriple = BaconCard, so a constructed pool card gets no golden
        // companion image. source/sourceView opt out of the CardHoverRegistry bookkeeping that
        // RootOverlayWindow's own hovers rely on - see CardTooltipSource.
        CardTooltipPanel.shared.show(cardId: card.id, showTriple: card.baconCard,
                                     baconTriple: card.baconTriple, placement: placement,
                                     anchor: anchor, bounds: bounds,
                                     source: .trackingArea, sourceView: view,
                                     baconCard: card.baconCard)
    }

    static func hide(card: Card) {
        CardTooltipPanel.shared.hide(ifShowing: card.id)
    }

    static func hideAll() {
        CardTooltipPanel.shared.hide(from: .trackingArea)
    }
}

@available(macOS 10.15, *)
final class RelatedCardsBrowserHoverNSView: NSView {
    var card: Card?
    var placement: CardTooltipPlacement = .left

    // Match NSHostingView's own flip, like CardHoverNSView does.
    override var isFlipped: Bool { true }

    private lazy var trackingArea = NSTrackingArea(rect: .zero,
                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                                   owner: self,
                                                   userInfo: nil)

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if !trackingAreas.contains(trackingArea) {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard let card else { return }
        RelatedCardsBrowserTooltip.show(card: card, placement: placement, from: self)
    }

    override func mouseExited(with event: NSEvent) {
        guard let card else { return }
        RelatedCardsBrowserTooltip.hide(card: card)
    }
}

@available(macOS 10.15, *)
private struct RelatedCardsBrowserHoverView: NSViewRepresentable {
    let card: Card
    let placement: CardTooltipPlacement

    func makeNSView(context: Context) -> RelatedCardsBrowserHoverNSView {
        let view = RelatedCardsBrowserHoverNSView()
        view.card = card
        view.placement = placement
        return view
    }

    func updateNSView(_ nsView: RelatedCardsBrowserHoverNSView, context: Context) {
        nsView.card = card
        nsView.placement = placement
    }
}

// The grid mode's card: RelatedCardItem.AssetViewModel is built with CardAssetType.FullImage, so
// this is the whole rendered card (frame, name, text), not the art crop RelatedCardsTooltipPanel's
// compact grid uses. The 108x152 box and its 2,3 margin are the literal values from the XAML's
// <Image> in the ShowCardGrid ListView; the renders carry their own transparent padding, which is
// why HDT gets away with rows that tight.
@available(macOS 10.15, *)
private struct RelatedCardsBrowserFullCardView: View {
    let card: Card

    static let cardWidth: CGFloat = 108
    static let cardHeight: CGFloat = 152

    @SwiftUI.State private var image: NSImage?

    private var loadingImageName: String {
        switch card.type {
        case .hero: return "loading_hero"
        case .minion: return "loading_minion"
        case .weapon: return "loading_weapon"
        default: return "loading_spell"
        }
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(loadingImageName).resizable().aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .padding(.horizontal, 2)
        .padding(.vertical, 3)
        // HDT's tooltip hangs off the Border that wraps the Image, so it covers the margin too.
        // A background rather than an overlay, matching HoverTrackingNSView's existing use: a
        // tracking area fires regardless of z-order, and behind the card it cannot intercept the
        // scroll wheel.
        .background(RelatedCardsBrowserHoverView(card: card, placement: .left))
        .onAppear(perform: loadImage)
    }

    private func loadImage() {
        let cardId = card.id
        if card.baconCard {
            ImageUtils.cardArtBG(for: cardId, baconTriple: false) { img in
                DispatchQueue.main.async { self.image = img }
            }
        } else {
            ImageUtils.cardArt(for: cardId) { img in
                DispatchQueue.main.async { self.image = img }
            }
        }
    }
}

// AnimatedCardList lays its CardBars out from its own frame width, and only when something calls
// updateFrames() - it has no layout pass of its own because every existing caller sizes it by hand.
// Hosted in SwiftUI nothing does, so this subclass re-runs the layout whenever AppKit hands it a new
// size, and reload(cards:) forces one after the contents change.
@available(macOS 10.15, *)
final class RelatedCardsBrowserTileList: AnimatedCardList {
    private var laidOutSize: NSSize = .zero
    private var loadedIds: [String] = []

    // updateNSView runs for every change to the view model, most of which - opening the filter
    // drawer, say - leave the pool alone, and update(cards:reset:) would throw away and rebuild
    // every CardBar each time.
    func reload(cards: [Card]) {
        let ids = cards.map { $0.id }
        guard ids != loadedIds else { return }
        loadedIds = ids
        update(cards: cards, reset: true)
        laidOutSize = .zero
        needsLayout = true
    }

    override func layout() {
        super.layout()
        guard bounds.size != laidOutSize else { return }
        laidOutSize = bounds.size
        updateFrames()
    }
}

// The tile mode's list. HDT draws its own CardTile at 217x34 scaled by 0.92 and centered in the
// 350pt panel; HSTracker's CardBar is authored against the very same 217x34 box (kFrameWidth /
// kRowHeight), so the same scale reproduces HDT's row size exactly. playerType .cardList is the
// tracker-less variant: white text, and no darkening for the count of 0 that pool cards carry.
//
// The rows need no hover overlay of their own: CardTile.xaml carries its CardTooltip inline, and
// CardBar has the matching affordance built in - an NSTrackingArea reporting through CardCellHover,
// which is what drives the deck tracker's own hover preview.
@available(macOS 10.15, *)
private struct RelatedCardsBrowserTileListView: NSViewRepresentable {
    let cards: [Card]

    static let tileScale: CGFloat = 0.92
    static let tileWidth = CGFloat(kFrameWidth) * tileScale
    static let tileHeight = CGFloat(kRowHeight) * tileScale

    // CardBar holds its delegate weakly and AnimatedCardList holds it strongly, so the coordinator
    // SwiftUI owns is what keeps it alive for the life of the list.
    final class Coordinator: NSObject, CardCellHover {
        func hover(cell: CardBar, card: Card) {
            // Placement="Right", per CardTile.xaml.
            RelatedCardsBrowserTooltip.show(card: card, placement: .right, from: cell)
        }

        func out(card: Card) {
            RelatedCardsBrowserTooltip.hide(card: card)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> RelatedCardsBrowserTileList {
        let list = RelatedCardsBrowserTileList()
        list.playerType = .cardList
        list.cardHeight = Self.tileHeight
        // Set before the first reload: AnimatedCardList only forwards a delegate that is already in
        // place when it builds each CardBar.
        list.delegate = context.coordinator
        return list
    }

    func updateNSView(_ nsView: RelatedCardsBrowserTileList, context: Context) {
        nsView.reload(cards: cards)
    }
}

@available(macOS 10.15, *)
private struct RelatedCardsBrowserContentView: View {
    @ObservedObject var viewModel: RelatedCardsBrowserViewModel
    static let width: CGFloat = 350

    var body: some View {
        VStack(spacing: 0) {
            header
            if viewModel.hasAnyFilter {
                filterBar
                if viewModel.isFilterOpen {
                    filterDrawer
                }
            }
            cardList
        }
        .frame(width: Self.width)
        .background(Color(hex: "#DD1E2428"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2C3A42"), lineWidth: 1))
    }

    private var header: some View {
        HStack {
            Text(viewModel.headerText)
                .chunkFive(size: 14)
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button(action: { viewModel.close() }) {
                // "xmark" (SF Symbols) needs macOS 11 - this file's baseline is 10.15, matching
                // the rest of this port - so a plain glyph stands in for the icon.
                Text(verbatim: "\u{2715}")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#1C2022"))
        .cornerRadius(12, corners: [.topLeft, .topRight])
    }

    private var filterBar: some View {
        Button(action: { viewModel.toggleFilterDrawer() }) {
            HStack {
                HStack(spacing: 6) {
                    Text(String.localizedString("TheOutfinder_Label_Filters", comment: "").uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "#FFB00D"))
                    if viewModel.hasActiveFilter {
                        Circle().fill(Color(hex: "#FFB00D")).frame(width: 5, height: 5)
                    }
                }
                Spacer()
                Text(viewModel.filterMatchText)
                    .font(.system(size: 10))
                    .foregroundColor(viewModel.hasActiveFilter ? Color(hex: "#FFB00D") : Color(hex: "#8A9BA8"))
                Text(verbatim: viewModel.isFilterOpen ? "\u{25B4}" : "\u{25BE}")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(hex: "#1A1C1E"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#2C3540")), alignment: .bottom)
    }

    private var filterDrawer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.keywordFilters.isEmpty {
                ChunkedChipRows(items: viewModel.keywordFilters, itemsPerRow: 3) { entry in
                    FilterChipView(label: entry.label, isActive: viewModel.activeKeyword == entry.keyword) {
                        viewModel.toggleKeyword(entry.keyword)
                    }
                }
            }
            if !viewModel.costFilters.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text(String.localizedString("TheOutfinder_Label_Cost", comment: "").uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                    ChunkedChipRows(items: viewModel.costFilters, itemsPerRow: 6) { cost in
                        FilterChipView(label: "\(cost)", isActive: viewModel.activeCostFilters.contains(cost)) {
                            viewModel.toggleCost(cost)
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#17191B"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#2C3540")), alignment: .bottom)
    }

    private var cardList: some View {
        ScrollView {
            if viewModel.useCardTiles {
                cardTiles
            } else {
                cardGrid
            }
        }
        .frame(maxHeight: 480)
    }

    // Ports the ShowCardGrid ListView: rows of three full card renders, centered.
    private var cardGrid: some View {
        let cards = viewModel.filteredCards
        let rows = Int(ceil(Double(cards.count) / 3.0))
        return VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        if index < cards.count {
                            RelatedCardsBrowserFullCardView(card: cards[index])
                                // Same reason as RelatedCardsTooltipPanel's grid: the panel is a
                                // singleton, so a slot that changes card (filtering the pool, or
                                // reopening the browser on another card) keeps its view identity and
                                // never re-runs the .onAppear that loads the art.
                                .id(cards[index].imageIdentity)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // Ports the UseCardTiles ListView, down to its 4,3 padding.
    private var cardTiles: some View {
        RelatedCardsBrowserTileListView(cards: viewModel.filteredCards)
            .frame(width: RelatedCardsBrowserTileListView.tileWidth,
                   height: RelatedCardsBrowserTileListView.tileHeight * CGFloat(viewModel.filteredCards.count))
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity)
    }
}

// SwiftUI has no WrapPanel equivalent pre-macOS 13's Layout protocol (this file's baseline is
// 10.15, matching the rest of this port), so filter chips wrap the same way
// RelatedCardsTooltipPanel's keyword-chip summary already does: chunked into fixed-size rows by
// index math rather than a true flow layout. A fixed row size is a fair approximation for a
// handful of filter chips in a 320pt-wide panel.
@available(macOS 10.15, *)
private struct ChunkedChipRows<Data: RandomAccessCollection, RowContent: View>: View where Data.Index == Int {
    let items: Data
    let itemsPerRow: Int
    let rowContent: (Data.Element) -> RowContent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<Int(ceil(Double(items.count) / Double(itemsPerRow))), id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<itemsPerRow, id: \.self) { column in
                        let index = row * itemsPerRow + column
                        if index < items.count {
                            rowContent(items[items.index(items.startIndex, offsetBy: index)])
                        }
                    }
                }
            }
        }
    }
}

// Public surface mirrors RelatedCardsTooltipPanel's shape: an NSPanel-backed singleton with
// simple show/hide entry points, following the same NSPanel + NSHostingView precedent.
@available(macOS 10.15, *)
final class RelatedCardsBrowserPanel: NSPanel {
    static let shared = RelatedCardsBrowserPanel()

    private let viewModel = RelatedCardsBrowserViewModel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Int(RelatedCardsBrowserContentView.width), height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        // Unlike RelatedCardsTooltipPanel, this panel is meant to be clicked and scrolled -
        // ignoresMouseEvents stays false (the default), matching ToastWindowController's pattern
        // for an interactive non-activating overlay panel.
        hasShadow = true
        isFloatingPanel = true
        hidesOnDeactivate = false
        animationBehavior = .none
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)) + 1)

        viewModel.onClose = { [weak self] in self?.hide() }

        contentView = NSHostingView(rootView: RelatedCardsBrowserContentView(viewModel: viewModel))

        // Dismiss when the user leaves the game, like every other overlay.
        //
        // CardImageTooltip does this by hiding on Hearthstone's *deactivation*, but that rule
        // can't be reused here: this panel is interactive, and bringing HSTracker forward to
        // click a filter deactivates Hearthstone - which would dismiss the panel the moment it
        // was used. Keying off which app just became active instead keeps it open for both
        // Hearthstone and HSTracker, and closes it for anything else (alt-tabbing to a browser,
        // Hearthstone being minimized, etc).
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(otherAppActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func otherAppActivated(_ notification: Notification) {
        guard isVisible else { return }
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if app.localizedName == CoreManager.applicationName { return }
        if app.bundleIdentifier == Bundle.main.bundleIdentifier { return }
        hide()
    }

    var isShown: Bool {
        isVisible
    }

    // sourceCard/pool mirror HDT's ShowRelatedCardsPanel(Card sourceCard, List<Card> relatedCards)
    // call - the card whose pool this is (for the header text) and the full pool to browse.
    func show(sourceCard: Card, relatedCards: [Card], near frame: NSRect) {
        collectionBehavior = Settings.canJoinFullscreen ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
        RelatedCardsBrowserTooltip.hideAll()
        viewModel.reset(cardName: sourceCard.name, cards: relatedCards)

        var origin = NSPoint(x: frame.maxX + 12, y: frame.maxY - 600)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(frame.origin) }) ?? NSScreen.main {
            if origin.x + RelatedCardsBrowserContentView.width > screen.frame.maxX {
                origin.x = frame.minX - RelatedCardsBrowserContentView.width - 12
            }
            if origin.y < screen.frame.minY {
                origin.y = screen.frame.minY
            }
            if origin.y + 600 > screen.frame.maxY {
                origin.y = screen.frame.maxY - 600
            }
        }
        if origin.x.isFinite && origin.y.isFinite {
            setFrameOrigin(origin)
        }
        makeKeyAndOrderFront(nil)
    }

    func hide() {
        // The pool the tooltip was anchored to is going away with the panel, and a plain NSView
        // tracking area cannot report an exit for a window that just disappeared.
        RelatedCardsBrowserTooltip.hideAll()
        orderOut(nil)
    }
}
