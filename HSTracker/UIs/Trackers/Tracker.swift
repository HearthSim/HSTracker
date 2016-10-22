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

class Tracker: OverWindowController {

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
    var playerType: PlayerType?
    private var cellsCache = [String: NSView]()

    override func windowDidLoad() {
        super.windowDidLoad()

        let center = NotificationCenter.default
        var observers: [String] = []
        var selector: Selector? = nil
        if playerType == .player {
            selector = #selector(playerOptionFrameChange)
            observers = ["player_draw_chance", "player_card_count", "player_cthun_frame",
                         "player_yogg_frame", "player_deathrattle_frame", "show_win_loss_ratio",
                         "reload_decks", "player_in_hand_color", "show_deck_name",
                         "player_graveyard_details_frame", "player_graveyard_frame"]
        } else if playerType == .opponent {
            selector = #selector(opponentOptionFrameChange)
            observers = ["opponent_card_count", "opponent_draw_chance", "opponent_cthun_frame",
                         "opponent_yogg_frame", "opponent_deathrattle_frame",
                         "show_opponent_class", "opponent_graveyard_frame",
                         "opponent_graveyard_details_frame"]
        }

        guard let currentSelector = selector else {
            Log.error?.message("\(playerType) is unknown")
            return
        }

        for name in observers {
            center.addObserver(self,
                               selector: currentSelector,
                               name: NSNotification.Name(rawValue: name),
                               object: nil)
        }

        let options = ["show_opponent_draw", "show_opponent_mulligan", "show_opponent_play",
            "show_player_draw", "show_player_mulligan", "show_player_play", "rarity_colors",
            "remove_cards_from_deck", "highlight_last_drawn", "highlight_cards_in_hand",
            "highlight_discarded", "show_player_get"]
        for option in options {
            center.addObserver(self,
                               selector: #selector(trackerOptionsChange),
                               name: NSNotification.Name(rawValue: option),
                               object: nil)
        }

        let frames = ["player_draw_chance", "player_card_count",
                      "opponent_card_count", "opponent_draw_chance"]
        for name in frames {
            center.addObserver(self,
                               selector: #selector(frameOptionsChange),
                               name: NSNotification.Name(rawValue: name),
                               object: nil)
        }
        center.addObserver(self,
                           selector: #selector(cardSizeChange),
                           name: NSNotification.Name(rawValue: "card_size"),
                           object: nil)

        setOpacity()
        frameOptionsChange()
    }

    func player() -> Player {
        return playerType == .player ? Game.instance.player : Game.instance.opponent
    }

    // MARK: - Notifications
    func trackerOptionsChange() {
        frameOptionsChange()
    }

    func cardSizeChange() {
        frameOptionsChange()
        setWindowSizes()
        WindowManager.default.updateTrackers()
    }

    func playerOptionFrameChange() {
        if playerType == .player {
            WindowManager.default.updateTrackers(reset: true)
        }
    }

    func opponentOptionFrameChange() {
        if playerType == .opponent {
            WindowManager.default.updateTrackers(reset: true)
        }
    }

    func setOpacity() {
        let alpha = CGFloat(Settings.instance.trackerOpacity / 100.0)
        self.window!.backgroundColor = NSColor(red: 0,
                                               green: 0,
                                               blue: 0,
                                               alpha: alpha)
    }

    func frameOptionsChange() {
        WindowManager.default.updateTrackers()
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
                existing!.update(highlight: highlight)
            } else if existing!.card!.isCreated != card.isCreated {
                existing!.update(highlight: false)
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

                let index = animatedCards.index(of: card)!
                animatedCards.insert(newAnimated, at: index)
                newAnimated.update(highlight: true)
                newCards.remove(newCard!)
            }
        }
        for (cardCellView, fadeOut) in toRemove {
            remove(card: cardCellView, fadeOut: fadeOut)
        }
        newCards.forEach({
            let newCard = CardBar.factory()
            newCard.playerType = self.playerType
            newCard.setDelegate(self)
            newCard.card = $0
            let index = cards.index(of: $0)!
            animatedCards.insert(newCard, at: index)
            newCard.fadeIn(highlight: !reset)
        })

        updateCountFrames()
        updateCardFrames()
    }

    fileprivate func updateCardFrames() {
        guard let windowFrame = self.window?.contentView?.frame else { return }
        let settings = Settings.instance

        let windowWidth = windowFrame.width
        let windowHeight = windowFrame.height

        let ratio: CGFloat
        switch settings.cardSize {
        case .tiny: ratio = CGFloat(kRowHeight / kTinyRowHeight)
        case .small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
        case .medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
        case .huge: ratio = CGFloat(kRowHeight / kHighRowHeight)
        case .big: ratio = 1.0
        }

        let showCthunCounter: Bool
        let showSpellCounter: Bool
        let showDeathrattleCounter: Bool
        let showGraveyard: Bool
        let proxy: Entity?

        if playerType == .opponent {
            cardCounter.isHidden = !settings.showOpponentCardCount
            opponentDrawChance.isHidden = !settings.showOpponentDrawChance
            playerDrawChance.isHidden = true

            showCthunCounter = WotogCounterHelper.showOpponentCthunCounter
            showSpellCounter = WotogCounterHelper.showOpponentSpellsCounter
            showDeathrattleCounter = WotogCounterHelper.showOpponentDeathrattleCounter
            showGraveyard = WotogCounterHelper.showOpponentGraveyard
            proxy = WotogCounterHelper.opponentCthunProxy
            playerClass.isHidden = !settings.showOpponentClassInTracker
            recordTracker.isHidden = true
        } else {
            cardCounter.isHidden = !settings.showPlayerCardCount
            opponentDrawChance.isHidden = true
            playerDrawChance.isHidden = !settings.showPlayerDrawChance

            showCthunCounter = WotogCounterHelper.showPlayerCthunCounter
            showSpellCounter = WotogCounterHelper.showPlayerSpellsCounter
            showDeathrattleCounter = WotogCounterHelper.showPlayerDeathrattleCounter
            showGraveyard = WotogCounterHelper.showPlayerGraveyard
            proxy = WotogCounterHelper.playerCthunProxy
            playerClass.isHidden = !settings.showDeckNameInTracker
            recordTracker.isHidden = !settings.showWinLossRatio
        }
        fatigueTracker.isHidden = !(settings.fatigueIndicator && player().fatigue > 0)
        graveyardCounter.isHidden = !showGraveyard

        if let activeDeck = Game.instance.activeDeck, !recordTracker.isHidden {
            recordTracker.message = StatsHelper.getDeckManagerRecordLabel(deck: activeDeck)
            recordTracker.needsDisplay = true
        } else {
            recordTracker.isHidden = true
        }
        if !fatigueTracker.isHidden {
            fatigueTracker.message = "\(NSLocalizedString("Fatigue : ", comment: ""))"
                + "\(player().fatigue)"
            fatigueTracker.needsDisplay = true
        }

        var counterStyle: [WotogCounterStyle] = []
        if showCthunCounter && showSpellCounter && showDeathrattleCounter {
            counterStyle.append(.full)
        } else if !showCthunCounter && !showSpellCounter && !showDeathrattleCounter {
            counterStyle.append(.none)
        } else {
            if showDeathrattleCounter {
                counterStyle.append(.deathrattles)
            }
            if showSpellCounter {
                counterStyle.append(.spells)
            }
            if showCthunCounter {
                counterStyle.append(.cthun)
            }
        }

        wotogCounter.counterStyle = counterStyle
        wotogCounter.isHidden = wotogCounter.counterStyle.contains(.none)
        wotogCounter.attack = proxy?.attack ?? 6
        wotogCounter.health = proxy?.health ?? 6
        wotogCounter.spell = player().spellsPlayedCount
        wotogCounter.deathrattle = player().deathrattlesPlayedCount

        let graveyard = player().graveyard
        // map entitiy to card [count]
        var minionmap: [Card: Int] = [:]
        var minions: Int = 0
        var murlocks: Int = 0
        for e: Entity in graveyard {
            if e.isMinion {
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

        var graveyardminions: [Card] = []
        for (card, count) in minionmap {
            card.count = count
            graveyardminions.append(card)
        }
        graveyardCounter.graveyard = graveyardminions.sortCardList()
        graveyardCounter.minions = minions
        graveyardCounter.murlocks = murlocks

        let bigFrameHeight = round(71 / ratio)
        let smallFrameHeight = round(40 / ratio)

        var offsetFrames: CGFloat = 0
        var startHeight: CGFloat = 0
        if !playerClass.isHidden && playerType == .opponent {
            if let playerClassId = Game.instance.opponent.playerClassId,
                let playerName = Game.instance.opponent.name {
                
                offsetFrames += smallFrameHeight
                
                playerClass.frame = NSRect(x: 0,
                                           y: windowHeight - smallFrameHeight,
                                           width: windowHeight,
                                           height: smallFrameHeight)
                startHeight += smallFrameHeight
                
                playerClass.subviews.forEach({$0.removeFromSuperview()})
                let hero = CardBar.factory()
                hero.playerType = .hero
                hero.playerClassID = playerClassId
                hero.playerName = playerName
                
                playerClass.addSubview(hero)
                hero.frame = NSRect(x: 0, y: 0,
                                    width: windowWidth,
                                    height: smallFrameHeight)
                hero.update(highlight: false)
            }
        } else if !playerClass.isHidden && playerType == .player {
            if let activeDeck = Game.instance.activeDeck {

                offsetFrames += smallFrameHeight
                
                playerClass.frame = NSRect(x: 0,
                                           y: windowHeight - smallFrameHeight,
                                           width: windowHeight,
                                           height: smallFrameHeight)
                startHeight += smallFrameHeight
                
                playerClass.subviews.forEach({$0.removeFromSuperview()})
                let hero = CardBar.factory()
                hero.playerType = .hero
                hero.playerClassID = Cards.hero(byPlayerClass: activeDeck.playerClass)?.id
                hero.playerName = activeDeck.name
                
                playerClass.addSubview(hero)
                hero.frame = NSRect(x: 0, y: 0,
                                    width: windowWidth,
                                    height: smallFrameHeight)
                hero.update(highlight: false)
            }
        }
        if !opponentDrawChance.isHidden {
            offsetFrames += bigFrameHeight
        }
        if !playerDrawChance.isHidden {
            offsetFrames += smallFrameHeight
        }
        if !cardCounter.isHidden {
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
        if !recordTracker.isHidden {
            offsetFrames += smallFrameHeight
        }
        if !fatigueTracker.isHidden {
            offsetFrames += smallFrameHeight
        }

        var cardHeight: CGFloat
        switch settings.cardSize {
        case .tiny: cardHeight = CGFloat(kTinyRowHeight)
        case .small: cardHeight = CGFloat(kSmallRowHeight)
        case .medium: cardHeight = CGFloat(kMediumRowHeight)
        case .huge: cardHeight = CGFloat(kHighRowHeight)
        case .big: cardHeight = CGFloat(kRowHeight)
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
        if !cardCounter.isHidden {
            y -= smallFrameHeight
            cardCounter.frame = NSRect(x: 0, y: y, width: windowWidth, height: smallFrameHeight)
        }
        if !opponentDrawChance.isHidden {
            y -= bigFrameHeight
            opponentDrawChance.frame = NSRect(x: 0,
                                              y: y,
                                              width: windowWidth,
                                              height: bigFrameHeight)
        }
        if !playerDrawChance.isHidden {
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
        if !graveyardCounter.isHidden {
            y -= smallFrameHeight
            graveyardCounter?.frame = NSRect(x: 0,
                                             y: y,
                                             width: windowWidth,
                                             height: smallFrameHeight)
            if playerType == .opponent {
                graveyardCounter?.displayDetails = settings.showOpponentGraveyardDetails
            } else {
                graveyardCounter?.displayDetails = settings.showPlayerGraveyardDetails
            }
            graveyardCounter?.cardHeight = cardHeight
            graveyardCounter?.needsDisplay = true
        }
        if !recordTracker.isHidden {
            y -= smallFrameHeight
            recordTracker.frame = NSRect(x: 0,
                                         y: y,
                                         width: windowWidth,
                                         height: smallFrameHeight)
        }
        if !fatigueTracker.isHidden {
            y -= smallFrameHeight
            fatigueTracker.frame = NSRect(x: 0,
                                         y: y,
                                         width: windowWidth,
                                         height: smallFrameHeight)
        }
    }

    private func updateCountFrames() {
        let gameStarted = !Game.instance.isInMenu && Game.instance.entities.count >= 67
        let deckCount = !gameStarted ? 30 : player().deckCount
        let handCount = !gameStarted ? 0 : player().handCount

        cardCounter?.deckCount = deckCount
        cardCounter?.handCount = handCount
        cardCounter?.needsDisplay = true

        if playerType == .opponent {
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
                    let handMinusCoin = handCount - (player().hasCoin == true ? 1 : 0)
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

    private func remove(card: CardBar, fadeOut: Bool) {
        if fadeOut {
            card.fadeOut(highlight: card.card!.count > 0)
            let when = DispatchTime.now()
                + Double(Int64(600 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
            let queue = DispatchQueue.main
            queue.asyncAfter(deadline: when) {
                self.animatedCards.remove(card)
            }
        } else {
            animatedCards.remove(card)
        }
    }

    fileprivate func areEqualForList(_ c1: Card, _ c2: Card) -> Bool {
        return c1.id == c2.id && c1.jousted == c2.jousted && c1.isCreated == c2.isCreated
            && (!Settings.instance.highlightDiscarded || c1.wasDiscarded == c2.wasDiscarded)
    }
}

// MARK: - NSWindowDelegate
extension Tracker: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        updateCardFrames()
        onWindowMove()
    }

    func windowDidMove(_ notification: Notification) {
        onWindowMove()
    }

    private func onWindowMove() {
        let settings = Settings.instance
        if playerType == .player {
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
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: "show_floating_card"),
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": frame
                ])
    }

    func out(card: Card) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "hide_floating_card"),
                                        object: nil)
    }
}
