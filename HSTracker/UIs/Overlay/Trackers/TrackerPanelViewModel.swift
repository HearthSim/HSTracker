//
//  TrackerPanelViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftUI

/// One deck tracker on the overlay canvas - HDT's `BorderStackPanelPlayer` /
/// `BorderStackPanelOpponent` and the `StackPanelPlayer` / `StackPanelOpponent`
/// inside them (`Windows/OverlayWindow.xaml`).
///
/// It replaces the `Tracker` window controller, which drew the same sections into
/// a borderless `NSPanel` of its own and laid them out by hand in `updateFrames`.
/// The sections themselves are unchanged - see `TrackerSectionViews` - so this
/// holds what they display, where the panel sits, and the height the card rows
/// have to shrink into.
@available(macOS 10.15, *)
class TrackerPanelViewModel: ObservableObject {
    let playerType: PlayerType

    init(playerType: PlayerType) {
        self.playerType = playerType
        self.top = playerType == .opponent ? Settings.opponentDeckTop : Settings.playerDeckTop
        self.left = playerType == .opponent ? Settings.opponentDeckLeft : Settings.playerDeckLeft
        self.height = playerType == .opponent ? Settings.opponentDeckHeight : Settings.playerDeckHeight
        self.scaling = playerType == .opponent ? Settings.overlayOpponentScaling : Settings.overlayPlayerScaling
        self.opacity = playerType == .opponent ? Settings.opponentOpacity : Settings.playerOpacity
        self.panelOrder = DeckPanel.order(for: playerType)
    }

    // MARK: - Visibility

    @Published var isShown = false

    // MARK: - Content

    @Published private(set) var cards = TrackerCardListContent()
    @Published private(set) var topCards = TrackerCardListContent()
    @Published private(set) var bottomCards = TrackerCardListContent()
    @Published private(set) var relatedCards = TrackerCardListContent()
    @Published private(set) var packageCards = TrackerCardListContent()
    @Published private(set) var packageLabel = ""
    @Published private(set) var sideboards: [Sideboard] = []
    @Published private(set) var sideboardsVersion = 0
    @Published private(set) var sideboardsReset = false

    private var contentVersion = 0

    /// Only the two sideboards `DeckSideboards` knows how to draw count towards
    /// the panel's layout - E.T.C.'s band and King of the Underbelly's.
    var sideboardCardCount: Int {
        sideboardBoxes.reduce(0) { $0 + $1.cards.count }
    }

    /// How many of those two boxes are non-empty, each of which draws a header of
    /// its own.
    var sideboardBoxCount: Int { sideboardBoxes.count }

    private var sideboardBoxes: [Sideboard] {
        sideboards.filter {
            ($0.ownerCardId == CardIds.Collectible.Neutral.ETCBandManager
             || $0.ownerCardId == CardIds.Collectible.Hunter.KingOfTheUnderbelly)
                && !$0.cards.isEmpty
        }
    }

    /// HDT's OverlayCenterPlayerStackPanel / OverlayCenterOpponentStackPanel.
    var isCentered: Bool {
        playerType == .opponent ? Settings.overlayCenterOpponentStack : Settings.overlayCenterPlayerStack
    }

    /// `Tracker.update(cards:top:bottom:sideboards:relatedCards:...)`, which is
    /// what `Game.updatePlayerTracker` / `updateOpponentTracker` still call.
    func update(cards: [Card], top: [Card], bottom: [Card], sideboards: [Sideboard], relatedCards: [Card],
                packageCards: [Card] = [], packageLabel: String = "", reset: Bool = false) {
        contentVersion += 1
        let version = contentVersion
        self.cards = TrackerCardListContent(cards: cards, version: version, reset: reset)
        self.topCards = TrackerCardListContent(cards: top, version: version, reset: reset)
        self.bottomCards = TrackerCardListContent(cards: bottom, version: version, reset: reset)
        self.relatedCards = TrackerCardListContent(cards: relatedCards, version: version, reset: reset)
        self.packageCards = TrackerCardListContent(cards: packageCards, version: version, reset: reset)
        self.packageLabel = packageLabel
        self.sideboards = sideboards
        self.sideboardsVersion = version
        self.sideboardsReset = reset
    }

    // MARK: - Counters

    @Published private(set) var handCount = 0
    @Published private(set) var deckCount = 30
    @Published private(set) var drawChance1 = 0.0
    @Published private(set) var drawChance2 = 0.0
    @Published private(set) var opponentHandChance1 = 0.0
    @Published private(set) var opponentHandChance2 = 0.0

    /// `Tracker.updateCardCounter`, carried over unchanged - including the
    /// opponent's "chance they are already holding it next turn" maths, which is
    /// HSTracker's own rather than HDT's `Helper.DrawProbability`.
    func updateCardCounter(deckCount: Int, handCount: Int, hasCoin: Bool, gameStarted: Bool) {
        self.deckCount = deckCount
        self.handCount = handCount

        var draw1 = 0.0, draw2 = 0.0
        if deckCount > 0 {
            draw1 = (1 * 100.0) / Double(deckCount)
            draw2 = (2 * 100.0) / Double(deckCount)
        }
        drawChance1 = draw1
        drawChance2 = draw2

        guard playerType == .opponent else { return }

        var hand1 = 0.0, hand2 = 0.0
        if gameStarted {
            // opponent's chances of having a particular card (of which they have either one
            // or two in the deck) after the next draw, i.e. at the start of their next turn
            if deckCount <= 1 {
                // opponent will have drawn all his cards
                hand1 = 100
                hand2 = 100
            } else {
                let maxDeckSize = max(30, deckCount)

                // Deck size after the opponent draws
                let nextDeckSize = deckCount - 1

                // probability a given card has been drawn if there is one copy in the deck
                hand1 = Double(maxDeckSize - nextDeckSize) / Double(maxDeckSize)

                // probability a given card has been drawn if there are two copies in the deck
                let prob2 = Double((maxDeckSize - 1) - nextDeckSize) / Double(maxDeckSize - 1)
                hand2 = 2 * hand1 - (hand1 * prob2)

                hand1 *= 100
                hand2 *= 100
            }
        }
        opponentHandChance1 = hand1
        opponentHandChance2 = hand2
    }

    // MARK: - Graveyard

    @Published var showGraveyard = false
    @Published private(set) var graveyardMinions: [Card] = []
    @Published private(set) var graveyardMinionCount = 0
    @Published private(set) var graveyardMurlocCount = 0
    @Published private(set) var graveyardVersion = 0
    /// Whether the counter opens its card list on hover -
    /// `Settings.showPlayer/OpponentGraveyardDetails`.
    var graveyardDetails: Bool {
        playerType == .opponent ? Settings.showOpponentGraveyardDetails : Settings.showPlayerGraveyardDetails
    }
    /// The id the opponent stack reports its own hover region under - HDT gives
    /// StackPanelOpponent `IsOverlayHoverVisible="True"` so the
    /// link-opponent-deck prompt can follow the cursor onto the deck list
    /// without the list ever taking a click.
    static let opponentStackHoverRegionID = "opponentDeckStack"

    /// The id the graveyard counter's hover region is reported under, so
    /// RootOverlayWindow can tell the two sides' counters apart.
    var graveyardHoverRegionID: String {
        playerType == .opponent ? "opponentGraveyardCounter" : "playerGraveyardCounter"
    }

    /// The entity-to-card fold `Tracker.updateFrames` did on every pass.
    func setGraveyard(_ graveyard: [Entity]?) {
        var minionmap: [Card: Int] = [:]
        var minions = 0
        var murlocks = 0
        if let graveyard {
            for e: Entity in graveyard where e.isMinion {
                if let value = minionmap[e.card] {
                    minionmap[e.card] = value + 1
                } else {
                    minionmap[e.card] = 1
                }
                minions += 1
                if e.card.race == .murloc {
                    murlocks += 1
                }
            }
        }
        var cards: [Card] = []
        for (card, count) in minionmap {
            card.count = count
            cards.append(card)
        }
        let sorted = cards.sortCardList()
        guard minions != graveyardMinionCount || murlocks != graveyardMurlocCount
                || sorted.map({ "\($0.id)x\($0.count)" }) != graveyardMinions.map({ "\($0.id)x\($0.count)" }) else {
            return
        }
        graveyardMinions = sorted
        graveyardMinionCount = minions
        graveyardMurlocCount = murlocks
        graveyardVersion += 1
    }

    // MARK: - Hero bar and record

    @Published var playerClassId: String?
    @Published var playerName: String?
    @Published var recordMessage = ""

    // MARK: - Placement
    //
    // HDT's Config.PlayerDeckTop / PlayerDeckLeft / PlayerDeckHeight and their
    // opponent twins, plus OverlayPlayerScaling and PlayerOpacity. All are
    // percentages, as HDT stores them.

    @Published var top: Double
    @Published var left: Double
    @Published var height: Double
    @Published var scaling: Double
    @Published var opacity: Double

    /// The section order, reloaded when the settings change.
    @Published var panelOrder: [DeckPanel]

    func reloadSettings() {
        // Game asks for a tracker update on nearly every log event, and the drag
        // below only writes its percentages back on mouse up - so re-reading them
        // mid-drag would snap the panel back under the cursor.
        if lastDragTranslation == nil {
            top = playerType == .opponent ? Settings.opponentDeckTop : Settings.playerDeckTop
            left = playerType == .opponent ? Settings.opponentDeckLeft : Settings.playerDeckLeft
            height = playerType == .opponent ? Settings.opponentDeckHeight : Settings.playerDeckHeight
        }
        scaling = playerType == .opponent ? Settings.overlayOpponentScaling : Settings.overlayPlayerScaling
        opacity = playerType == .opponent ? Settings.opponentOpacity : Settings.playerOpacity
        panelOrder = DeckPanel.order(for: playerType)
    }

    private func save() {
        if playerType == .opponent {
            Settings.opponentDeckTop = top
            Settings.opponentDeckLeft = left
            Settings.opponentDeckHeight = height
        } else {
            Settings.playerDeckTop = top
            Settings.playerDeckLeft = left
            Settings.playerDeckHeight = height
        }
    }

    // MARK: - Dragging and resizing

    private var lastDragTranslation: CGSize?

    /// HDT drags a stack by adding the raw mouse delta to the stored percentages
    /// (`OverlayWindow.Input.cs`: `PlayerDeckTop += delta.Y / Height`, where delta
    /// is the per-move pixel delta pre-multiplied by 100). SwiftUI reports a
    /// running total instead of a per-event delta, so the increment is taken
    /// against the previous translation.
    func drag(translation: CGSize, canvasSize: CGSize) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let previous = lastDragTranslation ?? .zero
        let dx = translation.width - previous.width
        let dy = translation.height - previous.height
        lastDragTranslation = translation

        top += Double(dy / canvasSize.height) * 100.0
        left += Double(dx / canvasSize.width) * 100.0
    }

    /// The `ResizeGrip` HDT puts on the stack's bottom-right corner, which only
    /// changes the height and clamps it at 5% of the client
    /// (`OverlayWindow.Input.cs`).
    func resize(translation: CGSize, canvasSize: CGSize) {
        guard canvasSize.height > 0 else { return }
        let previous = lastDragTranslation ?? .zero
        let dy = translation.height - previous.height
        lastDragTranslation = translation

        height = max(height + Double(dy / canvasSize.height) * 100.0, 5)
    }

    /// `MouseInputOnLmbUp` saves the config once the drag finishes.
    func endDrag() {
        lastDragTranslation = nil
        save()
    }

    /// The trackers used to be windows of their own, dragged to an absolute screen
    /// rect. Convert that rect into the percentages above the first time there is
    /// a Hearthstone frame to measure it against, so a player who moved a tracker
    /// keeps it where they put it. The old rects were only honoured when trackers
    /// were not auto-positioned, so neither is this.
    static func migratePlacementIfNeeded() {
        guard !Settings.migratedTrackerPlacement else { return }
        let hearthstone = SizeHelper.hearthstoneWindow.frame
        guard hearthstone.width > 0, hearthstone.height > 0 else { return }

        if !Settings.autoPositionTrackers {
            if let saved = Settings.playerTrackerFrame, saved.width > 0, saved.height > 0 {
                // The player stack hangs its right edge on PlayerDeckLeft.
                Settings.playerDeckLeft = Double((saved.maxX - hearthstone.minX) / hearthstone.width) * 100.0
                Settings.playerDeckTop = Double((hearthstone.maxY - saved.maxY) / hearthstone.height) * 100.0
                Settings.playerDeckHeight = Double(saved.height / hearthstone.height) * 100.0
            }
            if let saved = Settings.opponentTrackerFrame, saved.width > 0, saved.height > 0 {
                Settings.opponentDeckLeft = Double((saved.minX - hearthstone.minX) / hearthstone.width) * 100.0
                Settings.opponentDeckTop = Double((hearthstone.maxY - saved.maxY) / hearthstone.height) * 100.0
                Settings.opponentDeckHeight = Double(saved.height / hearthstone.height) * 100.0
            }
        }

        // The single tracker_opacity was the window background's alpha, where 0
        // meant "no backing at all" rather than "invisible tracker". HDT's
        // PlayerOpacity is the stack's own opacity and defaults to fully opaque,
        // so the old value has no sensible reading as one - it is left alone.
        Settings.migratedTrackerPlacement = true
    }
}
