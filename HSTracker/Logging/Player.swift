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

class DynamicEntity : Hashable {
    var cardId:String
    var hidden, created, discarded:Bool
    var cardMark:CardMark
    
    init(cardId:String, hidden:Bool = false, created:Bool = false,
        cardMark:CardMark = CardMark.None, discarded:Bool = false) {
        self.cardId = cardId
        self.hidden = hidden
        self.created = created
        self.discarded = discarded
            self.cardMark = cardMark
    }
    
    var hashValue: Int {
        return cardId.hashValue ^
            hidden.hashValue ^
            created.hashValue ^
            discarded.hashValue ^
        cardMark.hashValue
    }
}
func ==(lhs: DynamicEntity, rhs: DynamicEntity) -> Bool {
    return lhs.cardId == rhs.cardId &&
        lhs.hidden == rhs.hidden &&
        lhs.created == lhs.created &&
        lhs.discarded == rhs.discarded &&
    lhs.cardMark == rhs.cardMark
}

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
        reset()
    }

    var hasCoin: Bool {
        return hand.any { $0.cardId == "GAME_005" || $0.entity?.cardId == "GAME_005" }
    }

    var handCount: Int {
        return self.hand.count
    }

    var deckCount: Int {
        return self.deck.count
    }

    func drawnCards() -> [Card] {
        return drawnCardIds.filter { !$0.isEmpty }
            .groupBy { (s:String) in s.trim() }
            .map { g -> (Card?) in
                if let card = Cards.byId(g.key) {
                    card.count = g.items.count
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
    }

    func displayReveleadCards() -> [Card] {
        return revealedCards.filter { $0.cardId != nil && !$0.cardId!.isEmpty }
            .map { (ce:CardEntity) -> (DynamicEntity) in
                DynamicEntity(cardId: ce.cardId!,
                    hidden: ce.inHand || ce.inDeck,
                    created: ce.created,
                    discarded: ce.discarded && Settings.instance.highlightDiscarded)
            }
            .groupBy { (d:DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.jousted = g.key.hidden
                    card.isCreated = g.key.created
                    card.wasDiscarded = g.key.discarded
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
            .sortCardList()
    }
    
    func displayCards() -> [Card] {
        let settings = Settings.instance
        var drawnCards = self.drawnCards()
        
        var createdInHand = [Card]()
        if settings.showPlayerGet {
            createdInHand = createdInHandCardIds.filter { !$0.isEmpty }
                .groupBy { (s:String) in s }
                .map { g -> Card? in
                    if let card = Cards.byId(g.key) {
                        card.count = g.items.count
                        card.isCreated = true
                        card.highlightInHand = self.hand.any { $0.cardId == card.cardId }
                        return card
                    } else {
                        return nil
                    }
                }
                .filter { $0 != nil }
                .map { $0! }
        }
        
        guard let _ = Game.instance.activeDeck else {
            drawnCards += createdInHand
            return drawnCards.sortCardList()
        }
        
        var stillInDeck = deck.filter { $0.cardId != nil && !$0.cardId!.isEmpty }
            .map { (ce:CardEntity) -> (DynamicEntity) in
                DynamicEntity(cardId: ce.cardId!,
                    hidden: ce.inHand || ce.inDeck,
                    cardMark: ce.cardMark,
                    discarded: ce.discarded)
            }
            .groupBy { (d:DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.isCreated = g.key.cardMark == CardMark.Created
                    card.highlightDraw = self.hightlightedCards.contains(g.key.cardId)
                    card.highlightInHand = self.hand.any { $0.cardId == g.key.cardId }
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
        
        if settings.removeCardsFromDeck {
            if settings.highlightLastDrawn {
                let drawHighlight = Game.instance.activeDeck!.sortedCards.filter { (card:Card) in
                    self.hightlightedCards.contains(card.cardId) && stillInDeck.all { (c:Card) in c.cardId != card.cardId  }
                }
                    .map { card -> Card in
                        let c:Card = card.copy() as! Card
                        c.count = 0
                        c.highlightDraw = true
                        return c
                }
                stillInDeck += drawHighlight
            }
            
            if settings.highlightCardsInHand {
                let inHand = Game.instance.activeDeck!.sortedCards.filter { (card:Card) in
                    stillInDeck.all { (c:Card) in c.cardId != card.cardId } && self.hand.any { (ce:CardEntity) in card.cardId == ce.cardId }
                    }
                    .map { card -> Card in
                        let c:Card = card.copy() as! Card
                        c.count = 0
                        c.highlightInHand = true
                        let count = self.deck.filter { (ce:CardEntity) -> Bool in
                            return (ce.cardId != nil && !ce.cardId!.isEmpty)
                            }
                            .groupBy { (ce:CardEntity) -> String in ce.cardId! }
                            .map { g -> Int in g.items.count }
                            .maxElement()
                        if let count = count where self.isLocalPlayer && c.cardId == CardIds.Collectible.Neutral.RenoJackson && count <= 1 {
                            c.highlightFrame = true
                        }
                        
                        return c
                }
                stillInDeck += inHand
            }
            return stillInDeck.sortCardList()
        }
        
        let notInDeck = Game.instance.activeDeck!.sortedCards.filter { (card:Card) in
            self.deck.all { (c:CardEntity) in c.cardId != card.cardId }
            }
            .map { card -> Card in
                let c:Card = card.copy() as! Card
                c.count = 0
                c.highlightDraw = self.hightlightedCards.contains(c.cardId)
                if self.hand.any({ $0.cardId == c.cardId }) {
                    card.highlightInHand = true
                    let count = self.deck.filter { (ce:CardEntity) -> Bool in
                        return (ce.cardId != nil && !ce.cardId!.isEmpty)
                        }
                        .groupBy { (ce:CardEntity) -> String in ce.cardId! }
                        .map { g -> Int in g.items.count }
                        .maxElement()
                    if let count = count where self.isLocalPlayer && c.cardId == CardIds.Collectible.Neutral.RenoJackson && count <= 1 {
                        c.highlightFrame = true
                    }
                }
                return c
        }
        
        stillInDeck += notInDeck + createdInHand
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

    func createInDeck(entity: Entity, _ turn: Int) {
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
            self.revealDeckCard(entity.cardId!, turn)
            cardEntity = CardEntity(cardId: entity.cardId, entity: nil)
            cardEntity.turn = turn
            self.revealedCards.append(cardEntity)
        }
        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func revealDeckCard(cardId: String, _ turn: Int) {
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

    func createInHand(entity: Entity?, _ turn: Int) {
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

    func boardToDeck(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.board, self.deck, turn) {
            updateRevealedEntity(cardEntity, turn)

            if let cardId = entity.cardId where !cardId.isEmpty && self.drawnCardIds.contains(cardId) {
                if let index = self.drawnCardIds.indexOf(cardId) {
                    self.drawnCardIds.removeAtIndex(index)
                }
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func play(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.hand, entity.isSecret ? self.secrets : self.board, turn) {
            if entity.getTag(GameTag.CARDTYPE) == CardType.TOKEN.rawValue {
                cardEntity.cardMark = .Created
                cardEntity.created = true
            }
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func handDiscard(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.hand, self.graveyard, turn) {
            updateRevealedEntity(cardEntity, turn, true)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretPlayedFromDeck(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.deck, self.secrets, turn) {
            updateRevealedEntity(cardEntity, turn)
            if let cardId = entity.cardId where !cardId.isEmpty {
                self.drawnCardIds.append(cardId)
                self.drawnCardIdsTotal.append(cardId)
            }
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretPlayedFromHand(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.hand, self.secrets, turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func mulligan(entity: Entity) {
        if let cardEntity = moveCardEntity(entity, self.hand, self.deck, 0) {

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

    func draw(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.deck, self.hand, turn) {

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

    func removeFromDeck(entity: Entity, _ turn: Int) {
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
        if let cardEntity = moveCardEntity(entity, self.deck, self.removed, turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func deckDiscard(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.deck, self.graveyard, turn) {
            updateRevealedEntity(cardEntity, turn, true)

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

    func deckToPlay(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.deck, self.board, turn) {
            updateRevealedEntity(cardEntity, turn)

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

    func playToGraveyard(entity: Entity, _ cardId: String?, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.board, self.graveyard, turn) {
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func joustReveal(entity: Entity, _ turn: Int) {
        var ce: CardEntity?
        for ent in self.deck {
            if ent.inDeck && ent.cardId != entity.cardId {
                ce = ent
                break
            }
        }

        if let _ = ce {
            if let cardId = entity.cardId {
                revealDeckCard(cardId, turn)
                let cardEntity = CardEntity(cardId: entity.cardId, entity: nil)
                cardEntity.turn = turn
                self.revealedCards.append(cardEntity)
                DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
            }
        }
    }

    func createInPlay(entity: Entity, _ turn: Int) {
        let cardEntity = CardEntity(cardId: nil, entity: entity)
        cardEntity.turn = turn
        self.board.append(cardEntity)
        DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
    }

    func stolenByOpponent(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.board, self.removed, turn) {
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func stolenFromOpponent(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.removed, self.board, turn) {
            cardEntity.created = true
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func boardToHand(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.board, self.hand, turn) {
            cardEntity.cardMark = CardMark.Returned
            updateRevealedEntity(cardEntity, turn, nil, CardMark.Returned)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func secretTriggered(entity: Entity, _ turn: Int) {
        if let cardEntity = moveCardEntity(entity, self.secrets,
                self.graveyard,
                turn) {
            updateRevealedEntity(cardEntity, turn)
            DDLogInfo("\(debugName) \(__FUNCTION__) \(cardEntity)")
        }
    }

    func updateRevealedEntity(entity: CardEntity, _ turn: Int, _ discarded: Bool? = nil, _ cardMark: CardMark? = nil) {
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

    func moveCardEntity(entity: Entity, var _ from: [CardEntity], var _ to: [CardEntity], _
        turn: Int) -> CardEntity? {
        var cardEntity = getEntityFromCollection(from, entity)
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

    func getEntityFromCollection(array: [CardEntity], _ entity: Entity) -> CardEntity? {
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
    
    func updateZonePos(entity:Entity, _ zone:Zone, _ turn:Int) {
        switch zone {
        case .HAND:
            updateCardEntity(entity)
            hand.sortInPlace(CardEntity.zonePosComparison)
            if !isLocalPlayer && turn == 0 && hand.count == 5 && hand[4].entity?.id > 67 {
                hand[4].cardMark = .Coin
                hand[4].created = true
                deck.append(CardEntity())
                DDLogVerbose("Coin \(hand[4])")
            }
            
        case .PLAY:
            updateCardEntity(entity)
            board.sortInPlace(CardEntity.zonePosComparison)
            
        default: break
        }
    }
    
    func updateCardEntity(entity:Entity)
    {
        if let cardEntity = getEntityFromCollection(hand, entity) {
            cardEntity.entity = entity
        }
    }
}
