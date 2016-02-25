/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */

import Foundation

class Player {
    var revealedCards = [CardEntity]()
    var hand = [CardEntity]()
    var board = [CardEntity]()
    var deck = [CardEntity]()
    var graveyard = [CardEntity]()
    var secrets = [CardEntity]()
    var removed = [CardEntity]()
    var drawnCardIds = [String]()
    var drawnCardIdsTotal = [String]()
    var createdInHandCardIds = [String]()
    var hightlightedCards = [String]()
    var isLocalPlayer: Bool
    var id: Int?
    var playerClass: Card?
    var name: String?
    var tracker: Tracker?
    var goingFirst: Bool = false
    var fatigue: Int = 0
    //@property(nonatomic) BOOL drawnCardsMatchDeck;

    let DeckSize = 30

    init(_ local: Bool) {
        self.isLocalPlayer = local
    }

    var hasCoin: Bool {
        return !self.hand.filter({ (cardEntity) -> Bool in
            if let entity = cardEntity.entity {
                if entity.cardId == "GAME_005" {
                    return true
                }
            }
            return cardEntity.cardId == "GAME_005"
        }).isEmpty
    }

    var handCount: Int {
        return self.hand.count
    }

    var deckCount: Int {
        return self.deck.count
    }

    func drawnCards() -> [Card] {
        let tmp = drawnCardIds.filter { !$0.isEmpty }
        var cards = [String: Card]()
        tmp.forEach { (cardId) -> () in
            if let card = cards[cardId] {
                card.count += 1
            } else if let card = Card.byId(cardId) {
                card.count = 1
                cards[cardId] = card
            }
        }
        
        return Array(cards.values)
    }

    func displayReveleadCards() -> [Card] {
        var cards = [String: Card]()
        revealedCards.forEach { (cardEntity) -> () in
            if let cardId = cardEntity.cardId where !cardId.isEmpty {
                if let card = cards[cardId] {
                    card.count += 1
                }
                else if let card = Card.byId(cardId) {
                    card.count = 1
                    card.jousted = (cardEntity.inHand || cardEntity.inDeck)
                    card.isCreated = cardEntity.created
                    card.wasDiscarded = cardEntity.discarded && Settings.instance.highlightDiscarded
                    cards[cardId] = card
                }
            }
        }
        
        return Array(cards.values).sortCardList()
    }

    func displayCards() -> [Card] {
        var drawnCards = self.drawnCards()
        
        var cards = [String: Card]()
        createdInHandCardIds.forEach { (cardId) -> () in
            if let card = cards[cardId] {
                card.count += 1
            } else if let card = Card.byId(cardId) {
                card.count = 1
                card.isCreated = true
                cards[cardId] = card
            }
        }
        
        let createdInHand = Array(cards.values)
        guard let _ = Game.instance.activeDeck else {
            drawnCards.appendContentsOf(createdInHand)
            return drawnCards.sortCardList()
        }
        
        cards.removeAll()
        deck.forEach { (cardEntity) -> () in
            if let cardId = cardEntity.cardId where !cardId.isEmpty {
                if let card = cards[cardId] {
                    card.count += 1
                }
                else if let card = Card.byId(cardId) {
                    card.count = 1
                    card.isCreated = cardEntity.cardMark == .Created
                    card.highlightDraw = hightlightedCards.contains(cardId)
                    var highlightInHand = false
                    hand.forEach({ (ce) -> () in
                        if let cardId = ce.cardId where cardId == cardEntity.cardId {
                            highlightInHand = true
                        }
                    })
                    card.highlightInHand = highlightInHand
                    cards[cardId] = card
                }
            }
        }
        var stillInDeck:[Card] = Array(cards.values)
        
        let settings = Settings.instance
        if settings.removeCardsFromDeck {
            if settings.highlightLastDrawn {
                var drawHighlight = [Card]()
                var drawHighlightCardIds:[DeckCard]?
                if let activeDeck = Game.instance.activeDeck {
                    drawHighlightCardIds = activeDeck.deckCards.filter({ (deckCard) -> Bool in
                        let cardId = deckCard.cardId
                        return self.hightlightedCards.contains(cardId) && stillInDeck.filter({ $0.cardId != cardId }).isEmpty
                    })
                }
                if let drawHighlightCardIds = drawHighlightCardIds {
                    drawHighlightCardIds.forEach({ (deckCard) -> () in
                        if let card = Card.byId(deckCard.cardId) {
                            card.count = 0
                            card.highlightDraw = true
                            drawHighlight.append(card)
                        }
                    })
                }
                stillInDeck.appendContentsOf(drawHighlight)
            }
            
            if settings.highlightCardsInHand {
                if let activeDeck = Game.instance.activeDeck {
                    let inHandCardIds = activeDeck.deckCards.filter({ (deckCard) -> Bool in
                        let cardId = deckCard.cardId
                        return !self.hand.filter({ $0.cardId != cardId }).isEmpty && stillInDeck.filter({ $0.cardId != cardId }).isEmpty
                    })
                    var inHand = [Card]()
                    inHandCardIds.forEach({ (deckCard) -> () in
                        if let card = Card.byId(deckCard.cardId) {
                            card.count = 0
                            card.highlightDraw = true
                            if self.isLocalPlayer && card.cardId == CardIds.Collectible.Neutral.RenoJackson {
                                var countIds = [String: Int]()
                                deck.forEach({ (cardEntity) -> () in
                                    if let cardId = cardEntity.cardId where !cardId.isEmpty {
                                        if let count = countIds[cardId] {
                                            countIds[cardId] = count + 1
                                        }
                                        else {
                                            countIds[cardId] = 1
                                        }
                                    }
                                })
                                card.highlightDraw = Array(countIds.values).maxElement() <= 1
                            }
                            inHand.append(card)
                        }
                    })
                    stillInDeck.appendContentsOf(inHand)
                }
            }
            
            stillInDeck.appendContentsOf(createdInHand)
            return stillInDeck.sortCardList()
        }
        
        if let activeDeck = Game.instance.activeDeck {
            let notInDeckCardIds = activeDeck.deckCards.filter({ (deckCard) -> Bool in
                return self.deck.filter({ $0.cardId != deckCard.cardId }).isEmpty
            })
            var notInDeck = [Card]()
            notInDeckCardIds.forEach({ (deckCard) -> () in
                if let card = Card.byId(deckCard.cardId) {
                    card.count = 0
                    card.highlightDraw = true
                    if self.isLocalPlayer && card.cardId == CardIds.Collectible.Neutral.RenoJackson {
                        var countIds = [String: Int]()
                        deck.forEach({ (cardEntity) -> () in
                            if let cardId = cardEntity.cardId where !cardId.isEmpty {
                                if let count = countIds[cardId] {
                                    countIds[cardId] = count + 1
                                }
                                else {
                                    countIds[cardId] = 1
                                }
                            }
                        })
                        card.highlightDraw = Array(countIds.values).maxElement() <= 1
                    }
                    notInDeck.append(card)
                }
            })
            stillInDeck.appendContentsOf(notInDeck)
        }
        
        stillInDeck.appendContentsOf(createdInHand)
        
        return stillInDeck.sortCardList()
    }
    

    func reset() {
        self.id = nil
        self.name = ""
        self.playerClass = nil
        self.goingFirst = false
        self.fatigue = 0
        //self.drawnCardsMatchDeck = true;
        self.hand = []
        self.board = []
        self.deck = []
        self.graveyard = []
        self.secrets = []
        self.drawnCardIds = []
        self.drawnCardIdsTotal = []
        self.revealedCards = []
        self.createdInHandCardIds = []
        self.hightlightedCards = []
        self.removed = []

        for _ in 0 ..< DeckSize {
            self.deck.append(CardEntity())
        }
    }

    func gameStart() {
    }

    func gameEnd() {
    }

    var debugName: String {
        return self.isLocalPlayer ? "Player" : "Opponent"
    }

    func createInDeck(entity: Entity, turn: Int) {
        var cardEntity: CardEntity

        if self.isLocalPlayer {
            cardEntity = CardEntity(cardId: nil, entity: entity)
            cardEntity.turn = turn
            self.deck.append(cardEntity)

            let ce = CardEntity(cardId: nil, entity: entity)
            ce.turn = turn
            self.revealedCards.append(ce)
        } else {
            self.deck.append(CardEntity())
            self.revealDeckCard(entity.cardId!, turn: turn)
            cardEntity = CardEntity(cardId: entity.cardId, entity: nil)
            cardEntity.turn = turn
            self.revealedCards.append(cardEntity)
        }
        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func revealDeckCard(cardId: String, turn: Int) {
        var cardEntity: CardEntity?
        for ce in self.deck {
            if ce.unkown {
                cardEntity = ce
                break
            }
        }
        if let cardEntity = cardEntity {
            cardEntity.cardId = cardId
            cardEntity.turn = turn
        }
    }

    func createInHand(entity: Entity?, turn: Int) {
        let cardEntity = CardEntity(cardId: nil, entity: entity)
        cardEntity.turn = turn
        cardEntity.cardMark = CardMark.Created
        cardEntity.created = true
        if let entity = entity where entity.cardId == "GAME_005" || entity.cardId == "GVG_028t" {
            cardEntity.cardMark = CardMark.Coin

            if let cardId = entity.cardId where self.isLocalPlayer {
                self.createdInHandCardIds.append(cardId)
            }
        }

        self.hand.append(cardEntity)

        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func boardToDeck(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.board, to: self.deck, turn: turn) {
            updateRevealedEntity(cardEntity, turn: turn)

            if let cardId = entity.cardId where !cardId.isEmpty && self.drawnCardIds.contains(cardId) {
                if let index = self.drawnCardIds.indexOf(cardId) {
                    self.drawnCardIds.removeAtIndex(index)
                }
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func play(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.hand, to: entity.isSecret ? self.secrets : self.board, turn: turn) {
            if entity.getTag(GameTag.CARDTYPE) == CardType.TOKEN.rawValue {
                cardEntity.cardMark = .Created
                cardEntity.created = true
            }
            updateRevealedEntity(cardEntity, turn: turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func handDiscard(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.hand, to: self.graveyard, turn: turn) {
            updateRevealedEntity(cardEntity, turn: turn, discarded: true)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretPlayedFromDeck(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.deck, to: self.secrets, turn: turn) {
            updateRevealedEntity(cardEntity, turn: turn)
            if let cardId = entity.cardId where !cardId.isEmpty {
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretPlayedFromHand(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.hand, to: self.secrets, turn: turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func mulligan(entity: Entity) {
        if let cardEntity = moveCardEntity(entity, from: self.hand, to: self.deck, turn: 0) {

            //new cards are drawn first
            var newCard: CardEntity?
            for ent in self.hand {
                if ent.entity!.getTag(GameTag.ZONE_POSITION) == entity.getTag(GameTag.ZONE_POSITION) {
                    newCard = ent
                    break
                }
            }

            if let newCard = newCard {
                newCard.cardMark = CardMark.Mulliganed
            }
            if let cardId = entity.cardId where !cardId.isEmpty && self.drawnCardIds.contains(cardId) {
                self.drawnCardIds.remove(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func draw(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.deck, to: self.hand, turn: turn) {

            if let cardId = entity.cardId where self.isLocalPlayer {
                highlight(cardId)
            } else {
                cardEntity.reset()
            }

            if let cardId = entity.cardId where !cardId.isEmpty && cardEntity.cardMark != CardMark.Created
                    && cardEntity.cardMark != CardMark.Returned && !cardEntity.created {
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func highlight(cardId: String) {
        hightlightedCards.append(cardId)
        Game.instance.playerTracker?.update()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            NSThread.sleepForTimeInterval(3)
            self.hightlightedCards.removeFirst()
            dispatch_async(dispatch_get_main_queue()) {
                Game.instance.playerTracker?.update()
            }
        }
    }

    func removeFromDeck(entity: Entity, turn: Int) {
        var revealed: CardEntity?
        for ent in self.revealedCards {
            if ent.entity == entity {
                revealed = ent
                break
            }
        }

        if let revealed = revealed {
            self.revealedCards.remove(revealed)
        }
        if let cardEntity = moveCardEntity(entity, from: self.deck, to: self.removed, turn: turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func deckDiscard(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.deck, to: self.graveyard, turn: turn) {
            updateRevealedEntity(cardEntity, turn: turn, discarded: true)

            if let cardId = entity.cardId where !cardId.isEmpty && cardEntity.cardMark != CardMark.Created && cardEntity.cardMark != CardMark.Returned {
                /*if(self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
                    DrawnCardsMatchDeck = false;
                }*/
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func deckToPlay(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.deck, to: self.board, turn: turn) {
            updateRevealedEntity(cardEntity, turn: turn)

            if let cardId = entity.cardId where !cardId.isEmpty && cardEntity.cardMark != CardMark.Created && cardEntity.cardMark != CardMark.Returned {
                /*if(self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
                  DrawnCardsMatchDeck = false;
                }*/
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func playToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.board, to: self.graveyard, turn: turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func joustReveal(entity: Entity, turn: Int) {
        var ce: CardEntity?
        for ent in self.deck {
            if ent.inDeck && ent.cardId != entity.cardId {
                ce = ent
                break
            }
        }

        if let _ = ce {
            if let cardId = entity.cardId {
                revealDeckCard(cardId, turn: turn)
                let cardEntity = CardEntity(cardId: entity.cardId, entity: nil)
                cardEntity.turn = turn
                self.revealedCards.append(cardEntity)
                DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
            }
        }
    }

    func createInPlay(entity: Entity, turn: Int) {
        let cardEntity = CardEntity(cardId: nil, entity: entity)
        cardEntity.turn = turn
        self.board.append(cardEntity)
        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func stolenByOpponent(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.board, to: self.removed, turn: turn) {
            updateRevealedEntity(cardEntity, turn: turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func stolenFromOpponent(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.removed, to: self.board, turn: turn) {
            cardEntity.created = true
            updateRevealedEntity(cardEntity, turn: turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func boardToHand(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.board, to: self.hand, turn: turn) {
            cardEntity.cardMark = CardMark.Returned
            updateRevealedEntity(cardEntity, turn: turn, cardMark: CardMark.Returned)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretTriggered(entity: Entity, turn: Int) {
        if let cardEntity = moveCardEntity(entity, from: self.secrets,
                to: self.graveyard,
                turn: turn) {
            updateRevealedEntity(cardEntity, turn: turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func updateRevealedEntity(entity: CardEntity, turn: Int, discarded: Bool? = nil, cardMark: CardMark? = nil) {
        var cardEntity: CardEntity?
        for ent in self.revealedCards {
            if ent.entity == entity.entity ||
                    (ent.cardId == entity.cardId && ent.entity == nil && ent.turn <= entity.prevTurn) {
                cardEntity = ent
                break
            }
        }

        if let cardEntity = cardEntity {
            cardEntity.update(entity.entity)
        } else {
            cardEntity = CardEntity(cardId: nil, entity: entity.entity)
            cardEntity!.turn = turn
            cardEntity!.created = entity.created
            cardEntity!.discarded = entity.discarded
            let cardType = CardType(rawValue: entity.entity!.getTag(.CARDTYPE))
            if cardType != .HERO && cardType != .ENCHANTMENT && cardType != .HERO_POWER && cardType != .PLAYER {
                self.revealedCards.append(entity)
            }
        }

        if let discarded = discarded {
            cardEntity!.discarded = discarded
        }

        if let cardMark = cardMark {
            cardEntity!.cardMark = cardMark
        }
    }

    func moveCardEntity(entity: Entity, var from: [CardEntity], var to: [CardEntity], turn: Int) -> CardEntity? {
        var cardEntity = getEntityFromCollection(from, entity: entity)
        if let _cardEntity = cardEntity {
            from.remove(_cardEntity)
        } else {
            for ce in from {
                if let cardId = ce.cardId where !cardId.isEmpty && ce.entity == nil {
                    cardEntity = ce
                    break
                }
            }

            if let _cardEntity = cardEntity {
                from.remove(_cardEntity)
                _cardEntity.update(entity)
            } else {
                cardEntity = CardEntity(cardId: nil, entity: entity)
                cardEntity!.turn = turn
            }
        }

        if let _cardEntity = cardEntity {
            _cardEntity.turn = turn
            to.append(_cardEntity)
            to.sortInPlace(CardEntity.zonePosComparison)
        }
        return cardEntity
    }

    func getEntityFromCollection(array: [CardEntity], entity: Entity) -> CardEntity? {
        var cardEntity: CardEntity?

        for ce in array {
            if ce.entity == entity {
                cardEntity = ce
                break
            }
        }

        if cardEntity == nil {
            for ce in array {
                if let cardId = ce.cardId where !cardId.isEmpty && ce.cardId == entity.cardId {
                    cardEntity = ce
                    break
                }
            }
        }

        if cardEntity == nil {
            for ce in array {
                if (ce.cardId == nil || ce.cardId!.isEmpty) && ce.entity == nil {
                    cardEntity = ce
                    break
                }
            }
        }

        if cardEntity != nil {
            cardEntity!.update(entity)
        }
        return cardEntity
    }

}
