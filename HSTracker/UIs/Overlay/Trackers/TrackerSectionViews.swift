//
//  TrackerSectionViews.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// The sections of a deck tracker, as SwiftUI wrappers around the AppKit views
// that already draw them.
//
// Nothing here re-implements a card row or a counter frame: HDT's stack is built
// out of CardTile lists and theme-framed canvases, and HSTracker's equivalents -
// AnimatedCardList/CardBar, and the TextFrame subclasses that draw the theme's
// own PNGs - already match them pixel for pixel, including every overlay theme.
// Only the container that orders, places and scales them moved to SwiftUI.
//
// Each wrapper is given an explicit frame by TrackerPanelView and re-runs the
// AppKit view's own frame-based layout from `layout()`, because these views lay
// their children out on demand rather than in a layout pass - every pre-existing
// caller sized them by hand.

// MARK: - Row hover

/// The card lists whose rows raise a hover, and who to tell when one does.
///
/// HDT shows a deck-list card's tooltip while its overlay is fully
/// click-through: `StackPanelOpponent` carries `IsOverlayHoverVisible` and
/// `CardTile` an `OverlayExtensions.ToolTip`, and
/// `OverlayWindow.MouseOverDetection` sweeps the cursor against every registered
/// hover-visible element each frame and synthesizes MouseEnter/MouseLeave on it
/// (`CustomMouseEventArgs`). Clicks keep falling through to Hearthstone
/// throughout - hover-visible is deliberately not hit-test visible.
///
/// `RootOverlayWindow.updateTrackerRowHover` is that sweep. It is why the hosted
/// lists no longer hand their `CardBar`s a `CardCellHover` delegate: the bars'
/// own `NSTrackingArea`s are dead while the overlay window is click-through, and
/// would otherwise double-fire with the sweep the moment it is not. HDT guards
/// the same double-fire by ignoring any enter/leave that is not one of its own
/// synthesized events.
@available(macOS 10.15, *)
final class TrackerCardHoverRegistry {
    static let shared = TrackerCardHoverRegistry()

    struct Entry {
        weak var list: AnimatedCardList?
        weak var target: CardCellHover?
    }

    private(set) var entries: [Entry] = []

    func register(_ list: AnimatedCardList, target: CardCellHover?) {
        entries.removeAll { $0.list == nil || $0.list === list }
        guard let target else { return }
        entries.append(Entry(list: list, target: target))
    }

    func unregister(_ list: AnimatedCardList) {
        entries.removeAll { $0.list === list || $0.list == nil }
    }

    /// The row under a point, in screen coordinates - what HDT's mouse-over
    /// sweep resolves each frame.
    ///
    /// Screen coordinates rather than a view space, because `NSView.convert`
    /// walks the full transform chain (SwiftUI's `scaleEffect` and `offset`
    /// included) and `NSEvent.mouseLocation` is already in them, which sidesteps
    /// the question of which coordinate space a given rect was reported in.
    func row(under screenLocation: NSPoint, in window: NSWindow) -> (bar: CardBar, card: Card, target: CardCellHover)? {
        var match: (bar: CardBar, card: Card, target: CardCellHover)?
        for entry in entries {
            guard let list = entry.list, let target = entry.target,
                  list.window === window else { continue }
            // Cheap reject: descend into the rows only once the cursor is inside
            // the list itself.
            let listRect = window.convertToScreen(list.convert(list.bounds, to: nil))
            guard listRect.contains(screenLocation) else { continue }

            for case let bar as CardBar in list.subviews {
                guard let card = bar.card else { continue }
                let rect = window.convertToScreen(bar.convert(bar.bounds, to: nil))
                if rect.contains(screenLocation) {
                    // `last` wins, as in RootOverlayWindow's own tooltip sweep: a
                    // later sibling is the one drawn on top.
                    match = (bar, card, target)
                }
            }
        }
        return match
    }
}

// MARK: - Card lists

/// What a hosted `AnimatedCardList` should be showing. `version` is bumped by the
/// view model on every update so the wrapper can tell a real content change from
/// one of SwiftUI's many re-renders, and `reset` carries HDT's `reset` flag (a
/// rebuild rather than an animated diff) through with it.
struct TrackerCardListContent {
    var cards: [Card] = []
    var version: Int = 0
    var reset: Bool = false
}

/// `AnimatedCardList` lays its `CardBar`s out from its own frame width, and only
/// when something calls `updateFrames()`. Hosted in SwiftUI nothing does, so this
/// re-runs the layout whenever AppKit hands it a new size.
@available(macOS 10.15, *)
final class TrackerCardList: AnimatedCardList {
    private var laidOut: NSSize = .zero
    private var appliedVersion = -1
    private var appliedHighlightVersion = -1

    func apply(_ content: TrackerCardListContent) {
        guard content.version != appliedVersion else { return }
        appliedVersion = content.version
        update(cards: content.cards, reset: content.reset)
        laidOut = .zero
        needsLayout = true
    }

    /// Setting `shouldHighlightCard` re-evaluates and redraws every row, so it is
    /// only pushed through when the handler says the highlight actually changed.
    func applyHighlight(_ highlight: ((Card, [Card]) -> HighlightColor)?, version: Int) {
        guard version != appliedHighlightVersion else { return }
        appliedHighlightVersion = version
        shouldHighlightCard = highlight
    }

    override func layout() {
        super.layout()
        guard bounds.size != laidOut else { return }
        laidOut = bounds.size
        updateFrames()
    }

    /// Who the cursor sweep reports this list's rows to.
    weak var hoverTarget: CardCellHover? {
        didSet { TrackerCardHoverRegistry.shared.register(self, target: hoverTarget) }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            TrackerCardHoverRegistry.shared.register(self, target: hoverTarget)
        } else {
            TrackerCardHoverRegistry.shared.unregister(self)
        }
    }
}

@available(macOS 10.15, *)
struct TrackerCardListView: NSViewRepresentable {
    let content: TrackerCardListContent
    let playerType: PlayerType
    let cardHeight: CGFloat
    let delegate: CardCellHover?
    /// The player deck's synergy highlight - HDT's `ListViewPlayer.ShouldHighlightCard`.
    var highlight: ((Card, [Card]) -> HighlightColor)?
    var highlightVersion: Int = 0

    func makeNSView(context: Context) -> TrackerCardList {
        let list = TrackerCardList()
        list.playerType = playerType
        list.hoverTarget = delegate
        return list
    }

    func updateNSView(_ nsView: TrackerCardList, context: Context) {
        nsView.playerType = playerType
        if nsView.hoverTarget !== delegate {
            nsView.hoverTarget = delegate
        }
        if nsView.cardHeight != cardHeight {
            nsView.cardHeight = cardHeight
            nsView.needsLayout = true
        }
        nsView.apply(content)
        nsView.applyHighlight(highlight, version: highlightVersion)
    }
}

// MARK: - Deck lenses (on top / on bottom / related / arena package)

/// `DeckLens` positions its icon, label and card list from its own frame, the way
/// `AnimatedCardList` does, so it needs the same nudge.
@available(macOS 10.15, *)
final class TrackerDeckLens: DeckLens {
    var frameHeight: CGFloat = 40
    private var laidOut: NSSize = .zero
    private var appliedVersion = -1
    private var appliedHighlightVersion = -1

    func applyHighlight(_ highlight: ((Card, [Card]) -> HighlightColor)?, version: Int) {
        guard version != appliedHighlightVersion else { return }
        appliedHighlightVersion = version
        cards.shouldHighlightCard = highlight
    }

    func apply(_ content: TrackerCardListContent) {
        guard content.version != appliedVersion else { return }
        appliedVersion = content.version
        // Straight to the list rather than through DeckLens.update, which asks
        // Game for a tracker re-layout when a card leaves. That nudge existed
        // because the AppKit tracker sized the lens by hand; the SwiftUI panel
        // already re-lays out when the view model's card counts change.
        cards.update(cards: content.cards, reset: content.reset)
        laidOut = .zero
        needsLayout = true
    }

    override func layout() {
        super.layout()
        guard bounds.size != laidOut else { return }
        laidOut = bounds.size
        updateFrames(frameHeight: frameHeight)
    }

    weak var hoverTarget: CardCellHover? {
        didSet { TrackerCardHoverRegistry.shared.register(cards, target: hoverTarget) }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            TrackerCardHoverRegistry.shared.register(cards, target: hoverTarget)
        } else {
            TrackerCardHoverRegistry.shared.unregister(cards)
        }
    }
}

@available(macOS 10.15, *)
struct TrackerDeckLensView: NSViewRepresentable {
    let content: TrackerCardListContent
    let label: String
    let icon: DeckLensIcon
    let isPremium: Bool
    let playerType: PlayerType
    let cardHeight: CGFloat
    let frameHeight: CGFloat
    let delegate: CardCellHover?
    var highlight: ((Card, [Card]) -> HighlightColor)?
    var highlightVersion: Int = 0

    func makeNSView(context: Context) -> TrackerDeckLens {
        let lens = TrackerDeckLens(frame: .zero)
        lens.setPlayerType(playerType: playerType)
        lens.hoverTarget = delegate
        return lens
    }

    func updateNSView(_ nsView: TrackerDeckLens, context: Context) {
        nsView.setPlayerType(playerType: playerType)
        if nsView.hoverTarget !== delegate {
            nsView.hoverTarget = delegate
        }
        if nsView.icon != icon { nsView.icon = icon }
        if nsView.isPremium != isPremium { nsView.isPremium = isPremium }
        nsView.setLabel(label: label)
        nsView.frameHeight = frameHeight
        if nsView.cards.cardHeight != cardHeight {
            nsView.cards.cardHeight = cardHeight
            nsView.needsLayout = true
        }
        nsView.apply(content)
        nsView.applyHighlight(highlight, version: highlightVersion)
    }
}

// MARK: - Sideboards

@available(macOS 10.15, *)
final class TrackerSideboards: DeckSideboards {
    var frameHeight: CGFloat = 40
    var listCardHeight: CGFloat = CGFloat(kRowHeight)
    private var laidOut: NSSize = .zero
    private var appliedVersion = -1

    func apply(_ sideboards: [Sideboard], version: Int, reset: Bool) {
        guard version != appliedVersion else { return }
        appliedVersion = version
        // DeckSideboards.update splits the sideboards between the two boxes and
        // hides the empty ones; the tracker re-layout it also asks for is what
        // the SwiftUI panel does on its own, but there is no way to opt out of it
        // here without duplicating the split, and it is a no-op nudge.
        update(sideboards: sideboards, reset: reset)
        laidOut = .zero
        needsLayout = true
    }

    override func layout() {
        super.layout()
        guard bounds.size != laidOut else { return }
        laidOut = bounds.size
        updateFrames(frameHeight: frameHeight, cardHeight: listCardHeight)
    }

    /// Two lists here: E.T.C.'s band and King of the Underbelly's.
    weak var hoverTarget: CardCellHover? {
        didSet {
            TrackerCardHoverRegistry.shared.register(cards, target: hoverTarget)
            TrackerCardHoverRegistry.shared.register(kingOfTheUnderbellyCardList, target: hoverTarget)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            TrackerCardHoverRegistry.shared.register(cards, target: hoverTarget)
            TrackerCardHoverRegistry.shared.register(kingOfTheUnderbellyCardList, target: hoverTarget)
        } else {
            TrackerCardHoverRegistry.shared.unregister(cards)
            TrackerCardHoverRegistry.shared.unregister(kingOfTheUnderbellyCardList)
        }
    }
}

@available(macOS 10.15, *)
struct TrackerSideboardsView: NSViewRepresentable {
    let sideboards: [Sideboard]
    let version: Int
    let reset: Bool
    let playerType: PlayerType
    let cardHeight: CGFloat
    let frameHeight: CGFloat
    let delegate: CardCellHover?

    func makeNSView(context: Context) -> TrackerSideboards {
        let view = TrackerSideboards(frame: .zero)
        view.setPlayerType(playerType: playerType)
        view.hoverTarget = delegate
        return view
    }

    func updateNSView(_ nsView: TrackerSideboards, context: Context) {
        nsView.setPlayerType(playerType: playerType)
        if nsView.hoverTarget !== delegate {
            nsView.hoverTarget = delegate
        }
        nsView.frameHeight = frameHeight
        if nsView.listCardHeight != cardHeight {
            nsView.listCardHeight = cardHeight
            nsView.cards.cardHeight = cardHeight
            nsView.kingOfTheUnderbellyCardList.cardHeight = cardHeight
            nsView.needsLayout = true
        }
        // Shown unconditionally: the panel only mounts this section when there is
        // something in it, so DeckSideboards' own "hide until filled" flag would
        // only ever leave it blank.
        nsView.isHidden = false
        nsView.apply(sideboards, version: version, reset: reset)
    }
}

// MARK: - Hero bar (deck title / opponent class)

/// The single `CardBar` HDT's stack replaces with a plain `LblDeckTitle`.
/// HSTracker has always drawn the class portrait behind the name, so the bar is
/// what carries over - see `DeckPanel.deckTitle`.
@available(macOS 10.15, *)
struct TrackerHeroBarView: NSViewRepresentable {
    let heroCardId: String?
    let name: String?
    /// The player's own bar keeps the hero's cost gem; the opponent's is drawn
    /// costless, as the AppKit tracker did.
    let hidesCost: Bool

    func makeNSView(context: Context) -> CardBar {
        let bar = CardBar.factory()
        bar.playerType = .hero
        return bar
    }

    func updateNSView(_ nsView: CardBar, context: Context) {
        let card = Cards.hero(byId: heroCardId ?? "")
        card?.count = 1
        if hidesCost {
            card?.cost = -1
        }
        nsView.card = card
        nsView.playerName = name
        nsView.update(highlight: false)
        nsView.needsDisplay = true
    }
}

// MARK: - Theme-framed counters

/// Wraps one of the `TextFrame` subclasses, which draw the overlay theme's own
/// frame PNG plus their numbers and need nothing but a redraw when their values
/// change.
@available(macOS 10.15, *)
struct TrackerTextFrameView<Frame: TextFrame>: NSViewRepresentable {
    let make: () -> Frame
    let configure: (Frame) -> Void

    func makeNSView(context: Context) -> Frame {
        let view = make()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: Frame, context: Context) {
        configure(nsView)
        nsView.needsDisplay = true
    }
}
