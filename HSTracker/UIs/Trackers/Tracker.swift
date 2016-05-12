/*
* This file is part of the HSTracker package.
* (c) Benjamin Michotte <bmichotte@gmail.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*
* Created on 15/02/16.
*/

import Cocoa
import CleanroomLogger

// TODO not yet implemented
enum HandCountPosition: Int {
    case Tracker,
    Window
}

class Tracker: NSWindowController {

    @IBOutlet weak var cardsView: NSView!
    @IBOutlet weak var cardCounter: CardCounter!
    @IBOutlet weak var playerDrawChance: PlayerDrawChance!
    @IBOutlet weak var opponentDrawChance: OpponentDrawChance!
    @IBOutlet weak var wotogCounter: WotogCounter!

    var heroCard: Card?
    var animatedCards = [CardCellView]()
    var player: Player?
    var playerType: PlayerType?
    private var cellsCache = [String: NSView]()

    override func windowDidLoad() {
        super.windowDidLoad()

        let center = NSNotificationCenter.defaultCenter()
        let observers = [
            "hearthstone_running": #selector(Tracker.hearthstoneRunning(_:)),
            "hearthstone_active": #selector(Tracker.hearthstoneActive(_:)),
            "tracker_opacity": #selector(Tracker.opacityChange(_:)),
            "card_size": #selector(Tracker.cardSizeChange(_:)),
            "window_locked": #selector(Tracker.windowLockedChange(_:)),
            "auto_position_trackers": #selector(Tracker.autoPositionTrackersChange(_:)),

            "player_draw_chance": #selector(Tracker.playerOptionFrameChange(_:)),
            "player_card_count": #selector(Tracker.playerOptionFrameChange(_:)),
            "player_cthun_frame": #selector(Tracker.playerOptionFrameChange(_:)),
            "player_yogg_frame": #selector(Tracker.playerOptionFrameChange(_:)),

            "opponent_card_count": #selector(Tracker.opponentOptionFrameChange(_:)),
            "opponent_draw_chance": #selector(Tracker.opponentOptionFrameChange(_:)),
            "opponent_cthun_frame": #selector(Tracker.opponentOptionFrameChange(_:)),
            "opponent_yogg_frame": #selector(Tracker.opponentOptionFrameChange(_:)),
        ]

        for (name, selector) in observers {
            center.addObserver(self,
                               selector: selector,
                               name: name,
                               object: nil)
        }

        let options = ["show_opponent_draw", "show_opponent_mulligan", "show_opponent_play",
            "show_player_draw", "show_player_mulligan", "show_player_play", "rarity_colors",
            "remove_cards_from_deck", "highlight_last_drawn", "highlight_cards_in_hand",
            "highlight_discarded", "show_player_get"]
        for option in options {
            center.addObserver(self,
                               selector: #selector(Tracker.trackerOptionsChange(_:)),
                               name: option,
                               object: nil)
        }

        let frames = [ "player_draw_chance", "player_card_count",
                       "opponent_card_count", "opponent_draw_chance"]
        for name in frames {
            center.addObserver(self,
                               selector: #selector(Tracker.frameOptionsChange(_:)),
                               name: name,
                               object: nil)
        }

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.acceptsMouseMovedEvents = true

        setWindowSizes()
        _setOpacity()
        _windowLockedChange()
        _hearthstoneRunning()
        _frameOptionsChange()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - Notifications
    func windowLockedChange(notification: NSNotification) {
        _windowLockedChange()
    }
    private func _windowLockedChange() {
        let locked = Settings.instance.windowsLocked
        if locked {
            self.window!.styleMask = NSBorderlessWindowMask
        } else {
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask
                | NSResizableWindowMask | NSBorderlessWindowMask
        }
        self.window!.ignoresMouseEvents = locked
    }

    func hearthstoneRunning(notification: NSNotification) {
        _hearthstoneRunning()
    }
    private func _hearthstoneRunning() {
        let hs = Hearthstone.instance

        let level: Int
        if hs.hearthstoneActive {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
        self.window!.level = level
    }

    func hearthstoneActive(notification: NSNotification) {
        _windowLockedChange()
        _hearthstoneRunning()
    }

    func trackerOptionsChange(notification: NSNotification) {
        _frameOptionsChange()
    }

    func cardSizeChange(notification: NSNotification) {
        _frameOptionsChange()
        setWindowSizes()
    }

    func playerOptionFrameChange(notification: NSNotification) {
        if playerType == .Player {
            Game.instance.updatePlayerTracker(true)
        }
    }

    func opponentOptionFrameChange(notification: NSNotification) {
        if playerType == .Opponent {
            Game.instance.updateOpponentTracker(true)
        }
    }

    func autoPositionTrackersChange(notification: NSNotification) {
        if Settings.instance.autoPositionTrackers {
            if playerType == .Player {
                Game.instance.changeTracker(self,
                                            Hearthstone.instance.hearthstoneActive,
                                            SizeHelper.playerTrackerFrame())
            } else if playerType == .Opponent {
                Game.instance.changeTracker(self,
                                            Hearthstone.instance.hearthstoneActive,
                                            SizeHelper.opponentTrackerFrame())
            }
        }
    }

    func setWindowSizes() {
        var width: Double
        let settings = Settings.instance
        switch settings.cardSize {
        case .Small:
            width = kSmallFrameWidth

        case .Medium:
            width = kMediumFrameWidth

        default:
            width = kFrameWidth
        }

        self.window!.contentMinSize = NSSize(width: CGFloat(width), height: 400)
        self.window!.contentMaxSize = NSSize(width: CGFloat(width),
                                             height: NSHeight(NSScreen.mainScreen()!.frame))
    }

    func opacityChange(notification: NSNotification) {
        _setOpacity()
    }
    private func _setOpacity() {
        let alpha = CGFloat(Settings.instance.trackerOpacity / 100.0)
        self.window!.backgroundColor = NSColor(red: 0,
                                               green: 0,
                                               blue: 0,
                                               alpha: alpha)
    }

    func frameOptionsChange(notification: NSNotification) {
        _frameOptionsChange()
    }

    private func _frameOptionsChange() {
        if playerType == .Player {
            Game.instance.updatePlayerTracker()
        } else if playerType == .Opponent {
            Game.instance.updateOpponentTracker()
        }
    }

    // MARK: - Game
    func update(cards: [Card], _ reset: Bool = false) {
        if reset {
            cellsCache.removeAll()
            animatedCards.removeAll()
        }

        var newCards = [Card]()
        cards.forEach({ (card: Card) in
            let existing = animatedCards.firstWhere({ self.areEqualForList($0.card!, card) })
            if existing == nil {
                newCards.append(card)
            } else if existing!.card!.count != card.count
                || existing!.card!.highlightInHand != card.highlightInHand {
                let highlight = existing!.card!.count != card.count
                existing!.card!.count = card.count
                existing!.card!.highlightInHand = card.highlightInHand
                existing!.update(highlight)
            } else if existing!.card!.isCreated != card.isCreated {
                existing!.update(false)
            }
        })

        var toUpdate = [CardCellView]()
        animatedCards.forEach({ (c: CardCellView) in
            if !cards.any({ self.areEqualForList($0, c.card!) }) {
                toUpdate.append(c)
            }
        })
        var toRemove: [CardCellView: Bool] = [:]
        toUpdate.forEach { (card: CardCellView) in
            let newCard = newCards.firstWhere({ $0.id == card.card!.id })
            toRemove[card] = newCard == nil
            if newCard != nil {
                let newAnimated = CardCellView()
                newAnimated.playerType = self.playerType
                newAnimated.setDelegate(self)
                newAnimated.card = newCard

                let index = animatedCards.indexOf(card)!
                animatedCards.insert(newAnimated, atIndex: index)
                newAnimated.update(true)
                newCards.remove(newCard!)
            }
        }
        for (cardCellView, fadeOut) in toRemove {
            removeCard(cardCellView, fadeOut)
        }
        newCards.forEach({
            let newCard = CardCellView()
            newCard.playerType = self.playerType
            newCard.setDelegate(self)
            newCard.card = $0
            let index = cards.indexOf($0)!
            animatedCards.insert(newCard, atIndex: index)
            newCard.fadeIn(!reset)
        })

        updateCountFrames()
        updateCardFrames()
    }

    private func updateCardFrames() {
        guard let windowFrame = self.window?.contentView?.frame else { return }
        let settings = Settings.instance

        let windowWidth = NSWidth(windowFrame)
        let windowHeight = NSHeight(windowFrame)

        let ratio: CGFloat
        switch settings.cardSize {
        case .Small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
        case .Medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
        default: ratio = 1.0
        }

        let showCthunCounter: Bool
        let showSpellCounter: Bool
        let proxy: Entity?

        if playerType == .Opponent {
            cardCounter.hidden = !settings.showOpponentCardCount
            opponentDrawChance.hidden = !settings.showOpponentDrawChance
            playerDrawChance.hidden = true

            showCthunCounter = WotogCounterHelper.showOpponentCthunCounter
            showSpellCounter = WotogCounterHelper.showOpponentSpellsCounter
            proxy = WotogCounterHelper.opponentCthunProxy
        } else {
            cardCounter.hidden = !settings.showPlayerCardCount
            opponentDrawChance.hidden = true
            playerDrawChance.hidden = !settings.showPlayerDrawChance

            showCthunCounter = WotogCounterHelper.showPlayerCthunCounter
            showSpellCounter = WotogCounterHelper.showPlayerSpellsCounter
            proxy = WotogCounterHelper.playerCthunProxy
        }
        wotogCounter.counterStyle = showCthunCounter && showSpellCounter
            ? .Full : (showCthunCounter ? .Cthun : (showSpellCounter ? .Spells : .None))
        wotogCounter.hidden = wotogCounter.counterStyle == .None
        wotogCounter.attack = proxy?.attack ?? 6
        wotogCounter.health = proxy?.health ?? 6
        wotogCounter.spell = player?.spellsPlayedCount ?? 0

        let opponentDrawChanceHeight = round(71 / ratio)
        let playerDrawChanceHeight = round(40 / ratio)
        let cardCounterHeight = round(40 / ratio)
        let cthunCounterHeight = round(40 / ratio)
        let yoggCounterHeight = round(40 / ratio)

        var offsetFrames: CGFloat = 0
        if !opponentDrawChance.hidden {
            offsetFrames += opponentDrawChanceHeight
        }
        if !playerDrawChance.hidden {
            offsetFrames += playerDrawChanceHeight
        }
        if !cardCounter.hidden {
            offsetFrames += cardCounterHeight
        }
        if showSpellCounter {
            offsetFrames += yoggCounterHeight
        }
        if showCthunCounter {
            offsetFrames += cthunCounterHeight
        }

        var cardHeight: CGFloat
        switch settings.cardSize {
        case .Small: cardHeight = CGFloat(kSmallRowHeight)
        case .Medium: cardHeight = CGFloat(kMediumRowHeight)
        default: cardHeight = CGFloat(kRowHeight)
        }
        if animatedCards.count > 0 {
            cardHeight = round(min(cardHeight,
                (windowHeight - offsetFrames) / CGFloat(animatedCards.count)))
        }
        for view in cardsView.subviews {
            view.removeFromSuperview()
        }

        let cardViewHeight = CGFloat(animatedCards.count) * cardHeight
        var y: CGFloat = cardViewHeight
        cardsView.frame = NSRect(x: 0,
                                 y: windowHeight - cardViewHeight,
                                 width: windowWidth,
                                 height: cardViewHeight)

        for cell in animatedCards {
            y -= cardHeight
            cell.frame = NSRect(x: 0, y: y, width: windowWidth, height: cardHeight)
            cardsView.addSubview(cell)
        }

        y = windowHeight - cardViewHeight
        if !cardCounter.hidden {
            y -= cardCounterHeight
            cardCounter.frame = NSRect(x: 0, y: y, width: windowWidth, height: cardCounterHeight)
        }
        if !opponentDrawChance.hidden {
            y -= opponentDrawChanceHeight
            opponentDrawChance.frame = NSRect(x: 0,
                                              y: y,
                                              width: windowWidth,
                                              height: opponentDrawChanceHeight)
        }
        if !playerDrawChance.hidden {
            y -= playerDrawChanceHeight
            playerDrawChance.frame = NSRect(x: 0,
                                            y: y,
                                            width: windowWidth,
                                            height: playerDrawChanceHeight)
        }
        if showCthunCounter || showSpellCounter {
            var height: CGFloat = 0
            if showCthunCounter {
                height += cthunCounterHeight
            }
            if showSpellCounter {
                height += yoggCounterHeight
            }
            y -= height

            wotogCounter?.frame = NSRect(x: 0, y: y, width: windowWidth, height: height)
            wotogCounter?.needsDisplay = true
        }
    }

    func updateCountFrames() {
        let gameStarted = !Game.instance.isInMenu && Game.instance.entities.count >= 67
        let deckCount: Int
        let handCount: Int
        if let player = player {
            deckCount = !gameStarted ? 30 : player.deckCount
            handCount = !gameStarted ? 0 : player.handCount
        } else {
            deckCount = 30
            handCount = 0
        }

        cardCounter?.deckCount = deckCount
        cardCounter?.handCount = handCount
        cardCounter?.needsDisplay = true

        if playerType == .Opponent {
            var draw1 = 0.0, draw2 = 0.0, hand1 = 0.0, hand2 = 0.0
            if deckCount > 0 {
                draw1 = (1 * 100.0) / Double(deckCount)
                draw2 = (2 * 100.0) / Double(deckCount)
            }
            if gameStarted {
                // opponent's chances of having a particular card (of which they have either one
                // or two in the deck) after the next draw, i.e. at the start of their next turn
                if deckCount <= 1 {
                    // opponent will have drawn all his cards
                    hand1 = 100
                    hand2 = 100
                } else {
                    let handMinusCoin = handCount - (player?.hasCoin == true ? 1 : 0)
                    let deckPlusHand = deckCount + handMinusCoin

                    // probabilities a given card (and a second one) are still in the deck
                    let prob1 = Double(deckCount - 1) / Double(deckPlusHand)
                    let prob2 = prob1 * Double(deckCount - 2) / Double(deckPlusHand - 1)

                    hand1 = 100 * (1 - prob1)
                    hand2 = 100 * (1 - prob2)
                }
            }
            opponentDrawChance?.drawChance1 = draw1
            opponentDrawChance?.drawChance2 = draw2
            opponentDrawChance?.handChance1 = hand1
            opponentDrawChance?.handChance2 = hand2
            opponentDrawChance?.needsDisplay = true
        } else {
            var draw1 = 0.0, draw2 = 0.0
            if deckCount > 0 {
                draw1 = (1 * 100.0) / Double(deckCount)
                draw2 = (2 * 100.0) / Double(deckCount)
            }

            playerDrawChance?.drawChance1 = draw1
            playerDrawChance?.drawChance2 = draw2
            playerDrawChance?.needsDisplay = true
        }
    }

    private func removeCard(card: CardCellView, _ fadeOut: Bool) {
        if fadeOut {
            card.fadeOut(card.card!.count > 0)
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(600 * Double(NSEC_PER_MSEC)))
            let queue = dispatch_get_main_queue()
            dispatch_after(when, queue) {
                self.animatedCards.remove(card)
            }
        } else {
            animatedCards.remove(card)
        }
    }

    private func areEqualForList(c1: Card, _ c2: Card) -> Bool {
        return c1.id == c2.id && c1.jousted == c2.jousted && c1.isCreated == c2.isCreated
            && (!Settings.instance.highlightDiscarded || c1.wasDiscarded == c2.wasDiscarded)
    }
}

// MARK: - NSWindowDelegate
extension Tracker: NSWindowDelegate {
    func windowDidResize(notification: NSNotification) {
        _frameOptionsChange()
        onWindowMove()
    }

    func windowDidMove(notification: NSNotification) {
        onWindowMove()
    }

    private func onWindowMove() {
        let settings = Settings.instance
        if playerType == .Player {
            settings.playerTrackerFrame = self.window?.frame
        } else {
            settings.opponentTrackerFrame = self.window?.frame
        }
    }
}

// MARK: - CardCellHover
extension Tracker: CardCellHover {
    func hover(cell: CardCellView, _ card: Card) {
        let rect = cell.frame

        let windowRect = self.window!.frame

        let hoverFrame = NSRect(x: 0, y: 0, width: 200, height: 300)

        var x: CGFloat
        if windowRect.origin.x < hoverFrame.size.width {
            x = windowRect.origin.x + windowRect.size.width
        } else {
            x = windowRect.origin.x - hoverFrame.size.width
        }

        var y: CGFloat = max(30,
                             windowRect.origin.y + cardsView.frame.origin.y
                                + rect.origin.y - (NSHeight(hoverFrame) / 2))
        if let screen = self.window?.screen {
            if y + NSHeight(hoverFrame) > NSHeight(screen.frame) {
                y = NSHeight(screen.frame) - NSHeight(hoverFrame)
            }
        }
        let frame = [x, y, NSWidth(hoverFrame), NSHeight(hoverFrame)]
        NSNotificationCenter.defaultCenter()
            .postNotificationName("show_floating_card",
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": frame
                ])
    }

    func out(card: Card) {
        NSNotificationCenter.defaultCenter().postNotificationName("hide_floating_card", object: nil)
    }
}
