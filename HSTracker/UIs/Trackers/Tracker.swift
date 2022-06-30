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
    @IBOutlet weak private var cardsView: AnimatedCardList!
    @IBOutlet weak private var cardCounter: CardCounter!
    @IBOutlet weak private var playerDrawChance: PlayerDrawChance!
    @IBOutlet weak private var opponentDrawChance: OpponentDrawChance!
    @IBOutlet weak private var wotogCounter: WotogCounterFrame!
    @IBOutlet weak private var playerClass: NSView!
    @IBOutlet weak private var recordTracker: StringTracker!
    @IBOutlet weak private var fatigueTracker: StringTracker!
    @IBOutlet weak private var galakrondCounter: StringTracker!
    @IBOutlet weak private var graveyardCounter: GraveyardCounter!
    @IBOutlet weak private var jadeCounter: JadeCounter!
    @IBOutlet weak private var playerBottom: DeckLens!
    @IBOutlet weak private var playerTop: DeckLens!

    private var hero: CardBar?
    private var heroCard: Card?

    var hasValidFrame = false
    
    var playerType: PlayerType?
    var showCthunCounter: Bool = false
    var showSpellCounter: Bool = false
    var showDeathrattleCounter: Bool = false
    var showJadeCounter: Bool = false
    var showLibramCounter: Bool = false
    var showGraveyard: Bool = false
    var proxy: Entity?
    var nextJadeSize: Int = 1
    var fatigueCounter: Int = 0
    var hasGalakrondProxy: Bool = false
    var galakrondInvokeCounter: Int = 0
    var graveyard: [Entity]?
    var spellsPlayedCount = 0
    var deathrattlesPlayedCount = 0
    var libramReductionCount = 0
    
    var playerClassId: String?
    var playerName: String?
    var currentGameMode: GameMode = .none
    var currentFormat: Format = .unknown
    var matchInfo: MatchInfo?
    var recordTrackerMessage: String = ""
    var observer: NSObjectProtocol?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Settings.tracker_opacity), object: nil, queue: OperationQueue.main) { _ in
            self.setOpacity()
        }
        if let playerType = playerType {
            graveyardCounter.playerType = playerType
            cardsView.playerType = playerType
            playerBottom.setPlayerType(playerType: playerType)
            playerTop.setPlayerType(playerType: playerType)
        }
        cardsView.delegate = self
        playerBottom.setDelegate(delegate: self)
        playerTop.setDelegate(delegate: self)
        playerTop.setLabel(label: NSLocalizedString("On Top", comment: ""))
        playerBottom.setLabel(label: NSLocalizedString("On Bottom", comment: ""))
        setOpacity()
    }
    
    deinit {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func isLoaded() -> Bool {
        return self.isWindowLoaded
    }

    // MARK: - Notifications

    func setOpacity() {
        let alpha = CGFloat(Settings.trackerOpacity / 100.0)
        self.window!.backgroundColor = NSColor(red: 0,
                                               green: 0,
                                               blue: 0,
                                               alpha: alpha)
    }

    // MARK: - Game
    func update(cards: [Card], top: [Card], bottom: [Card], reset: Bool = false) {
        cardsView.update(cards: cards, reset: reset)
        playerBottom.update(cards: bottom, reset: reset)
        playerTop.update(cards: top, reset: reset)
    }
    
    override func updateFrames() {
        super.updateFrames()
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
            galakrondCounter.isHidden = !(Settings.showOpponentGalakrondCounter && (galakrondInvokeCounter > 0))
        } else {
            cardCounter.isHidden = !Settings.showPlayerCardCount
            opponentDrawChance.isHidden = true
            playerDrawChance.isHidden = !Settings.showPlayerDrawChance
            
            playerClass.isHidden = !Settings.showDeckNameInTracker
            recordTracker.isHidden = !Settings.showWinLossRatio
            galakrondCounter.isHidden = !(Settings.showPlayerGalakrondCounter && hasGalakrondProxy)
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
        
        if !galakrondCounter.isHidden {
            galakrondCounter.message = "\(NSLocalizedString("Invoked : ", comment: ""))"
                + "\(galakrondInvokeCounter)"
            galakrondCounter.needsDisplay = true
        }
        let showLibram = showLibramCounter  && libramReductionCount > 0
        var counterStyle: [WotogCounterStyle] = []
        if showCthunCounter && showSpellCounter && showDeathrattleCounter && showLibram {
            counterStyle.append(.full)
        } else if !showCthunCounter && !showSpellCounter && !showDeathrattleCounter  && !showLibram {
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
            
            if showLibram {
                counterStyle.append(.libram)
            }
        }
        
        recordTracker.message = recordTrackerMessage
        
        wotogCounter.counterStyle = counterStyle
        wotogCounter.isHidden = wotogCounter.counterStyle.contains(.none)
        wotogCounter.attack = proxy?.attack ?? 6
        wotogCounter.health = proxy?.health ?? 6
        wotogCounter.spell = spellsPlayedCount
        wotogCounter.deathrattle = deathrattlesPlayedCount
        wotogCounter.libram = libramReductionCount
        
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
                hero?.card?.count = 1
                hero?.card?.cost = -1
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
        if !galakrondCounter.isHidden {
            offsetFrames += smallFrameHeight
        }
        if showLibram {
            offsetFrames += smallFrameHeight
        }
        
        var totalCards = cardsView.count

        if playerBottom.count > 0 && Settings.showPlayerCardsBottom {
            offsetFrames += smallFrameHeight
            totalCards += playerBottom.count
        }
        if playerTop.count > 0 && Settings.showPlayerCardsTop {
            offsetFrames += smallFrameHeight
            totalCards += playerTop.count
        }

        var cardHeight: CGFloat
        switch Settings.cardSize {
        case .tiny: cardHeight = CGFloat(kTinyRowHeight)
        case .small: cardHeight = CGFloat(kSmallRowHeight)
        case .medium: cardHeight = CGFloat(kMediumRowHeight)
        case .huge: cardHeight = CGFloat(kHighRowHeight)
        case .big: cardHeight = CGFloat(kRowHeight)
        }
        if totalCards > 0 {
            cardHeight = round(min(cardHeight,
                                   (windowHeight - offsetFrames) / CGFloat(totalCards)))
        }
        
        let cardViewHeight = CGFloat(cardsView.count) * cardHeight
        var y: CGFloat = windowHeight - startHeight

        if playerTop.count > 0 && Settings.showPlayerCardsTop {
            let playerTopHeight = CGFloat(playerTop.count) * cardHeight + smallFrameHeight + 5
            y -= playerTopHeight
            playerTop.frame = NSRect(x: 0, y: y, width: windowWidth, height: playerTopHeight)
            playerTop.updateFrames(frameHeight: smallFrameHeight)
        } else {
            playerTop.frame = NSRect.zero
        }

        y -= cardViewHeight
        cardsView.frame = NSRect(x: 0,
                                 y: y,
                                 width: windowWidth,
                                 height: cardViewHeight)
        cardsView.updateFrames()
                
        if playerBottom.count > 0 && Settings.showPlayerCardsBottom {
            let playerBottomHeight = CGFloat(playerBottom.count) * cardHeight + smallFrameHeight + 5
            y -= playerBottomHeight
            playerBottom.frame = NSRect(x: 0, y: y, width: windowWidth, height: playerBottomHeight)
            playerBottom.updateFrames(frameHeight: smallFrameHeight)
        } else {
            playerBottom.frame = NSRect.zero
        }
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
        if showCthunCounter || showSpellCounter || showDeathrattleCounter || showLibram {
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
            if showLibram {
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
        if !galakrondCounter.isHidden {
            y -= smallFrameHeight
            galakrondCounter.frame = NSRect(x: 0,
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
}

// MARK: - CardCellHover
extension Tracker: CardCellHover {
    func hover(cell: CardBar, card: Card) {

        let windowRect = self.window!.frame

        let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 388)

        var x: CGFloat
        // decide if the popup window should on the left or right side of the tracker
        if windowRect.origin.x < hoverFrame.size.width {
            x = windowRect.origin.x + windowRect.size.width
        } else {
            x = windowRect.origin.x - hoverFrame.size.width
        }

        let cellFrameRelativeToWindow = cell.convert(cell.bounds, to: nil)
        let cellFrameRelativeToScreen = cell.window?.convertToScreen(cellFrameRelativeToWindow)

        let y: CGFloat = cellFrameRelativeToScreen!.origin.y - hoverFrame.height / 2.0

        let frame = [x, y, hoverFrame.width, hoverFrame.height]

        let userinfo = [
            "card": card,
            "frame": frame,
            "useFrame": true
        ] as [String: Any]

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
