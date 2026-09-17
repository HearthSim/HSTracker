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
class TrackerCardHoverHandler: NSObject, ObservableObject, CardCellHover {
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

    // MARK: - CardCellHover

    func hover(cell: CardBar, card: Card) {
        if playerType == .player {
            highlightPlayerDeckCards(highlightSourceCardId: card.id)
        }
        delayedTooltip?.cancel()
        delayedTooltip = DelayedTooltip(handler: tooltipDisplay, 0.400, ["cell": cell, "card": card])
    }

    func out(card: Card) {
        if playerType == .player {
            highlightPlayerDeckCards(highlightSourceCardId: nil)
        }
        delayedTooltip?.cancel()
        delayedTooltip = nil
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hide_floating_card),
                                        object: nil,
                                        userInfo: ["card": card])
        AppDelegate.instance().coreManager.game.windowManager.tooltipGridCards.hide()
    }

    private func tooltipDisplay(_ userInfo: Any?) {
        defer { delayedTooltip = nil }
        guard let dict = userInfo as? [String: Any?],
              let cell = dict["cell"] as? CardBar,
              let card = dict["card"] as? Card,
              let window = cell.window else {
            return
        }

        let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 388)
        let cellInWindow = cell.convert(cell.bounds, to: nil)
        let cellOnScreen = window.convertToScreen(cellInWindow)

        // Decide whether the render goes to the left or the right of the tracker.
        // The tracker used to be a window of its own, so this asked whether that
        // window's own origin left room; the row spans the panel, so its screen
        // frame answers the same question now that the panel is one of many
        // children of a full-screen overlay window.
        let x = cellOnScreen.minX < hoverFrame.width ? cellOnScreen.maxX : cellOnScreen.minX - hoverFrame.width
        let y = cellOnScreen.minY - hoverFrame.height / 2.0

        let frame = [x, y, hoverFrame.width, hoverFrame.height]
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.show_floating_card),
                                        object: nil,
                                        userInfo: ["card": card, "frame": frame, "useFrame": true])

        let game = AppDelegate.instance().coreManager.game
        let anchor = NSRect(x: x, y: y, width: hoverFrame.width, height: hoverFrame.height)
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

/// The plainer hover the two standalone card lists want: the secret helper and
/// the graveyard counter's detail list. Both show the blown-up card render and
/// nothing else - no related-cards grid, no deck highlight - which is what the
/// `CardList` window they replaced did.
///
/// `CardList` put the render to the panel's right whatever side the panel was on
/// when it was the secret helper (`isSecretPanel`), and otherwise picked the side
/// the hovered row left room for.
@available(macOS 10.15, *)
class OverlayCardListHoverHandler: NSObject, CardCellHover {
    static let secrets = OverlayCardListHoverHandler(alwaysRight: true)
    static let cardList = OverlayCardListHoverHandler(alwaysRight: false)

    private let alwaysRight: Bool

    private init(alwaysRight: Bool) {
        self.alwaysRight = alwaysRight
    }

    func hover(cell: CardBar, card: Card) {
        guard let window = cell.window else { return }
        let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 388)
        let onScreen = window.convertToScreen(cell.convert(cell.bounds, to: nil))

        let x = alwaysRight || onScreen.minX < hoverFrame.width
            ? onScreen.maxX
            : onScreen.minX - hoverFrame.width
        var y = onScreen.minY - hoverFrame.height / 2.0
        if let screen = window.screen {
            y = min(y, screen.frame.maxY - hoverFrame.height)
            y = max(y, screen.frame.minY)
        }
        let frame = [x, y, hoverFrame.width, hoverFrame.height]
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.show_floating_card),
                                        object: nil,
                                        userInfo: ["card": card, "frame": frame, "useFrame": true])
    }

    func out(card: Card) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hide_floating_card),
                                        object: nil,
                                        userInfo: ["card": card])
    }
}
