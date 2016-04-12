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

enum HandCountPosition: Int {
    case Tracker,
    Window
}

class Tracker: NSWindowController, NSWindowDelegate, CardCellHover {
    
    @IBOutlet weak var cardsView: NSView!
    
    @IBOutlet weak var cardCounter: CardCounter!
    @IBOutlet weak var playerDrawChance: PlayerDrawChance!
    @IBOutlet weak var opponentDrawChance: OpponentDrawChance!
    
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
        
        let frames = [ "player_draw_chance", "player_card_count", "opponent_card_count", "opponent_draw_chance"]
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
        _hearthstoneRunning(true)
        _frameOptionsChange()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - NSWindowDelegate
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
        }
        else {
            settings.opponentTrackerFrame = self.window?.frame
        }
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
            self.window!.styleMask = NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSBorderlessWindowMask
        }
        self.window!.ignoresMouseEvents = locked
    }
    
    func hearthstoneRunning(notification: NSNotification) {
        _hearthstoneRunning(false)
    }
    private func _hearthstoneRunning(forceActive: Bool) {
        let hs = Hearthstone.instance
        
        if hs.isHearthstoneRunning && (forceActive || hs.hearthstoneActive) {
            self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        }
        else {
            self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
    }
    
    func hearthstoneActive(notification: NSNotification) {
        _windowLockedChange()
        _hearthstoneRunning(false)
    }
    
    func trackerOptionsChange(notification: NSNotification) {
        _frameOptionsChange()
    }
    
    func cardSizeChange(notification: NSNotification) {
        _frameOptionsChange()
        setWindowSizes()
    }
    
    func autoPositionTrackersChange(notification: NSNotification) {
        if Settings.instance.autoPositionTrackers {
            if playerType == .Player {
                Game.instance.changeTracker(self,
                                            Hearthstone.instance.hearthstoneActive,
                                            SizeHelper.playerTrackerFrame())
            }
            else if playerType == .Opponent {
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
        
        self.window!.contentMinSize = NSMakeSize(CGFloat(width), 400)
        self.window!.contentMaxSize = NSMakeSize(CGFloat(width), NSHeight(NSScreen.mainScreen()!.frame))
    }
    
    func opacityChange(notification: NSNotification) {
        _setOpacity()
    }
    private func _setOpacity() {
        self.window!.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(Settings.instance.trackerOpacity / 100.0))
    }
    
    func frameOptionsChange(notification: NSNotification) {
        _frameOptionsChange()
    }
    
    private func _frameOptionsChange() {
        if playerType == .Player {
            Game.instance.updatePlayerTracker()
        }
        else if playerType == .Opponent {
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
            }
            else if existing!.card!.count != card.count || existing!.card!.highlightInHand != card.highlightInHand {
                let highlight = existing!.card!.count != card.count
                existing!.card!.count = card.count
                existing!.card!.highlightInHand = card.highlightInHand
                existing!.update(highlight)
            }
            else if existing!.card!.isCreated != card.isCreated {
                existing!.update(false)
            }
        })

        var toUpdate = [CardCellView]()
        animatedCards.forEach({ (c: CardCellView) in
            if !cards.any({ self.areEqualForList($0, c.card!) }) {
                toUpdate.append(c)
            }
        })
        var toRemove:[CardCellView: Bool] = [:]
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
        
        setCardCount()
        
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

        if playerType == .Opponent {
            cardCounter.hidden = !settings.showOpponentCardCount
            opponentDrawChance.hidden = !settings.showOpponentDrawChance
            playerDrawChance.hidden = true
        }
        else {
            cardCounter.hidden = !settings.showPlayerCardCount
            opponentDrawChance.hidden = true
            playerDrawChance.hidden = !settings.showPlayerDrawChance
        }

        let opponentDrawChanceHeight = round(71 / ratio)
        let playerDrawChanceHeight = round(40 / ratio)
        let cardCounterHeight = round(40 / ratio)
        
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
        
        var cardHeight: CGFloat
        switch settings.cardSize {
        case .Small: cardHeight = CGFloat(kSmallRowHeight)
        case .Medium: cardHeight = CGFloat(kMediumRowHeight)
        default: cardHeight = CGFloat(kRowHeight)
        }
        if animatedCards.count > 0 {
            cardHeight = round(min(cardHeight, (windowHeight - offsetFrames) / CGFloat(animatedCards.count)))
        }
        for view in cardsView.subviews {
            view.removeFromSuperview()
        }
        
        let cardViewHeight = CGFloat(animatedCards.count) * cardHeight
        var y: CGFloat = cardViewHeight
        cardsView.frame = NSMakeRect(0, windowHeight - cardViewHeight, windowWidth, cardViewHeight)
        
        for cell in animatedCards {
            y -= cardHeight
            cell.frame = NSMakeRect(0, y, windowWidth, cardHeight)
            cardsView.addSubview(cell)
        }
        
        y = windowHeight - cardViewHeight
        if !cardCounter.hidden {
            y -= cardCounterHeight
            cardCounter.frame = NSMakeRect(0, y, windowWidth, cardCounterHeight)
        }
        if !opponentDrawChance.hidden {
            y -= opponentDrawChanceHeight
            opponentDrawChance.frame = NSMakeRect(0, y, windowWidth, opponentDrawChanceHeight)
        }
        if !playerDrawChance.hidden {
            y -= playerDrawChanceHeight
            playerDrawChance.frame = NSMakeRect(0, y, windowWidth, playerDrawChanceHeight)
        }
    }
    
    func setCardCount() {
        let gameStarted = !Game.instance.isInMenu && Game.instance.entities.count >= 67
        let deckCount = !gameStarted || player == nil ? 30 : player!.deckCount
        let handCount = !gameStarted || player == nil ? 0 : player!.handCount
        
        cardCounter.deckCount = deckCount
        cardCounter.handCount = handCount
        cardCounter.layer?.setNeedsDisplay()
        
        if playerType == .Opponent {
            var draw1 = 0.0, draw2 = 0.0, hand1 = 0.0, hand2 = 0.0
            if deckCount > 0 {
                draw1 = (1 * 100.0) / Double(deckCount)
                draw2 = (2 * 100.0) / Double(deckCount)
            }
            if handCount > 0 {
                hand1 = (1 * 100.0) / Double(handCount)
                hand2 = (2 * 100.0) / Double(handCount)
            }
            opponentDrawChance.drawChance1 = draw1
            opponentDrawChance.drawChance2 = draw2
            opponentDrawChance.handChance1 = hand1
            opponentDrawChance.handChance2 = hand2
            opponentDrawChance.layer?.setNeedsDisplay()
        }
        else {
            var draw1 = 0.0, draw2 = 0.0
            if deckCount > 0 {
                draw1 = (1 * 100.0) / Double(deckCount)
                draw2 = (2 * 100.0) / Double(deckCount)
            }
            
            playerDrawChance.drawChance1 = draw1
            playerDrawChance.drawChance2 = draw2
            playerDrawChance.layer?.setNeedsDisplay()
        }
    }
    
    private func removeCard(card:CardCellView, _ fadeOut: Bool) {
        if fadeOut {
            card.fadeOut(card.card!.count > 0)
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(600 * Double(NSEC_PER_MSEC)))
            let queue = dispatch_get_main_queue()
            dispatch_after(when, queue) {
                self.animatedCards.remove(card)
            }
        }
        else {
            animatedCards.remove(card)
        }
    }
    
    private func areEqualForList(c1: Card, _ c2: Card) -> Bool {
        return c1.id == c2.id && c1.jousted == c2.jousted && c1.isCreated == c2.isCreated
            && (!Settings.instance.highlightDiscarded || c1.wasDiscarded == c2.wasDiscarded)
    }
    
    // MARK: - CardCellHover
    func hover(card: Card) {
        // DDLogInfo("hovering \(card)")
    }
    
    func out(card: Card) {
        // DDLogInfo(@"out \(card)")
    }
}
