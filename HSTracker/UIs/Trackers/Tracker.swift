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
    @IBOutlet weak var playerClass: NSView!
    @IBOutlet weak var recordTracker: StringTracker!
    @IBOutlet weak var fatigueTracker: StringTracker!
    @IBOutlet weak var graveyardCounter: GraveyardCounter!
    
    var heroCard: Card?
    var animatedCards: [CardBar] = []
    var player: Player?
    var playerType: PlayerType?
    private var cellsCache = [String: NSView]()

    override func windowDidLoad() {
        super.windowDidLoad()

        let center = NSNotificationCenter.defaultCenter()
        var observers = [
            "hearthstone_running": #selector(Tracker.hearthstoneRunning(_:)),
            "hearthstone_active": #selector(Tracker.hearthstoneActive(_:)),
            "tracker_opacity": #selector(Tracker.opacityChange(_:)),
            "card_size": #selector(Tracker.cardSizeChange(_:)),
            "window_locked": #selector(Tracker.windowLockedChange(_:)),
            "auto_position_trackers": #selector(Tracker.autoPositionTrackersChange(_:))
        ]
        if playerType == .Player {
            observers.update([
                "player_draw_chance": #selector(Tracker.playerOptionFrameChange(_:)),
                "player_card_count": #selector(Tracker.playerOptionFrameChange(_:)),
                "player_cthun_frame": #selector(Tracker.playerOptionFrameChange(_:)),
                "player_yogg_frame": #selector(Tracker.playerOptionFrameChange(_:)),
                "player_deathrattle_frame": #selector(Tracker.playerOptionFrameChange(_:)),
                "show_win_loss_ratio": #selector(Tracker.playerOptionFrameChange(_:)),
                "reload_decks": #selector(Tracker.playerOptionFrameChange(_:)),
                "player_in_hand_color": #selector(Tracker.playerOptionFrameChange(_:)),
                "show_deck_name": #selector(Tracker.playerOptionFrameChange(_:))
                ])
        } else if playerType == .Opponent {
            observers.update([
                "opponent_card_count": #selector(Tracker.opponentOptionFrameChange(_:)),
                "opponent_draw_chance": #selector(Tracker.opponentOptionFrameChange(_:)),
                "opponent_cthun_frame": #selector(Tracker.opponentOptionFrameChange(_:)),
                "opponent_yogg_frame": #selector(Tracker.opponentOptionFrameChange(_:)),
                "opponent_deathrattle_frame": #selector(Tracker.opponentOptionFrameChange(_:)),
                "show_opponent_class": #selector(Tracker.opponentOptionFrameChange(_:))
                ])
        }

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
        self.window!.collectionBehavior = [.CanJoinAllSpaces, .FullScreenAuxiliary]
        
        if let panel = self.window as? NSPanel {
            panel.floatingPanel = true
        }
        
        NSWorkspace.sharedWorkspace().notificationCenter
            .addObserver(self, selector: #selector(Tracker.bringToFront),
                         name: NSWorkspaceActiveSpaceDidChangeNotification, object: nil)
        
        setWindowSizes()
        _setOpacity()
        _windowLockedChange()
        _hearthstoneRunning()
        _frameOptionsChange()
    }
    
    func bringToFront() {
        if Settings.instance.autoPositionTrackers {
            self.autoPosition()
        }
        self.window?.orderFront(nil)
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
            self.window!.styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask
        } else {
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask
                | NSResizableWindowMask | NSBorderlessWindowMask | NSNonactivatingPanelMask
        }
        
        self.window!.ignoresMouseEvents = locked
        self.window?.orderFront(nil) // must be called after style change
    }

    func hearthstoneRunning(notification: NSNotification) {
        _hearthstoneRunning()
    }
    private func _hearthstoneRunning() {
        let hs = Hearthstone.instance

        let level: Int
        if hs.hearthstoneActive {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.MainMenuWindowLevelKey))-1
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
            self.autoPosition()
        }
    }
    
    private func autoPosition() {
        if playerType == .Player {
            Game.instance.moveWindow(self,
                                     active: Hearthstone.instance.hearthstoneActive,
                                     frame: SizeHelper.playerTrackerFrame())
        } else if playerType == .Opponent {
            Game.instance.moveWindow(self,
                                     active: Hearthstone.instance.hearthstoneActive,
                                     frame: SizeHelper.opponentTrackerFrame())
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
                                             height: NSScreen.mainScreen()!.frame.height)
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
    func update(cards: [Card], reset: Bool = false) {
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

        var toUpdate = [CardBar]()
        animatedCards.forEach({ (c: CardBar) in
            if !cards.any({ self.areEqualForList($0, c.card!) }) {
                toUpdate.append(c)
            }
        })
        var toRemove: [CardBar: Bool] = [:]
        toUpdate.forEach { (card: CardBar) in
            let newCard = newCards.firstWhere({ $0.id == card.card!.id })
            toRemove[card] = newCard == nil
            if newCard != nil {
                let newAnimated = CardBar.factory()
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
            removeCard(cardCellView, fadeOut: fadeOut)
        }
        newCards.forEach({
            let newCard = CardBar.factory()
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

        let windowWidth = windowFrame.width
        let windowHeight = windowFrame.height

        let ratio: CGFloat
        switch settings.cardSize {
        case .Small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
        case .Medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
        default: ratio = 1.0
        }

        let showCthunCounter: Bool
        let showSpellCounter: Bool
        let showDeathrattleCounter: Bool
        let showGraveyard: Bool
        let proxy: Entity?

        if playerType == .Opponent {
            cardCounter.hidden = !settings.showOpponentCardCount
            opponentDrawChance.hidden = !settings.showOpponentDrawChance
            playerDrawChance.hidden = true

            showCthunCounter = WotogCounterHelper.showOpponentCthunCounter
            showSpellCounter = WotogCounterHelper.showOpponentSpellsCounter
            showDeathrattleCounter = WotogCounterHelper.showOpponentDeathrattleCounter
            showGraveyard = WotogCounterHelper.showOpponentGraveyard
            proxy = WotogCounterHelper.opponentCthunProxy
            playerClass.hidden = !settings.showOpponentClassInTracker
            recordTracker.hidden = true
        } else {
            cardCounter.hidden = !settings.showPlayerCardCount
            opponentDrawChance.hidden = true
            playerDrawChance.hidden = !settings.showPlayerDrawChance

            showCthunCounter = WotogCounterHelper.showPlayerCthunCounter
            showSpellCounter = WotogCounterHelper.showPlayerSpellsCounter
            showDeathrattleCounter = WotogCounterHelper.showPlayerDeathrattleCounter
            showGraveyard = WotogCounterHelper.showPlayerGraveyard
            proxy = WotogCounterHelper.playerCthunProxy
            playerClass.hidden = !settings.showDeckNameInTracker
            recordTracker.hidden = !settings.showWinLossRatio
        }
        fatigueTracker.hidden = !(settings.fatigueIndicator && player?.fatigue > 0)
        graveyardCounter.hidden = !showGraveyard

        if let activeDeck = Game.instance.activeDeck where !recordTracker.hidden {
            recordTracker.message = StatsHelper.getDeckManagerRecordLabel(activeDeck)
            recordTracker.needsDisplay = true
        } else {
            recordTracker.hidden = true
        }
        if let player = player where !fatigueTracker.hidden {
            fatigueTracker.message = "\(NSLocalizedString("Fatigue : ", comment: ""))"
                + "\(player.fatigue)"
            fatigueTracker.needsDisplay = true
        }

        var counterStyle: [WotogCounterStyle] = []
        if showCthunCounter && showSpellCounter && showDeathrattleCounter {
            counterStyle.append(.Full)
        } else if !showCthunCounter && !showSpellCounter && !showDeathrattleCounter {
            counterStyle.append(.None)
        } else {
            if showDeathrattleCounter {
                counterStyle.append(.Deathrattles)
            }
            if showSpellCounter {
                counterStyle.append(.Spells)
            }
            if showCthunCounter {
                counterStyle.append(.Cthun)
            }
        }

        wotogCounter.counterStyle = counterStyle
        wotogCounter.hidden = wotogCounter.counterStyle.contains(.None)
        wotogCounter.attack = proxy?.attack ?? 6
        wotogCounter.health = proxy?.health ?? 6
        wotogCounter.spell = player?.spellsPlayedCount ?? 0
        wotogCounter.deathrattle = player?.deathrattlesPlayedCount ?? 0
        
        
        if let graveyard = player?.graveyard {
            // map entitiy to card [count]
            var minionmap = [Card: Int]()
            var minions: Int = 0; var murlocks: Int = 0
            for e: Entity in graveyard {
                if e.isMinion {
                    if let value = minionmap[e.card] {
                        minionmap[e.card] = value+1
                    } else {
                        minionmap[e.card] = 1
                    }
                    minions += 1
                    if e.card.race == Race.MURLOC {
                        murlocks += 1
                    }
                }
            }
            
            var graveyardminions: [Card] = []
            for (card, count) in minionmap {
                card.count = count
                graveyardminions.append(card)
            }
            graveyardCounter.graveyard = graveyardminions
            graveyardCounter.minions = minions
            graveyardCounter.murlocks = murlocks
        }
        

        let bigFrameHeight = round(71 / ratio)
        let smallFrameHeight = round(40 / ratio)

        var offsetFrames: CGFloat = 0
        var startHeight: CGFloat = 0
        if !playerClass.hidden && playerType == .Opponent {
            if let playerClassId = Game.instance.opponent.playerClassId,
                playerName = Game.instance.opponent.name {
                
                offsetFrames += smallFrameHeight
                
                playerClass.frame = NSRect(x: 0,
                                           y: windowHeight - smallFrameHeight,
                                           width: windowHeight,
                                           height: smallFrameHeight)
                startHeight += smallFrameHeight
                
                playerClass.subviews.forEach({$0.removeFromSuperview()})
                let hero = CardBar.factory()
                hero.playerType = .Hero
                hero.playerClassID = playerClassId
                hero.playerName = playerName
                
                playerClass.addSubview(hero)
                hero.frame = NSRect(x: 0, y: 0,
                                    width: windowWidth,
                                    height: smallFrameHeight)
                hero.update(false)
            }
        } else if !playerClass.hidden && playerType == .Player {
            if let activeDeck = Game.instance.activeDeck {

                offsetFrames += smallFrameHeight
                
                playerClass.frame = NSRect(x: 0,
                                           y: windowHeight - smallFrameHeight,
                                           width: windowHeight,
                                           height: smallFrameHeight)
                startHeight += smallFrameHeight
                
                playerClass.subviews.forEach({$0.removeFromSuperview()})
                let hero = CardBar.factory()
                hero.playerType = .Hero
                hero.playerClassID = Cards.heroByPlayerClass(activeDeck.playerClass)?.id
                hero.playerName = activeDeck.name
                
                playerClass.addSubview(hero)
                hero.frame = NSRect(x: 0, y: 0,
                                    width: windowWidth,
                                    height: smallFrameHeight)
                hero.update(false)
            }
        }
        if !opponentDrawChance.hidden {
            offsetFrames += bigFrameHeight
        }
        if !playerDrawChance.hidden {
            offsetFrames += smallFrameHeight
        }
        if !cardCounter.hidden {
            offsetFrames += smallFrameHeight
        }
        if showSpellCounter {
            offsetFrames += smallFrameHeight
        }
        if showCthunCounter {
            offsetFrames += smallFrameHeight
        }
        if showDeathrattleCounter {
            offsetFrames += smallFrameHeight
        }
        if showGraveyard {
            offsetFrames += smallFrameHeight
        }
        if !recordTracker.hidden {
            offsetFrames += smallFrameHeight
        }
        if !fatigueTracker.hidden {
            offsetFrames += smallFrameHeight
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
                                 y: windowHeight - startHeight - cardViewHeight,
                                 width: windowWidth,
                                 height: cardViewHeight)

        for cell in animatedCards {
            y -= cardHeight
            cell.frame = NSRect(x: 0, y: y, width: windowWidth, height: cardHeight)
            cardsView.addSubview(cell)
        }

        y = windowHeight - startHeight - cardViewHeight
        if !cardCounter.hidden {
            y -= smallFrameHeight
            cardCounter.frame = NSRect(x: 0, y: y, width: windowWidth, height: smallFrameHeight)
        }
        if !opponentDrawChance.hidden {
            y -= bigFrameHeight
            opponentDrawChance.frame = NSRect(x: 0,
                                              y: y,
                                              width: windowWidth,
                                              height: bigFrameHeight)
        }
        if !playerDrawChance.hidden {
            y -= smallFrameHeight
            playerDrawChance.frame = NSRect(x: 0,
                                            y: y,
                                            width: windowWidth,
                                            height: smallFrameHeight)
        }
        if showCthunCounter || showSpellCounter || showDeathrattleCounter {
            var height: CGFloat = 0
            if showCthunCounter {
                height += smallFrameHeight
            }
            if showDeathrattleCounter {
                height += smallFrameHeight
            }
            if showSpellCounter {
                height += smallFrameHeight
            }
            y -= height

            wotogCounter?.frame = NSRect(x: 0, y: y, width: windowWidth, height: height)
            wotogCounter?.needsDisplay = true
        }
        if !graveyardCounter.hidden {
            y -= smallFrameHeight
            graveyardCounter?.frame = NSRect(x: 0,
                                             y: y,
                                             width: windowWidth,
                                             height: smallFrameHeight)
            if playerType == .Opponent {
                graveyardCounter?.displayDetails = settings.showOpponentGraveyardDetails
            } else {
                graveyardCounter?.displayDetails = settings.showPlayerGraveyardDetails
            }
            graveyardCounter?.cardHeight = cardHeight
            graveyardCounter?.needsDisplay = true
        }
        if !recordTracker.hidden {
            y -= smallFrameHeight
            recordTracker.frame = NSRect(x: 0,
                                         y: y,
                                         width: windowWidth,
                                         height: smallFrameHeight)
        }
        if !fatigueTracker.hidden {
            y -= smallFrameHeight
            fatigueTracker.frame = NSRect(x: 0,
                                         y: y,
                                         width: windowWidth,
                                         height: smallFrameHeight)
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

    private func removeCard(card: CardBar, fadeOut: Bool) {
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
    func hover(cell: CardBar, card: Card) {
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
                                + rect.origin.y - (hoverFrame.height / 2))
        if let screen = self.window?.screen {
            if y + hoverFrame.height > screen.frame.height {
                y = screen.frame.height - hoverFrame.height
            }
        }
        let frame = [x, y, hoverFrame.width, hoverFrame.height]
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
