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
import RealmSwift

class Tracker: OverWindowController {

    // UI elements
    @IBOutlet weak private var cardsView: NSView!
    @IBOutlet weak private var cardCounter: CardCounter!
    @IBOutlet weak private var playerDrawChance: PlayerDrawChance!
    @IBOutlet weak private var opponentDrawChance: OpponentDrawChance!
    @IBOutlet weak private var wotogCounter: WotogCounter!
    @IBOutlet weak private var playerClass: NSView!
    @IBOutlet weak private var recordTracker: StringTracker!
    @IBOutlet weak private var fatigueTracker: StringTracker!
    @IBOutlet weak private var graveyardCounter: GraveyardCounter!
    @IBOutlet weak private var jadeCounter: JadeCounter!

    private var hero: CardBar?
    private var heroCard: Card?
    fileprivate var animatedCards: [CardBar] = []
    
    private var cellsCache = [String: NSView]()

    var hasValidFrame = false
    
    var playerType: PlayerType?
    var showCthunCounter: Bool = false
    var showSpellCounter: Bool = false
    var showDeathrattleCounter: Bool = false
    var showJadeCounter: Bool = false
    var showGraveyard: Bool = false
    var proxy: Entity?
    var nextJadeSize: Int = 1
    var fatigueCounter: Int = 0
    var graveyard: [Entity]?
    var spellsPlayedCount = 0
    var deathrattlesPlayedCount = 0
    
    var playerClassId: String?
    var playerName: String?
    var currentGameMode: GameMode = .none
    var currentFormat: Format = .unknown
    var matchInfo: MatchInfo?
    var recordTrackerMessage: String = ""
    
    override func windowDidLoad() {
        super.windowDidLoad()

        let center = NotificationCenter.default

        center.addObserver(self,
                           selector: #selector(setOpacity),
                           name: NSNotification.Name(rawValue: Settings.tracker_opacity),
                           object: nil)
        setOpacity()
    }

    func isLoaded() -> Bool {
        return self.isWindowLoaded
    }

    // MARK: - Notifications

    @objc func setOpacity() {
        let alpha = CGFloat(Settings.trackerOpacity / 100.0)
        self.window!.backgroundColor = NSColor(red: 0,
                                               green: 0,
                                               blue: 0,
                                               alpha: alpha)
    }

    // MARK: - Game
    func update(cards: [Card], reset: Bool = false) {
        if reset {
            cellsCache.removeAll()
            animatedCards.removeAll()
        }

        var newCards = [Card]()
        cards.forEach({ (card: Card) in
            let existing = animatedCards.first { self.areEqualForList($0.card!, card) }
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
            let newCard = newCards.first { $0.id == card.card!.id }
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
    }
    
    override func updateFrames() {
        guard let windowFrame = self.window?.contentView?.frame else { return }
        
        let windowWidth = windowFrame.width
        let windowHeight = windowFrame.height
        
        let ratio: CGFloat
        switch Settings.cardSize {
        case .tiny: ratio = CGFloat(kRowHeight / kTinyRowHeight)
        case .small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
        case .medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
        case .huge: ratio = CGFloat(kRowHeight / kHighRowHeight)
        case .big: ratio = 1.0
        }
        
        if playerType == .opponent {
            cardCounter.isHidden = !Settings.showOpponentCardCount
            opponentDrawChance.isHidden = !Settings.showOpponentDrawChance
            playerDrawChance.isHidden = true
            playerClass.isHidden = !Settings.showOpponentClassInTracker
            recordTracker.isHidden = true
        } else {
            cardCounter.isHidden = !Settings.showPlayerCardCount
            opponentDrawChance.isHidden = true
            playerDrawChance.isHidden = !Settings.showPlayerDrawChance
            
            playerClass.isHidden = !Settings.showDeckNameInTracker
            recordTracker.isHidden = !Settings.showWinLossRatio
        }
        
        fatigueTracker.isHidden = !(Settings.fatigueIndicator && (fatigueCounter > 0))
        graveyardCounter.isHidden = !showGraveyard
        jadeCounter.isHidden = !showJadeCounter
        
        if !recordTracker.isHidden {
            recordTracker.needsDisplay = true
        }
        
        if !fatigueTracker.isHidden {
            fatigueTracker.message = "\(NSLocalizedString("Fatigue : ", comment: ""))"
                + "\(fatigueCounter)"
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
        
        recordTracker.message = recordTrackerMessage
        
        wotogCounter.counterStyle = counterStyle
        wotogCounter.isHidden = wotogCounter.counterStyle.contains(.none)
        wotogCounter.attack = proxy?.attack ?? 6
        wotogCounter.health = proxy?.health ?? 6
        wotogCounter.spell = spellsPlayedCount
        wotogCounter.deathrattle = deathrattlesPlayedCount
        
        if !jadeCounter.isHidden {
            jadeCounter.nextJade = nextJadeSize
            jadeCounter.needsDisplay = true
        }
        
        // map entitiy to card [count]
        var minionmap: [Card: Int] = [:]
        var minions: Int = 0
        var murlocks: Int = 0
        if let graveyard = self.graveyard {
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
            if let playerClassId = self.playerClassId {
                offsetFrames += smallFrameHeight
                
                playerClass.frame = NSRect(x: 0,
                                           y: windowHeight - smallFrameHeight,
                                           width: windowHeight,
                                           height: smallFrameHeight)
                startHeight += smallFrameHeight
                
                if hero == nil {
                    hero = CardBar.factory()
                    if let hero = hero {
                        playerClass.addSubview(hero)
                    }
                }
                
                hero?.playerType = .hero
                hero?.card = Cards.hero(byId: playerClassId)
                if let matchInfo = matchInfo, currentGameMode == .ranked {
                    let wild = currentFormat == .wild
                    var rank = wild
                        ? matchInfo.opposingPlayer.wildRank
                        : matchInfo.opposingPlayer.standardRank
                    if rank < 0 {
                        rank = wild
                            ? matchInfo.opposingPlayer.wildLegendRank
                            : matchInfo.opposingPlayer.standardLegendRank
                    }
                    
                    if rank > 0 {
                        hero?.playerRank = rank
                    }
                }
                hero?.card?.count = 1
                hero?.playerName = playerName
                hero?.frame = NSRect(x: 0, y: 0,
                                     width: windowWidth,
                                     height: smallFrameHeight)
                hero?.update(highlight: false)
                hero?.needsDisplay = true
            }
        } else if !playerClass.isHidden && playerType == .player {
            
            offsetFrames += smallFrameHeight
            
            playerClass.frame = NSRect(x: 0,
                                       y: windowHeight - smallFrameHeight,
                                       width: windowHeight,
                                       height: smallFrameHeight)
            startHeight += smallFrameHeight
            if hero == nil {
                
                hero = CardBar.factory()
                if let hero = hero {
                    playerClass.addSubview(hero)
                }
            }
            hero?.playerType = .hero
            hero?.card = Cards.hero(byId: self.playerClassId ?? "")
            
            if let matchInfo = matchInfo, currentGameMode == .ranked {
                let wild = currentFormat == .wild
                var rank = wild
                    ? matchInfo.localPlayer.wildRank
                    : matchInfo.localPlayer.standardRank
                if rank < 0 {
                    rank = wild
                        ? matchInfo.localPlayer.wildLegendRank
                        : matchInfo.localPlayer.standardLegendRank
                }
                
                if rank > 0 {
                    hero?.playerRank = rank
                }
            }
            hero?.card?.count = 1
            hero?.playerName = playerName
            
            hero?.frame = NSRect(x: 0, y: 0,
                                 width: windowWidth,
                                 height: smallFrameHeight)
            hero?.update(highlight: false)
            hero?.needsDisplay = true
            
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
        if showJadeCounter {
            offsetFrames += smallFrameHeight
        }
        if !recordTracker.isHidden {
            offsetFrames += smallFrameHeight
        }
        if !fatigueTracker.isHidden {
            offsetFrames += smallFrameHeight
        }
        
        var cardHeight: CGFloat
        switch Settings.cardSize {
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
                graveyardCounter?.displayDetails = Settings.showOpponentGraveyardDetails
            } else {
                graveyardCounter?.displayDetails = Settings.showPlayerGraveyardDetails
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
        if !jadeCounter.isHidden {
            y -= smallFrameHeight
            jadeCounter.frame = NSRect(x: 0,
                                       y: y,
                                       width: windowWidth,
                                       height: smallFrameHeight)
        }
        
    }

    func updateCardCounter(deckCount: Int, handCount: Int, hasCoin: Bool, gameStarted: Bool) {
        
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
                    let handMinusCoin = handCount - (hasCoin == true ? 1 : 0)
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
            && (!Settings.highlightDiscarded || c1.wasDiscarded == c2.wasDiscarded)
    }
}

// MARK: - CardCellHover
extension Tracker: CardCellHover {
    func hover(cell: CardBar, card: Card) {

        let windowRect = self.window!.frame

        let hoverFrame = NSRect(x: 0, y: 0, width: 180, height: 250)

        var x: CGFloat
        // decide if the popup window should on the left or right side of the tracker
        if windowRect.origin.x < hoverFrame.size.width {
            x = windowRect.origin.x + windowRect.size.width
        } else {
            x = windowRect.origin.x - hoverFrame.size.width
        }

        let cellFrameRelativeToWindow = cell.convert(cell.bounds, to: nil)
        let cellFrameRelativeToScreen = cell.window?.convertToScreen(cellFrameRelativeToWindow)

        let y: CGFloat = cellFrameRelativeToScreen!.origin.y

        let frame = [x, y, hoverFrame.width, hoverFrame.height]

        var userinfo = [
            "card": card,
            "frame": frame
        ] as [String: Any]

        if self.playerType == .player && Settings.showTopdeckchance {
			
            let playercardlist: [Card] = self.animatedCards.map { $0.card! }
            let remainingcardsindeck = playercardlist.reduce(0) { $0 + $1.count}
            if let cardindeck = playercardlist.first(where: { $0.id == card.id }) {
                let cardindeckcount = cardindeck.count
                // probability that the top card is the one
                let Pfirst = Float(cardindeckcount) / Float(remainingcardsindeck)
                userinfo["drawchancetop"] = Pfirst * 100.0

                // probability that the card is in the first 2 cards
                var drawchancetop2: Float = 0.0
                if remainingcardsindeck > 1 {
                    let Psecond = Float(cardindeckcount) / Float(remainingcardsindeck-1)
                    drawchancetop2 = Pfirst + ((1-Pfirst) * Psecond )
                }
                userinfo["drawchancetop2"] = drawchancetop2 * 100.0
                userinfo["frame"] = frame
            }
        }

        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.show_floating_card),
                                  object: nil,
                                  userInfo: userinfo)
    }

    func out(card: Card) {
        let userinfo = [
            "card": card
            ] as [String: Any]
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hide_floating_card),
                                        object: nil,
                                        userInfo: userinfo)
    }
}
