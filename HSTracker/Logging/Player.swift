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
        for ce in self.hand {
            if ce.cardId == "GAME_005"
                    || (ce.entity != nil && ce.entity!.cardId == "GAME_005") {
                return true;
            }
        }
        return false
    }

    var handCount: Int {
        return self.hand.count
    }

    var deckCount: Int {
        return self.deck.count
    }

    func drawnCards() -> [Card] {
        /*NSArray *tmp = [self._drawnCardIds filteredArrayUsingPredicate:
          [NSPredicate predicateWithFormat:@"name.length > 0"]];
        NSMutableArray *cards = [NSMutableArray array];
        [tmp enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Card *card = [Card byId:obj];
            if (card && ![card.name isEqualToString:@"UNKNOWN"]) {
              PlayCard *playCard = [[cards filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"self.card.cardId = %@", obj]] firstObject];
              if (playCard) {
                playCard.count += 1;
              }
              else {
                playCard = [[PlayCard alloc] init];
                playCard.count = 1;
                playCard.card = card;
                [cards addObject:playCard];
              }
            }
        }];
        return cards;*/
    }

    func displayReveleadCards() -> [Card] {
        /*NSMutableDictionary *temp = [NSMutableDictionary dictionary];
        Settings *settings = [Settings instance];

        for (CardEntity *cardEntity in self._revealedCards) {
          if (cardEntity.cardId != nil && ![cardEntity.cardId isEmpty]) {
            if (temp[cardEntity.cardId]) {
              ((PlayCard *) temp[cardEntity.cardId]).count += 1;
            }
            else {
              Card *card = [Card byId:cardEntity.cardId];
              if (card && ![card.name isEqualToString:@"UNKNOWN"]) {
                PlayCard *playCard = [[PlayCard alloc] init];
                playCard.card = card;
                playCard.count = 1;
                playCard.jousted = (cardEntity.inHand || cardEntity.inDeck);
                playCard.isCreated = cardEntity.created;
                playCard.wasDiscarded = cardEntity.discarded && settings.highlightDiscarded;
                temp[cardEntity.cardId] = playCard;
              }
            }
          }
        }
        return [[temp allValues] sortCardList];*/
    }

    func displayCards() -> [Card] {
        /*NSMutableDictionary *temp = [NSMutableDictionary dictionary];
        for (NSString *str in self._createdInHandCardIds) {
          if (temp[str]) {
            ((PlayCard *) temp[str]).count += 1;
          }
          else {
            Card *card = [Card byId:str];
            if (card) {
              PlayCard *playCard = [[PlayCard alloc] init];
              playCard.card = card;
              playCard.count = 1;
              playCard.isCreated = YES;
              temp[str] = playCard;
            }
          }
        }
        NSArray *createdInHand = [temp allValues];
        [temp removeAllObjects];

        BOOL tmpBool = NO;
        if (tmpBool) {
          return [[[self drawnCards] arrayByAddingObjectsFromArray:createdInHand] sortCardList];
        }

        for (CardEntity *ce in self._deck) {
          if (ce.cardId != nil && ![ce.cardId isEmpty]) {
            if (temp[ce.cardId]) {
              ((PlayCard *) temp[ce.cardId]).count += 1;
            }
            else {
              Card *card = [Card byId:ce.cardId];
              if (card) {
                PlayCard *playCard = [[PlayCard alloc] init];
                playCard.card = card;
                playCard.count = 1;
                playCard.isCreated = ce.cardMark == ECardMark_Created;
                //playCard.highlightDraw = [self._hightlightedCards containsObject:ce.cardId];
                BOOL highlightInHand = NO;
                for (CardEntity *cardEntity in self._hand) {
                  if ([cardEntity.cardId isEqualToString:ce.cardId]) {
                    highlightInHand = YES;
                    break;
                  }
                }
                playCard.highlightInHand = highlightInHand;
                temp[ce.cardId] = playCard;
              }
            }
          }
        }
        NSArray *stillInDeck = [temp allValues];

        Settings *settings = [Settings instance];
        if (settings.removeCardsFromDeck) {
          if (settings.highlightLastDrawn) {
            var drawHighlight =
            DeckList.Instance.ActiveDeck.Cards.Where(c => _hightlightedCards.Contains(c.Id) && stillInDeck.All(c2 => c2.Id != c.Id))
            .Select(c =>
              {
                var card = (Card)c.Clone();
              card.Count = 0;
              card.HighlightDraw = true;
              return card;
              });
            stillInDeck = stillInDeck.Concat(drawHighlight).ToList();
          }
          if (settings.highlightCardsInHand) {
            var inHand =
            DeckList.Instance.ActiveDeck.Cards.Where(c => stillInDeck.All(c2 => c2.Id != c.Id) && Hand.Any(ce => c.Id == ce.CardId))
            .Select(c =>
              {
                var card = (Card)c.Clone();
              card.Count = 0;
              card.HighlightInHand = true;
              if(IsLocalPlayer && card.Id == HearthDb.CardIds.Collectible.Neutral.RenoJackson
              && Deck.Where(x => !string.IsNullOrEmpty(x.CardId)).Select(x => x.CardId).GroupBy(x => x).All(x => x.Count() <= 1))
              card.HighlightFrame = true;
              return card;
              });
            ;
            stillInDeck = stillInDeck.Concat(inHand).ToList();
          }
          //return stillInDeck.Concat(createdInHand).ToSortedCardList();
        }

        var notInDeck = DeckList.Instance.ActiveDeckVersion.Cards.Where(c => Deck.All(ce => ce.CardId != c.Id)).Select(c =>
          {
            var card = (Card)c.Clone();
          card.Count = 0;
          card.HighlightDraw = _hightlightedCards.Contains(c.Id);
          if(Hand.Any(ce => ce.CardId == c.Id))
          {
            card.HighlightInHand = true;
            if(IsLocalPlayer && card.Id == HearthDb.CardIds.Collectible.Neutral.RenoJackson
              && Deck.Where(x => !string.IsNullOrEmpty(x.CardId)).Select(x => x.CardId).GroupBy(x => x).All(x => x.Count() <= 1))
            card.HighlightFrame = true;
          }
          return card;
          });

        //return stillInDeck.Concat(notInDeck).Concat(createdInHand).ToSortedCardList();
        return [[stillInDeck arrayByAddingObjectsFromArray:createdInHand] sortCardList];*/
    }

    func reset() {
        self.id = nil
        self.name = ""
        self.playerClass = nil
        self.goingFirst = false
        self.fatigue = 0
        //self.drawnCardsMatchDeck = true;
        self.hand.removeAll()
        self.board.removeAll()
        self.deck.removeAll()
        self.graveyard.removeAll()
        self.secrets.removeAll()
        self.drawnCardIds.removeAll()
        self.drawnCardIdsTotal.removeAll()
        self.revealedCards.removeAll()
        self.createdInHandCardIds.removeAll()
        self.removed.removeAll()

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
            if entity[GameTag.CARDTYPE] == CardType.TOKEN.rawValue {
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
                if ent.entity![GameTag.ZONE_POSITION] == entity[GameTag.ZONE_POSITION] {
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
            let cardType = CardType(rawValue: entity.entity![GameTag.CARDTYPE]!)
            if cardType != CardType.HERO && cardType != CardType.ENCHANTMENT && cardType != CardType.HERO_POWER && cardType != CardType.PLAYER {
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
            to.sortInPlace {
                let v1 = ($0.entity != nil && $0.entity![GameTag.ZONE_POSITION] != nil) ? $0.entity![GameTag.ZONE_POSITION]! : 10
                let v2 = ($1.entity != nil && $1.entity![GameTag.ZONE_POSITION] != nil) ? $1.entity![GameTag.ZONE_POSITION]! : 10
                return v1 < v2
            }
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
