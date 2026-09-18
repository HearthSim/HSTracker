//
//  TrackerCardHoverHandler.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// What happens when the cursor rests on a row of a deck tracker: the blown-up
/// card render, the related-cards grid, and the player deck's synergy highlight.
///
/// This is `Tracker`'s `CardCellHover` conformance, lifted out of the window
/// controller as the panel moved onto the overlay canvas. One handler per side,
/// which is what lets `Tracker.getHoverComponent` go: it existed only because a
/// single `Tracker` instance owned both the player's lists and the opponent's,
/// and had to work out which of them a hovered row came from.
@available(macOS 10.15, *)
class TrackerCardHoverHandler: NSObject, ObservableObject, TrackerRowHoverTarget {
    let playerType: PlayerType

    init(playerType: PlayerType) {
        self.playerType = playerType
    }

    /// `ListViewPlayer.ShouldHighlightCard` - set while a row is hovered, so the
    /// cards that combo with it light up. Bumped alongside `highlightVersion` so
    /// the hosted lists can tell when it actually changed.
    @Published private(set) var deckHighlight: ((Card, [Card]) -> HighlightColor)?
    @Published private(set) var highlightVersion = 0

    private var delayedTooltip: DelayedTooltip?

    func highlightPlayerDeckCards(highlightSourceCardId: String?) {
        guard let highlightSourceCardId, !highlightSourceCardId.isEmpty, Settings.showPlayerHighlightSynergies else {
            setHighlight(nil)
            return
        }
        let game = AppDelegate.instance().coreManager.game
        let highlightSourceCard = game.relatedCardsManager.getCardWithHighlight(highlightSourceCardId)
        setHighlight(highlightSourceCard?.shouldHighlight)
    }

    private func setHighlight(_ highlight: ((Card, [Card]) -> HighlightColor)?) {
        // Nothing to compare two closures by, so a no-op set still costs a
        // version bump - but the only callers are hover in and hover out.
        if highlight == nil && deckHighlight == nil { return }
        deckHighlight = highlight
        highlightVersion += 1
    }

    // MARK: - Hover

    /// `rowFrame` is the hovered row in screen coordinates - RootOverlayWindow's
    /// sweep converts it out of the canvas before handing it over.
    func hover(card: Card, rowFrame: NSRect) {
        if playerType == .player {
            highlightPlayerDeckCards(highlightSourceCardId: card.id)
        }
        // CardTooltipPanel keeps its own show delay - CardTile.xaml's
        // ToolTipService.InitialShowDelay - so the render is asked for straight
        // away. The grid, which HDT shows as part of the same tooltip, keeps the
        // delay the floating-card window was driven through.
        TrackerRowCardPreview.show(card: card, rowFrame: rowFrame)
        delayedTooltip?.cancel()
        delayedTooltip = DelayedTooltip(handler: tooltipDisplay, 0.400,
                                        ["frame": rowFrame, "card": card])
    }

    func out(card: Card) {
        if playerType == .player {
            highlightPlayerDeckCards(highlightSourceCardId: nil)
        }
        delayedTooltip?.cancel()
        delayedTooltip = nil
        TrackerRowCardPreview.hide(card: card)
        AppDelegate.instance().coreManager.game.windowManager.tooltipGridCards.hide()
    }

    private func tooltipDisplay(_ userInfo: Any?) {
        defer { delayedTooltip = nil }
        guard let dict = userInfo as? [String: Any?],
              let cellOnScreen = dict["frame"] as? NSRect,
              let card = dict["card"] as? Card else {
            return
        }

        let game = AppDelegate.instance().coreManager.game
        // The grid goes beside the card render, as HDT's does by sitting in the
        // same CardTooltip control - so it is placed against the render's frame
        // rather than against the row.
        let anchor = TrackerRowCardPreview.frame(card: card, rowFrame: cellOnScreen)
        if playerType == .opponent {
            if Settings.showOpponentRelatedCards {
                setRelatedCardsTooltip(game.opponent, card.id, anchor)
            }
        } else if Settings.showPlayerRelatedCards {
            setRelatedCardsTooltip(game.player, card.id, anchor)
        }
    }

    func setRelatedCardsTooltip(_ player: Player, _ cardId: String, _ rect: NSRect) {
        let game = AppDelegate.instance().coreManager.game
        let relatedCards = game.getRelatedCards(player: player, cardId: cardId)

        let hearthstoneRect = SizeHelper.hearthstoneWindow.frame
        let tooltipGridCards = game.windowManager.tooltipGridCards
        // The deck-list hover is HDT's Card.UpdateTooltip path, gated on OutfinderInDeck: an
        // Outfinder pool card shows nothing at all when the Outfinder is off for the deck, while a
        // card carrying only a plain related-cards list still shows its grid.
        if relatedCards.count > 0 &&
            !game.relatedCardsManager.isOutfinderSuppressed(cardId: cardId, surfaceEnabled: Settings.outfinderInDeck) {
            let nonNullableRelatedCards = relatedCards.compactMap { $0 }

            tooltipGridCards.setCardIdsFromCards(nonNullableRelatedCards)
            tooltipGridCards.setTitle(String.localizedString("Related_Cards", comment: ""))
            // The deck list's own tooltip is CardTooltip.xaml, whose GridCardImages scales by
            // Config.CardImageSize rather than by the window - and that setting has no HSTracker
            // equivalent, so it stays at its default of 1. Set explicitly all the same: the panel
            // is a singleton, so an overlay hover's window scale would otherwise carry over.
            tooltipGridCards.setScale(1)
            // Passing player (like Game.swift's hover paths already do) so dynamic
            // evolve/devolve pools resolve their live-state summary here too, instead of
            // silently falling through to no summary on a deck-list hover.
            let (statistics, summary, hasLargePool) = game.relatedCardsManager.getPoolStatistics(cardId: cardId, relatedCards: relatedCards, player: player)
            tooltipGridCards.setPoolStatistics(statistics, relatedCardsSummary: summary, hasLargePool: hasLargePool)
            // rect is the hovered cell in screen space, so every bound it is compared against has
            // to be in screen space too: a bare width/height is the size of a display, not the top
            // or right edge of the one the tracker is actually on.
            let screen = NSScreen.screens.first { s in s.frame.intersects(rect) } ?? NSScreen.main
            var y = rect.minY
            let maxY = screen?.frame.maxY ?? hearthstoneRect.maxY
            if rect.minY + CGFloat(tooltipGridCards.gridHeight) > maxY {
                y = maxY - CGFloat(tooltipGridCards.gridHeight)
            }

            var x: CGFloat = 0.0
            if rect.minX < hearthstoneRect.midX {
                x = rect.maxX
            } else {
                x = rect.minX - CGFloat(tooltipGridCards.gridWidth)
            }

            let tooltipFrame = NSRect(x: x, y: y, width: CGFloat(tooltipGridCards.gridWidth), height: CGFloat(tooltipGridCards.gridHeight))
            tooltipGridCards.show(frame: tooltipFrame)
            RelatedCardsRightClickMonitor.shared.setHoveredLargePool(
                card: hasLargePool ? Cards.by(cardId: cardId) : nil,
                pool: hasLargePool ? nonNullableRelatedCards : [],
                anchorFrame: tooltipFrame)
        } else {
            tooltipGridCards.hide()
            RelatedCardsRightClickMonitor.shared.clearHoveredLargePool()
        }
    }
}

/// The blown-up card render a hovered tracker row raises: HDT's CardTile.xaml,
/// which carries `OverlayExtensions.ToolTip="{x:Type tooltips:CardTooltip}"` and
/// `ToolTipService.Placement="Right"`.
///
/// This used to be the FloatingCard window, driven through `show_floating_card`
/// notifications with a hand-computed screen frame; CardTooltipPanel is the same
/// control ported properly, and already backs every other hover in the overlay.
@available(macOS 10.15, *)
enum TrackerRowCardPreview {
    /// `Card.UpdateTooltip` sets `ShowTriple = BaconCard`, so a constructed deck's
    /// card gets no golden companion image.
    static func request(for card: Card) -> CardTooltipRequest {
        CardTooltipRequest(cardId: card.id,
                           showTriple: card.baconCard,
                           baconTriple: card.baconTriple,
                           placement: .right)
    }

    /// SetTooltip clamps the tooltip to the overlay window's own
    /// ActualWidth/ActualHeight rather than to the screen, and the canvas is that
    /// window here.
    private static var bounds: NSRect? {
        AppDelegate.instance().coreManager.game.windowManager.rootOverlay?.window?.frame
    }

    /// The rows are drawn by SwiftUI and have no view of their own, so the canvas
    /// stands in as the source view: what the guard is really asking is whether
    /// the overlay is still up by the time the show delay elapses.
    private static var sourceView: NSView? {
        AppDelegate.instance().coreManager.game.windowManager.rootOverlay?.hostingView
    }

    static func show(card: Card, rowFrame: NSRect) {
        guard Settings.showFloatingCard else { return }
        CardTooltipPanel.shared.show(request(for: card),
                                     anchor: rowFrame, bounds: bounds,
                                     source: .trackingArea, sourceView: sourceView,
                                     baconCard: card.baconCard)
    }

    static func hide(card: Card) {
        CardTooltipPanel.shared.hide(ifShowing: card.id)
    }

    /// Where that render will land, for a caller that has to sit beside it.
    static func frame(card: Card, rowFrame: NSRect) -> NSRect {
        CardTooltipPanel.projectedFrame(for: request(for: card),
                                        anchor: rowFrame,
                                        bounds: bounds ?? SizeHelper.hearthstoneWindow.frame)
    }
}

/// The plainer hover the two standalone card lists want: the secret helper and
/// the graveyard counter's detail list. Both show the blown-up card render and
/// nothing else - no related-cards grid, no deck highlight - which is what the
/// `CardList` window they replaced did.
///
/// One instance, not one per list: `CardList` pinned the render to the panel's
/// right when it was the secret helper and otherwise picked the side the hovered
/// row left room for, but both of those lists are built from CardTile in HDT, so
/// both ask for Placement="Right" and let SetTooltip flip it when the far side is
/// the only one with room.
@available(macOS 10.15, *)
class OverlayCardListHoverHandler: NSObject, TrackerRowHoverTarget {
    static let shared = OverlayCardListHoverHandler()

    private override init() {
        super.init()
    }

    /// `rowFrame` is the hovered row in screen coordinates.
    func hover(card: Card, rowFrame: NSRect) {
        TrackerRowCardPreview.show(card: card, rowFrame: rowFrame)
    }

    func out(card: Card) {
        TrackerRowCardPreview.hide(card: card)
    }
}
