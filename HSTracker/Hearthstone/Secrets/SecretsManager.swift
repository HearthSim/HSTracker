//
//  SecretsManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/10/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class SecretsManager {
    let avengeDelay: Double = 50.0 / 1000.0
    let multipleSecretResolveDelay = 750.0 / 1000.0
    private var _avengeDeathRattleCount = 0
    private var _awaitingAvenge = false
    private var _lastStartOfTurnCheck = 0
    private var _lastStartOfTurnDamageCheck = 0
    private var _lastStartOfTurnMinionCheck = 0

    private var entititesInHandOnMinionsPlayed: Set<Entity>  = Set<Entity>()

    private var game: Game
    private(set) var secrets = SynchronizedArray<Secret>()
    private var _triggeredSecrets = SynchronizedArray<Entity>()
    private var opponentTookDamageDuringTurns = SynchronizedArray<Int>()
    private var entityDamageDealtHistory = SynchronizedDictionary<Int, SynchronizedDictionary<Int, Int>>()
    
    private var _lastPlayedMinionId: Int = 0
    private var savedSecrets = SynchronizedArray<MultiIdCard>()

    var onChanged: (([Card]) -> Void)?

    init(game: Game) {
        self.game = game
    }

    private var freeSpaceOnBoard: Bool { return game.opponentBoardCount < 7 }
    private var freeSpaceInHand: Bool { return game.opponentHandCount < 10 }
    private var handleAction: Bool { return hasActiveSecrets }
    private var isAnyMinionInOpponentsHand: Bool { return entititesInHandOnMinionsPlayed.first(where: { entity in entity.isMinion }) != nil }

    private var hasActiveSecrets: Bool {
        return secrets.count > 0
    }
    
    private func saveSecret(secret: MultiIdCard) {
        if !secrets.any({ (s) -> Bool in
            s.isExcluded(cardId: secret)
        }) {
            savedSecrets.append(secret)
        }
    }

    func exclude(cardId: MultiIdCard, invokeCallback: Bool = true) {
        secrets.forEach {
            $0.exclude(cardId: cardId)
        }

        if invokeCallback {
            onChanged?(getSecretList())
        }
    }

    func exclude(cardIds: [MultiIdCard]) {
        cardIds.enumerated().forEach {
            exclude(cardId: $1, invokeCallback: $0 == cardIds.count - 1)
        }
    }

    func reset() {
        _avengeDeathRattleCount = 0
        _awaitingAvenge = false
        _lastStartOfTurnCheck = 0
        _lastStartOfTurnDamageCheck = 0
        _lastStartOfTurnMinionCheck = 0
        opponentTookDamageDuringTurns.removeAll()
        entititesInHandOnMinionsPlayed.removeAll()
        secrets.removeAll()
    }

    @discardableResult
    func newSecret(entity: Entity) -> Bool {
        if !entity.isSecret || !entity.has(tag: .class) {
            return false
        }

        if entity.hasCardId {
            exclude(cardId: MultiIdCard(entity.cardId))
        }
        do {
            let secret = try Secret(entity: entity)
            secrets.append(secret)
            logger.info("new secret : \(entity)")
            onNewSecret(secret: secret)
            onChanged?(getSecretList())
            return true
        } catch {
            logger.error("\(error)")
            return false
        }
    }

    @discardableResult
    func removeSecret(entity: Entity) -> Bool {
        guard let secret = secrets.first(where: { $0.entity.id == entity.id }) else {
            logger.info("Secret not found \(entity)")
            return false
        }

        handleFastCombat(entity: entity)
        secrets.remove(secret)
        if secret.entity.hasCardId {
            let mcid = MultiIdCard(secret.entity.cardId)
            exclude(cardId: mcid, invokeCallback: false)
            savedSecrets.remove(mcid)
        }
        onChanged?(getSecretList())
        return true
    }

    func toggle(cardId: String) {
        let mcid = MultiIdCard(cardId)
        let excluded = secrets.any { $0.isExcluded(cardId: mcid) }
        if excluded {
            secrets.forEach { $0.include(cardId: mcid) }
        } else {
            exclude(cardId: mcid, invokeCallback: false)
        }
    }

    func getSecretList() -> [Card] {
        let gameMode = game.currentGameType
        let format = game.currentFormat

        let opponentEntities = game.opponent.revealedEntities.filter {
            $0.id < 68 && $0.isSecret && $0.hasCardId
        }
        let gameModeHasCardLimit = [GameType.gt_casual, GameType.gt_ranked, GameType.gt_vs_friend, GameType.gt_vs_ai].contains(gameMode)

        let createdSecrets = secrets
            .filter { $0.entity.info.created }
            .flatMap { $0.excluded }
            .filter { !$0.value }
            .map { $0.key }
            .unique()
        let hasPlayedTwoOf: ((_ cardId: String) -> Bool) = { cardId in
            opponentEntities.filter { $0.cardId == cardId && !$0.info.created }.count >= 2
        }
        let adjustCount: ((_ cardId: String, _ count: Int) -> Int) = { cardId, count in
            gameModeHasCardLimit && hasPlayedTwoOf(cardId) && !createdSecrets.contains(MultiIdCard(cardId)) ? 0 : count
        }
        
        var cards = secrets.array().flatMap { $0.excluded }
            .group { $0.key }
            .compactMap { group in
                QuantifiedMultiIdCard(baseCard: group.key, count: adjustCount(group.key.ids[0], group.value.filter { x in !x.value }.count))
        }
        
        if let remoteData = RemoteConfig.data {
            if gameMode == .gt_arena {
                let currentSets = remoteData.arena?.current_sets?.compactMap({ value in
                    CardSet.allCases.first(where: { x in "\(x)".uppercased() == value })
                })
                
                cards = cards.filter { card in
                    (currentSets?.any { x in card.hasSet(set: x) } ?? false)
                }
                
                if remoteData.arena?.banned_secrets?.count ?? 0 > 0 {
                    cards = cards.filter({ card in
                        !(remoteData.arena?.banned_secrets?.all { s in card != s } ?? false)
                    })
                }
            } else {
                if remoteData.arena?.exclusive_secrets?.count ?? 0 > 0 {
                    cards = cards.filter({ card in
                        remoteData.arena?.exclusive_secrets?.all { s in card != s } ?? true
                    })
                }
                switch format {
                case .standard:
                    cards = cards.filter { card in card.isStandard }
                case .classic:
                    cards = cards.filter { card in card.isClassic }
                case .twist:
                    cards = cards.filter { card in card.isTwist }
                default:
                    cards = cards.filter { card in card.isWild }
                }
            }
        }

        return cards.compactMap { x in
            if x.count == 0 {
                return nil
            }
            if let card = x.getCardForFormat(format: format) {
                card.count = x.count
                return card
            }
            return nil
        }.sortCardList()
    }

    func handleAttack(attacker: Entity, defender: Entity, fastOnly: Bool = false) {
        guard handleAction else { return }

        if attacker[.controller] == defender[.controller] {
            return
        }

        var exclude: [MultiIdCard] = []
        
        if freeSpaceOnBoard {
            exclude.append(CardIds.Secrets.Paladin.NobleSacrifice)
        }
        
        if !attacker.isHero {
            exclude.append(CardIds.Secrets.Paladin.JudgementofJustice)
        }

        if defender.isHero {
            if !fastOnly && attacker.health >= 1 {
                if freeSpaceOnBoard {
                    exclude.append(CardIds.Secrets.Hunter.BearTrap)
                }

                if (game.entities.values.first(where: { x in
                    x.isInPlay && (x.isHero || x.isMinion) && !x.has(tag: .immune) && x != attacker && x != defender
                    }) != nil) {
                    exclude.append(CardIds.Secrets.Hunter.Misdirection)
                }

                if attacker.isMinion {
                    if game.playerMinionCount > 1 {
                        exclude.append(CardIds.Secrets.Rogue.SuddenBetrayal)
                    }

                    exclude.append(CardIds.Secrets.Mage.FlameWard)
                    exclude.append(CardIds.Secrets.Hunter.FreezingTrap)
                    exclude.append(CardIds.Secrets.Mage.Vaporize)
                    if freeSpaceOnBoard {
                        exclude.append(CardIds.Secrets.Rogue.ShadowClone)
                    }
                }
            }

            if freeSpaceOnBoard {
                exclude.append(CardIds.Secrets.Hunter.WanderingMonster)
                if attacker.isMinion {
                    exclude.append(CardIds.Secrets.Mage.VengefulVisage)
                }
            }

            exclude.append(CardIds.Secrets.Mage.IceBarrier)
            exclude.append(CardIds.Secrets.Hunter.ExplosiveTrap)
        } else {
            exclude.append(CardIds.Secrets.Rogue.Bamboozle)
            if !defender.has(tag: .divine_shield) {
                exclude.append(CardIds.Secrets.Paladin.AutodefenseMatrix)
            }
            
            if freeSpaceOnBoard {
                exclude.append(CardIds.Secrets.Mage.SplittingImage)
                exclude.append(CardIds.Secrets.Hunter.PackTactics)
                exclude.append(CardIds.Secrets.Hunter.SnakeTrap)
                exclude.append(CardIds.Secrets.Hunter.VenomstrikeTrap)
                //I think most of the secrets here could (and maybe should) check for this, but this one definitley does because of Hysteria.
                if game.playerEntity?.isCurrentPlayer ?? false {
                    exclude.append(CardIds.Secrets.Mage.OasisAlly)
                }
            }

            if attacker.isMinion {
                exclude.append(CardIds.Secrets.Hunter.FreezingTrap)
            }
        }
        self.exclude(cardIds: exclude)
    }

    func handleFastCombat(entity: Entity) {
        guard handleAction else { return }

        if !entity.hasCardId || game.proposedAttacker == 0 || game.proposedDefender == 0 {
            return
        }
        if !CardIds.Secrets.fastCombat.contains(MultiIdCard(entity.cardId)) {
            return
        }
        if let attacker = game.entities[game.proposedAttacker],
            let defender = game.entities[game.proposedDefender] {
            handleAttack(attacker: attacker, defender: defender, fastOnly: true)
        }
    }

    func handleMinionPlayed(entity: Entity) {
        guard handleAction else { return }

        var exclude: [MultiIdCard] = []
        
        _lastPlayedMinionId = entity.id

        if !entity.has(tag: .dormant) {
            saveSecret(secret: CardIds.Secrets.Hunter.Snipe)
            exclude.append(CardIds.Secrets.Hunter.Snipe)
            saveSecret(secret: CardIds.Secrets.Mage.ExplosiveRunes)
            exclude.append(CardIds.Secrets.Mage.ExplosiveRunes)
            saveSecret(secret: CardIds.Secrets.Mage.Objection)
            exclude.append(CardIds.Secrets.Mage.Objection)
            saveSecret(secret: CardIds.Secrets.Mage.PotionOfPolymorph)
            exclude.append(CardIds.Secrets.Mage.PotionOfPolymorph)
            saveSecret(secret: CardIds.Secrets.Paladin.Repentance)
            exclude.append(CardIds.Secrets.Paladin.Repentance)
        }

        if freeSpaceOnBoard {
            saveSecret(secret: CardIds.Secrets.Mage.MirrorEntity)
            exclude.append(CardIds.Secrets.Mage.MirrorEntity)
            saveSecret(secret: CardIds.Secrets.Rogue.Ambush)
            exclude.append(CardIds.Secrets.Rogue.Ambush)
            saveSecret(secret: CardIds.Secrets.Hunter.Zombeeees)
            exclude.append(CardIds.Secrets.Hunter.Zombeeees)
        }

        if freeSpaceInHand {
            exclude.append(CardIds.Secrets.Mage.FrozenClone)
        }
        exclude.append(CardIds.Secrets.Rogue.Kidnap)

        //Hidden cache will only trigger if the opponent has a minion in hand.
        //We might not know this for certain - requires additional tracking logic.
        let cardsInOpponentsHand = game.entities.values.filter({ e in
            e.isInHand && e.isControlled(by: game.opponent.id)
        }).compactMap({ e in e })
        for cardInOpponentsHand in cardsInOpponentsHand {
            entititesInHandOnMinionsPlayed.insert(cardInOpponentsHand)
        }

        if isAnyMinionInOpponentsHand {
            exclude.append(CardIds.Secrets.Hunter.HiddenCache)
        }

        self.exclude(cardIds: exclude)
    }

    func handleOpponentMinionDeath(entity: Entity) {
        guard handleAction else { return }

        var exclude: [MultiIdCard] = []
        if freeSpaceInHand {
            exclude.append(CardIds.Secrets.Mage.Duplicate)
            exclude.append(CardIds.Secrets.Paladin.GetawayKodo)
            exclude.append(CardIds.Secrets.Rogue.CheatDeath)
        }
        
        if let opponent_minions_died = game.opponentEntity?[.num_friendly_minions_that_died_this_turn], opponent_minions_died >= 1 {
            exclude.append(CardIds.Secrets.Paladin.HandOfSalvation)
        }

        var numDeathrattleMinions = 0
        if entity.isActiveDeathrattle {
            if let count = CardIds.DeathrattleSummonCardIds[entity.cardId] {
                numDeathrattleMinions = count
            } else if entity.cardId == CardIds.Collectible.Neutral.Stalagg
                && game.opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Feugen })
                || entity.cardId == CardIds.Collectible.Neutral.Feugen
                && game.opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Stalagg }) {
                numDeathrattleMinions = 1
            }

            if game.entities.values.any({ $0.cardId == CardIds.NonCollectible.Druid.SouloftheForest_SoulOfTheForestEnchantment
                && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
            if game.entities.values.any({ $0.cardId == CardIds.NonCollectible.Shaman.AncestralSpirit_AncestralSpiritEnchantment
                && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
        }

        if let opponentEntity = game.opponentEntity,
            opponentEntity.has(tag: .extra_deathrattles) {
            numDeathrattleMinions *= opponentEntity[.extra_deathrattles] + 1
        }

        handleAvengeAsync(deathRattleCount: numDeathrattleMinions)

        // redemption never triggers if a deathrattle effect fills up the board
        // effigy can trigger ahead of the deathrattle effect, but only if effigy was played before the deathrattle minion
        if game.opponentBoardCount < 7 - numDeathrattleMinions {
            exclude.append(CardIds.Secrets.Paladin.Redemption)
        }

        // TODO: break ties when Effigy + Deathrattle played on the same turn
        exclude.append(CardIds.Secrets.Mage.Effigy)
        exclude.append(CardIds.Secrets.Hunter.EmergencyManeuvers)

        self.exclude(cardIds: exclude)
    }
    
    func handlePlayerMinionDeath(entity: Entity) {
        if entity.id == _lastPlayedMinionId && savedSecrets.count > 0 {
            savedSecrets.forEach { savedSecret in
                secrets.forEach { secret in
                    secret.include(cardId: savedSecret)
                }
            }
            
            onChanged?(getSecretList())
        }
    }

    func handleAvengeAsync(deathRattleCount: Int) {
        guard handleAction else { return }

        if _awaitingAvenge {
            return
        }
        
        DispatchQueue.global().async {
            self._awaitingAvenge = true
            self._avengeDeathRattleCount += deathRattleCount
            if self.game.opponentMinionCount != 0 {
                Thread.sleep(forTimeInterval: self.avengeDelay)
                if self.game.opponentMinionCount - self._avengeDeathRattleCount > 0 {
                    self.exclude(cardId: CardIds.Secrets.Paladin.Avenge)
                }
            }
            self._avengeDeathRattleCount = 0
            self._awaitingAvenge = false
        }
    }

    func handleOpponentDamage(entity: Entity, damage: Int) {
        guard handleAction else { return }

        if entity.isHero && entity.isControlled(by: game.opponent.id) {
            if !entity.has(tag: GameTag.immune) {
                exclude(cardId: CardIds.Secrets.Paladin.EyeForAnEye)
                exclude(cardId: CardIds.Secrets.Rogue.Evasion)
                opponentTookDamageDuringTurns.append(game.turnNumber())
            }
        }
        
        if damage >= 3 && entity.isMinion && entity.isControlled(by: game.opponent.id) && entity[.zone] != Zone.graveyard.rawValue {
            exclude(cardId: CardIds.Secrets.Paladin.Reckoning)
        }
    }
    
    func handleEntityLostArmor(entity: Entity, value: Int) {
        if value <= 0 {
            return
        }
        
        if entity.isHero && entity.isControlled(by: game.opponent.id) {
            if !entity.has(tag: .immune) {
                opponentTookDamageDuringTurns.append(game.turnNumber())
            }
        }
    }

    func handleTurnsInPlayChange(entity: Entity, turn: Int) {
        guard handleAction else { return }

        let isCurrentPlayer = game.opponentEntity?.isCurrentPlayer ?? false
        
        if isCurrentPlayer && (turn > _lastStartOfTurnCheck) {
            _lastStartOfTurnCheck = turn
            exclude(cardId: CardIds.Secrets.Rogue.Perjury)
        }
        
        if isCurrentPlayer && (turn > _lastStartOfTurnMinionCheck) {
            if entity.isMinion && entity.isControlled(by: game.opponent.id) {
                _lastStartOfTurnMinionCheck = turn
                exclude(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
                if game.opponentMinionCount >= 2 && freeSpaceOnBoard {
                    exclude(cardId: CardIds.Secrets.Hunter.OpenTheCages)
                }
            }
        }
        if isCurrentPlayer && (turn > _lastStartOfTurnDamageCheck) {
            _lastStartOfTurnDamageCheck = turn
            let turnToCheck = turn - (game.playerEntity?.has(tag: .first_player) ?? false ? 0 : 1)
            if !opponentTookDamageDuringTurns.contains(turnToCheck) {
                exclude(cardId: CardIds.Secrets.Mage.RiggedFaireGame)
            }
        }
    }
    
    func handlePlayerTurnStart() {
        savedSecrets.removeAll()
    }
    
    func handleOpponentTurnStart() {
        if game.player.cardsPlayedThisTurn.count > 0 {
            exclude(cardId: CardIds.Secrets.Rogue.Plagiarize)
        }
    }
    
    func handlePlayerTurnEnded(mana: Int) {
        if mana == 0 {
            exclude(cardId: CardIds.Secrets.Hunter.HiddenMeaning)
        }
    }
    
    func handlePlayerManaRemaining(mana: Int) {
        if mana == 0 && freeSpaceInHand {
            exclude(cardId: CardIds.Secrets.Rogue.DoubleCross)
        }
    }
    
    func secretTriggered(entity: Entity) {
        _triggeredSecrets.append(entity)
    }

    func handleCardPlayed(entity: Entity, parentCardId: String) {
        guard handleAction else { return }
        
        savedSecrets.removeAll()

        var exclude: [MultiIdCard] = []
        
        if let player = game.playerEntity, player.has(tag: .num_cards_played_this_turn) && (player[.num_cards_played_this_turn] >= 3) {
            exclude.append(CardIds.Secrets.Hunter.MotionDenied)
            if freeSpaceOnBoard {
                exclude.append(CardIds.Secrets.Hunter.RatTrap)
                exclude.append(CardIds.Secrets.Paladin.GallopingSavior)
            }
            
            if freeSpaceInHand {
                exclude.append(CardIds.Secrets.Paladin.HiddenWisdom)
            }
        }
        
        if entity.isSpell {
            if parentCardId == CardIds.Collectible.Rogue.SparkjoyCheat {
                return
            }
            _triggeredSecrets.removeAll()
            if game.opponentSecretCount > 1 {
                usleep(useconds_t(1000 * multipleSecretResolveDelay))
            }
            // Counterspell/Ice trap order may matter in rare edge cases where both are in play.
            // This is currently not handled.
            exclude.append(CardIds.Secrets.Mage.Counterspell)
            
            if _triggeredSecrets.any({ x in CardIds.Secrets.Mage.Counterspell == x.cardId }) {
                self.exclude(cardIds: [CardIds.Secrets.Mage.Counterspell])
                return
            }
            
            exclude.append(CardIds.Secrets.Hunter.IceTrap)
            if _triggeredSecrets.any({ x in CardIds.Secrets.Hunter.IceTrap == x.cardId }) {
                self.exclude(cardIds: [CardIds.Secrets.Hunter.IceTrap])
                return
            }

            exclude.append(CardIds.Secrets.Paladin.OhMyYogg)
            
            if game.opponentMinionCount > 0 {
                exclude.append(CardIds.Secrets.Paladin.NeverSurrender)
            }

            if game.opponentHandCount < 10 {
                exclude.append(CardIds.Secrets.Rogue.DirtyTricks)
                exclude.append(CardIds.Secrets.Mage.ManaBind)
            }

            if freeSpaceOnBoard {
                // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                Thread.sleep(forTimeInterval: 0.2)
                if let target = game.entities[entity[.card_target]],
                    entity.has(tag: .card_target),
                    target.isMinion {
                    exclude.append(CardIds.Secrets.Mage.Spellbender)
                }
                exclude.append(CardIds.Secrets.Hunter.CatTrick)
                exclude.append(CardIds.Secrets.Mage.NetherwindPortal)
                exclude.append(CardIds.Secrets.Rogue.StickySituation)
            }

            if game.playerMinionCount > 0 {
                exclude.append(CardIds.Secrets.Hunter.PressurePlate)
            }
        } else if entity.isMinion && game.playerMinionCount > 3 {
            exclude.append(CardIds.Secrets.Paladin.SacredTrial)
        }
        self.exclude(cardIds: exclude)
    }
    
    func onNewSecret(secret: Secret) {
        if secret.entity[GameTag.class] == CardClass.allCases.firstIndex(of: .hunter) {
            entititesInHandOnMinionsPlayed.removeAll()
        }
    }
    
    func handleCardDrawn(entity: Entity) {
        guard handleAction else { return }

        var exclude: [MultiIdCard] = []
        if let playerEntity = game.playerEntity, playerEntity[.num_cards_drawn_this_turn] >= 1 {
            exclude.append(CardIds.Secrets.Rogue.Shenanigans)
        }
        
        self.exclude(cardIds: exclude)
    }

    func handleHeroPower() {
        guard handleAction else { return }
        exclude(cardId: CardIds.Secrets.Hunter.DartTrap)
    }
    
    func onEntityRevealedAsMinion(entity: Entity) {
        if entititesInHandOnMinionsPlayed.contains(entity) && entity.isMinion {
            exclude(cardId: CardIds.Secrets.Hunter.HiddenCache)
        }
    }
    
    func onNewBlock() {
        entityDamageDealtHistory.removeAll()
    }
    
    func entityDamage(dealer: Entity, target: Entity, damage: Int) {
        DispatchQueue.global().async { [self] in
            if target.isHero && target.isControlled(by: game.opponent.id) {
                if !target.has(tag: .immune) {
                    exclude(cardId: CardIds.Secrets.Paladin.EyeForAnEye)
                    exclude(cardId: CardIds.Secrets.Rogue.Evasion)
                    opponentTookDamageDuringTurns.append(game.turnNumber())
                }
            }
            if dealer.isMinion && dealer.isControlled(by: game.player.id) {
                if let dict = entityDamageDealtHistory[dealer.id] {
                    if let hist = dict[target.id] {
                        dict[target.id] = hist + damage
                    } else {
                        dict[target.id] = damage
                    }
                } else {
                    let dict = SynchronizedDictionary<Int, Int>()
                    entityDamageDealtHistory[dealer.id] = dict
                    dict[target.id] = damage
                }
                let damageDealt = entityDamageDealtHistory[dealer.id]?[target.id] ?? 0
                Thread.sleep(forTimeInterval: 0.1)
                //We check both heaolth and zone because sometimes after the await the dealer's health will revert to that of the original card.
                if damageDealt >= 3 && dealer.health > 0 && dealer[.zone] != Zone.graveyard.rawValue {
                    exclude(cardId: CardIds.Secrets.Paladin.Reckoning)
                }
            }
        }
    }
}
