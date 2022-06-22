/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Foundation
import AppCenterAnalytics

enum DeckLocation: Int {
    case unknown, top, bottom
}

class PowerGameStateParser: LogEventParser {
    static let TransferStudentToken = CardIds.Collectible.Neutral.TransferStudent + "t"
    
    let BlockStartRegex = Regex(".*BLOCK_START.*BlockType=(\\w+).*id=(\\d*).*(cardId=(\\w*)).*player=(\\d*).*Target=(.+).*SubOption=(.+)")
    let CardIdRegex = Regex("cardId=(\\w+)")
    let CreationRegex = Regex("FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)")
    let CreationTagRegex = Regex("tag=(\\w+) value=(\\w+)")
    let GameEntityRegex = Regex("GameEntity EntityID=(\\d+)")
    let PlayerEntityRegex = Regex("Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)")
    let PlayerIDRegex = Regex("\\[hi\\=(\\d+)\\slo=(\\d+)")
    let PlayerNameRegex = Regex("id=(\\d) Player=(.+) TaskList=(\\d)")
    let TagChangeRegex = Regex("TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)")
    let UpdatingEntityRegex = Regex("(SHOW_ENTITY|CHANGE_ENTITY) - Updating Entity=(.+) CardID=(\\w*)")
    let BuildNumberRegex = Regex("BuildNumber=(\\d+)")
    let PlayerIDNameRegex = Regex("PlayerID=(\\d+), PlayerName=(.+)")
    let HideEntityRegex = Regex("HIDE_ENTITY\\ -\\ .* id=(?<id>(\\d+))")
    let ShuffleRegex = Regex("SHUFFLE_DECK\\ PlayerID=(?<id>(\\d+))")
    var tagChangeHandler = TagChangeHandler()
    var currentEntity: Entity?

	private unowned(unsafe) let eventHandler: PowerEventHandler

	init(with eventHandler: PowerEventHandler) {
		self.eventHandler = eventHandler
        self.tagChangeHandler.setPowerGameStateParser(parser: self)
	}

    // MARK: - Entities

    private var currentEntityId = 0
    
    private var trackedFailure = false

    func resetCurrentEntity() {
        currentEntityId = 0
    }
    func set(currentEntity id: Int) {
        currentEntityId = id
    }

    // MARK: - blocks
    func blockStart(type: String?, cardId: String?) {
        maxBlockId += 1
        let blockId = maxBlockId
        currentBlock = currentBlock?.createChild(blockId: blockId, type: type, cardId: cardId)
            ?? Block(parent: nil, id: blockId, type: type, cardId: cardId)
    }

    func blockEnd() {
        currentBlock = currentBlock?.parent
        if let entity = eventHandler.entities[currentEntityId] {
            entity.info.hasOutstandingTagChanges = false
        }
    }

    private var maxBlockId: Int = 0
    private var currentBlock: Block?
    
    func getCurrentBlock() -> Block? {
        return self.currentBlock
    }

    // MARK: - line handling

    func handle(logLine: LogLine) {
        var creationTag = false

        // current game
        if GameEntityRegex.match(logLine.line) {
            if let match = GameEntityRegex.matches(logLine.line).first,
                let id = Int(match.value) {
                //print("**** GameEntityRegex id:'\(id)'")
				let entity = Entity(id: id)
				entity.name = "GameEntity"

				eventHandler.add(entity: entity)
                set(currentEntity: id)

                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
                return
            }
        }

        // players
        else if PlayerEntityRegex.match(logLine.line) {
            let matches = PlayerEntityRegex.matches(logLine.line)
            if let match = matches.first,
                let id = Int(match.value) {
				let entity = Entity(id: id)
                
                if matches.count > 1 {
                    let playerIdMatch = matches[1]
                    if let playerId = Int(playerIdMatch.value) {
                        entity[.player_id] = playerId
                        if let name = eventHandler.playerName(for: playerId) {
                            entity.name = name
                        }                        
                    }
                }
                eventHandler.add(entity: entity)

                set(currentEntity: id)
                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
                return
            }
        } else if TagChangeRegex.match(logLine.line) {
            let matches = TagChangeRegex.matches(logLine.line)
            let rawEntity = matches[0].value
                .replacingOccurrences(of: "UNKNOWN ENTITY ", with: "")
            let tag = matches[1].value
            let value = matches[2].value

            if rawEntity.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity: rawEntity) {
                let entity = tagChangeHandler.parseEntity(entity: rawEntity)
                if let id = entity.id {
                    tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: id, rawValue: value)
                }
            } else if let id = Int(rawEntity) {
                tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: id, rawValue: value)
            } else {
                var entity = eventHandler.entities.values
                    .first { $0.name == rawEntity }

                if let entity = entity {
                    tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag,
                                               id: entity.id, rawValue: value)
                } else {
                    let players = eventHandler.entities.values
                        .filter { $0.has(tag: .player_id) }
                        .take(2)
                    let unnamedPlayers = players.filter { $0.name.isBlank }
                    let unknownHumanPlayer = players
                        .first { $0.name == "UNKNOWN HUMAN PLAYER" }

                    if unnamedPlayers.count == 0 && unknownHumanPlayer != .none {
                        entity = unknownHumanPlayer
                    }

                    var tmpEntity = eventHandler.tmpEntities.first { $0.name == rawEntity }
                    if tmpEntity == .none {
                        tmpEntity = Entity(id: eventHandler.tmpEntities.count + 1)
                        tmpEntity!.name = rawEntity
                        eventHandler.tmpEntities.append(tmpEntity!)
                    }

                    if let _tag = GameTag(rawString: tag) {
                        let tagValue = tagChangeHandler.parseTag(tag: _tag, rawValue: value)

                        if unnamedPlayers.count == 1 {
                            entity = unnamedPlayers.first
                        } else if unnamedPlayers.count == 2 &&
                            _tag == .current_player && tagValue == 0 {
                            entity = eventHandler.entities.values
                                .first { $0.has(tag: .current_player) }
                        }

                        if let entity = entity, let tmpEntity = tmpEntity {
                            entity.name = tmpEntity.name
                            tmpEntity.tags.forEach({ (gameTag, val) in
                                tagChangeHandler.tagChange(eventHandler: eventHandler,
                                    tag: gameTag, id: entity.id,
                                    value: val)
                            })
                            eventHandler.tmpEntities.remove(tmpEntity)
                            tagChangeHandler.tagChange(eventHandler: eventHandler,
                                                       rawTag: tag,
                                                       id: entity.id,
                                                       rawValue: value)
                        }

                        if let tmpEntity = tmpEntity, eventHandler.tmpEntities.contains(tmpEntity) {
                            tmpEntity[_tag] = tagValue
                            let player: Player? = eventHandler.player.name == tmpEntity.name
                                ? eventHandler.player
                                : (eventHandler.opponent.name == tmpEntity.name ? eventHandler.opponent : nil)

                            if let _player = player,
                                let playerEntity = eventHandler.entities.values
                                    .first(where: { $0[.player_id] == _player.id }) {
                                playerEntity.name = tmpEntity.name
                                tmpEntity.tags.forEach({ gameTag, val in
                                    tagChangeHandler.tagChange(eventHandler: eventHandler,
                                                               tag: gameTag,
                                                               id: playerEntity.id,
                                                               value: val)
                                })
                                eventHandler.tmpEntities.remove(tmpEntity)
                            }
                        }
                    }
                }
            }
        } else if CreationRegex.match(logLine.line) {
            let matches = CreationRegex.matches(logLine.line)
            guard let id = Int(matches[0].value) else {
                logger.error("Failed to convert id to integer: Log line was $(logLine.line)")
                return
            }
            guard let zone = Zone(rawString: matches[1].value) else { return }
            var guessedCardId = false
            var guessedLocation = DeckLocation.unknown
            var cardId: String? = ensureValidCardID(cardId: matches[2].value)

            if eventHandler.entities[id] == .none {
                if cardId.isBlank && zone != .setaside {
                    if let blockId = currentBlock?.id,
                       let known = eventHandler.knownCardIds[blockId]?.first {
                        cardId = known.0
                        if !cardId.isBlank {
                            guessedLocation = known.1
                            logger.verbose("Found data for entity=\(id): CardId=\(cardId ?? ""), location=\(guessedLocation)")
                            eventHandler.knownCardIds.removeValue(forKey: blockId)
                            guessedCardId = true
                        }
                    }
                }

                let entity = Entity(id: id)
                if guessedCardId {
                    entity.info.guessedCardState = GuessedCardState.guessed
                }
                if guessedLocation != .unknown {
                    eventHandler.dredgeCounter += 1
                    let newIndex = eventHandler.dredgeCounter
                    let sign = guessedLocation == .top ? 1 : -1
                    entity.info.deckIndex = sign * newIndex
                }
                if let cid = cardId {
                    entity.cardId = cid
                }
                eventHandler.entities[id] = entity
                
                if currentBlock != nil &&  entity.cardId.uppercased().contains("HERO") {
                    currentBlock!.hasFullEntityHeroPackets = true
                }
            }

            if !cardId.isBlank {
                eventHandler.entities[id]!.cardId = cardId!
            }

            set(currentEntity: id)
            if eventHandler.determinedPlayers() {
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
            }
            eventHandler.currentEntityHasCardId = !cardId.isBlank
            eventHandler.currentEntityZone = zone
            return
        } else if UpdatingEntityRegex.match(logLine.line) {
            let matches = UpdatingEntityRegex.matches(logLine.line)
            let type = matches[0].value
            let rawEntity = matches[1].value
            let cardId = ensureValidCardID(cardId: matches[2].value)
            var entityId: Int?

            if rawEntity.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity: rawEntity) {
                let entity = tagChangeHandler.parseEntity(entity: rawEntity)
                if let _entityId = entity.id {
                    entityId = _entityId
                }
            } else if let _entityId = Int(rawEntity) {
                entityId = _entityId
            }

            if let entityId = entityId {
                if eventHandler.entities[entityId] == .none {
                    let entity = Entity(id: entityId)
                    eventHandler.entities[entityId] = entity
                    entity.info.latestCardId = cardId
                }
                if type != "CHANGE_ENTITY" || eventHandler.entities[entityId]!.cardId.isBlank {
                    eventHandler.entities[entityId]!.cardId = cardId
                }
                
                if type == "SHOW_ENTITY" {
                    let entity = eventHandler.entities[entityId]
                    if entity?.info.guessedCardState != GuessedCardState.none {
                        entity?.info.guessedCardState = GuessedCardState.revealed
                    }
                    if entity?.info.deckIndex ?? 0 < 0, let currentBlock = currentBlock, currentBlock.sourceEntityId != 0 {
                        if let source = eventHandler.entities[currentBlock.sourceEntityId], source.hasDredge {
                            eventHandler.dredgeCounter += 1
                            let newIndex = eventHandler.dredgeCounter
                            entity?.info.deckIndex = newIndex
                            logger.info("Dredge Top: \(entity?.description ?? "")")
                            eventHandler.handlePlayerDredge()
                        }
                    }
                }
                
                if type == "CHANGE_ENTITY" {
                    let entity = eventHandler.entities[entityId]!
                    if entity.info.originalEntityWasCreated == nil {
                        entity.info.originalEntityWasCreated = entity.info.created
                    }
                    if entity[.transformed_from_card] == 46706 {
                        eventHandler.chameleosReveal = (entityId, cardId)
                    }
                }
                
                set(currentEntity: entityId)
                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
            }

            if eventHandler.joustReveals > 0 {
                if let currentEntity = eventHandler.entities[entityId!] {
                    if currentEntity.isControlled(by: eventHandler.opponent.id) {
                        eventHandler.opponentJoust(entity: currentEntity, cardId: cardId,
                                           turn: eventHandler.turnNumber())
                    } else if currentEntity.isControlled(by: eventHandler.player.id) {
                        eventHandler.playerJoust(entity: currentEntity, cardId: cardId,
                                         turn: eventHandler.turnNumber())
                    }
                }
            }
            return
        } else if CreationTagRegex.match(logLine.line)
            && !logLine.line.contains("HIDE_ENTITY") {
            let matches = CreationTagRegex.matches(logLine.line)
            let tag = matches[0].value
            let value = matches[1].value
            tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: currentEntityId,
                                       rawValue: value, isCreationTag: true)
            creationTag = true
        } else if logLine.line.contains("HIDE_ENTITY") {
            let match = HideEntityRegex.matches(logLine.line)
            if match.count > 0 {
                let id = Int(match[0].value) ?? -1
                if let entity = eventHandler.entities[id] {
                    if entity.info.guessedCardState == GuessedCardState.revealed {
                        entity.info.guessedCardState = GuessedCardState.guessed
                    }
                    if currentBlock?.cardId == CardIds.Collectible.Neutral.KingTogwaggle
                        || currentBlock?.cardId == CardIds.NonCollectible.Neutral.KingTogwaggle_KingsRansomToken {
                        entity.info.hidden = true
                    }
                    if let blockId = currentBlock?.id, let known = eventHandler.knownCardIds[blockId]?.first {
                        if entity.cardId == known.0 && known.1 != .unknown {
                            logger.info("Setting DeckLocation=\(known.1) for \(entity.description)")
                            eventHandler.dredgeCounter += 1
                            let newIndex = eventHandler.dredgeCounter
                            let sign = known.1 == .top ? 1 : -1
                            entity.info.deckIndex = sign * newIndex
                        }
                    }
                 }
            }
        } else if ShuffleRegex.match(logLine.line) {
            let match = ShuffleRegex.matches(logLine.line)
            let playerId = Int(match[0].value)
            if playerId == eventHandler.player.id {
                eventHandler.player.shuffleDeck()
                eventHandler.handlePlayerDredge()
            }
        } else if BuildNumberRegex.match(logLine.line) {
            if let buildNumber = Int(BuildNumberRegex.matches(logLine.line)[0].value) {
                eventHandler.set(buildNumber: buildNumber)
            }
        } else if PlayerIDNameRegex.match(logLine.line) {
            let matches = PlayerIDNameRegex.matches(logLine.line)
            if matches.count >= 2, let playerID = Int(matches[0].value) {
                let playerName = matches[1].value
                eventHandler.add(playerName: playerName, for: playerID)
            }
        }
        if logLine.line.contains("End Spectator") {
            eventHandler.gameEnded = true
            eventHandler.gameEnd()
        } else if logLine.line.contains("BLOCK_START") {
            var type: String?
            var cardId: String?
            var correspondPlayer: Int?
            let matches = BlockStartRegex.matches(logLine.line)
            if matches.count > 0 {
                type = matches[0].value
            }
            
            if matches.count > 3 {
                cardId = matches[3].value
            }
            
            let target = getTargetCardId(matches: matches)
            
            if matches.count > 4 {
                if let v = Int(matches[4].value) {
                    correspondPlayer = v
                }
            }
            
            blockStart(type: type, cardId: cardId)

            if matches.count > 0 && (type == "TRIGGER" || type == "POWER") {
                let player = eventHandler.entities.values
                    .first { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.player.id }
                let opponent = eventHandler.entities.values
                    .first { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.opponent.id }

                guard let actionStartingEntityId = Int(matches[1].value) else {
                    if !trackedFailure {
                        trackedFailure = true
                        Analytics.trackEvent("PowerGameStateParser_invalid_action_entity_id", withProperties: ["line": logLine.line])
                    }
                    return
                }
                currentBlock?.sourceEntityId = actionStartingEntityId

                var actionStartingCardId: String? = matches[3].value
                var actionStartingEntity: Entity?

                if !actionStartingCardId.isBlank {
                    actionStartingEntity = eventHandler.entities[actionStartingEntityId]
                    if let actionEntity = actionStartingEntity {
                        actionStartingCardId = actionEntity.cardId
                    }
                }

                if actionStartingCardId.isBlank {
                    return
                }
                
                if type == "TRIGGER" && actionStartingCardId == CardIds.Collectible.Neutral.AugmentedElekk {
                    if currentBlock?.parent != nil {
                        actionStartingCardId = currentBlock?.parent?.cardId
                        type = currentBlock?.parent?.type
                    }
                }

                if type == "TRIGGER" {
                    if let actionStartingCardId = actionStartingCardId {
                        
                        switch actionStartingCardId {
                        case CardIds.Collectible.Neutral.SphereOfSapience:
                            // These are tricky to implement correctly, so
                            // until the are, we will just reset the state
                            // known about the top/bottom of the deck
                            if actionStartingEntity?.isControlled(by: player?.id ?? 0) ?? false {
                                eventHandler.handlePlayerUnknownCardAddedToDeck()
                            }
                        case CardIds.Collectible.Rogue.TradePrinceGallywix:
                            if let lastCardPlayed = eventHandler.lastCardPlayed,
                                let entity = eventHandler.entities[lastCardPlayed] {
                                let cardId = entity.cardId
                                addKnownCardId(eventHandler: eventHandler, cardId: cardId)
                            }
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .TradePrinceGallywix_GallywixsCoinToken)
                        case CardIds.Collectible.Shaman.WhiteEyes:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Shaman
                                            .WhiteEyes_TheStormGuardianToken)
                        case CardIds.Collectible.Hunter.RaptorHatchling:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Hunter
                                            .RaptorHatchling_RaptorPatriarchToken)
                        case CardIds.Collectible.Warrior.DirehornHatchling:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warrior
                                            .DirehornHatchling_DirehornMatriarchToken)
                        case CardIds.Collectible.Mage.FrozenClone:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target,
                                           count: 2)
                        case CardIds.Collectible.Shaman.Moorabi, CardIds.Collectible.Rogue.SonyaShadowdancer:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target)
                        case CardIds.Collectible.Neutral.HoardingDragon:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoinBasic, count: 2)
                        case CardIds.Collectible.Priest.GildedGargoyle:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Druid.AstralTiger:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Druid.AstralTiger)
                        case CardIds.Collectible.Rogue.Kingsbane:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Rogue.Kingsbane)
                        case CardIds.Collectible.Neutral.WeaselTunneler:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Neutral.WeaselTunneler)
                        case CardIds.Collectible.Neutral.SparkDrill:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SparkDrill_SparkToken, count: 2)
                        case CardIds.NonCollectible.Neutral.HakkartheSoulflayer_CorruptedBloodToken:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.HakkartheSoulflayer_CorruptedBloodToken, count: 2)
                        //TODO: Gral, the Shark?
                        case CardIds.Collectible.Paladin.ImmortalPrelate:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Paladin.ImmortalPrelate)
                        case CardIds.Collectible.Warrior.Wrenchcalibur:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
                        case CardIds.Collectible.Priest.SpiritOfTheDead:
                            if correspondPlayer == eventHandler.player.id {
                                addKnownCardId(eventHandler: eventHandler, cardId: eventHandler.player.lastDiedMinionCardId)
                            } else if correspondPlayer == eventHandler.opponent.id {
                                addKnownCardId(eventHandler: eventHandler, cardId: eventHandler.opponent.lastDiedMinionCardId)
                            }
                        case CardIds.Collectible.Druid.SecureTheDeck:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.Claw, count: 3)
                        case CardIds.Collectible.Rogue.Waxadred:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.Waxadred_WaxadredsCandleToken)
                        case CardIds.Collectible.Neutral.BadLuckAlbatross:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.BadLuckAlbatross_AlbatrossToken, count: 2)
                        case CardIds.Collectible.Priest.ReliquaryOfSouls:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Priest.ReliquaryofSouls_ReliquaryPrimeToken)
                        case CardIds.Collectible.Mage.AstromancerSolarian:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.AstromancerSolarian_SolarianPrimeToken)
                        case CardIds.Collectible.Warlock.KanrethadEbonlocke:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.KanrethadEbonlocke_KanrethadPrimeToken)
                        case CardIds.Collectible.Paladin.MurgurMurgurgle:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.MurgurMurgurgle_MurgurglePrimeToken)
                        case CardIds.Collectible.Rogue.Akama:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.Akama_AkamaPrimeToken)
                        case CardIds.Collectible.Druid.ArchsporeMsshifn:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.ArchsporeMsshifn_MsshifnPrimeToken)
                        case CardIds.Collectible.Shaman.LadyVashj:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Shaman.LadyVashj_VashjPrimeToken)
                        case CardIds.Collectible.Hunter.ZixorApexPredator:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Hunter.ZixorApexPredator_ZixorPrimeToken)
                        case CardIds.Collectible.Warrior.KargathBladefist:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.KargathBladefist_KargathPrimeToken)
                        case CardIds.Collectible.Neutral.SneakyDelinquent:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.SneakyDelinquent_SpectralDelinquentToken)
                        case CardIds.Collectible.Neutral.FishyFlyer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.FishyFlyer_SpectralFlyerToken)
                        case CardIds.Collectible.Neutral.SmugSenior:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.SmugSenior_SpectralSeniorToken)
                        case CardIds.Collectible.Rogue.Plagiarize:
                            if let actionEntity = actionStartingEntity {
                                let player = actionEntity.isControlled(by: eventHandler.player.id) ? eventHandler.opponent : eventHandler.player
                                for card in player!.cardsPlayedThisTurn {
                                    addKnownCardId(eventHandler: eventHandler, cardId: card)
                                }
                            }
                        case CardIds.Collectible.Rogue.EfficientOctoBot:
                            if let actionEntity = actionStartingEntity, actionEntity.isControlled(by: eventHandler.opponent.id) {
                                eventHandler.handleOpponentHandCostReduction(value: 1)
                            }
                        case CardIds.Collectible.Neutral.KeymasterAlabaster:
                            // The player controlled side of this is handled by TagChangeActions.OnCardCopy
                            if let actionEntity = actionStartingEntity, actionEntity.isControlled(by: eventHandler.opponent.id) && eventHandler.player.lastDrawnCardId != nil {
                                addKnownCardId(eventHandler: eventHandler, cardId: eventHandler.player.lastDrawnCardId)
                            }
                        case CardIds.Collectible.Neutral.EducatedElekk:
                            if let actionEntity = actionStartingEntity {
                                if actionEntity.isInGraveyard {
                                    for card in actionEntity.info.storedCardIds {
                                        addKnownCardId(eventHandler: eventHandler, cardId: card)
                                    }
                                } else if let lastCardPlayed = eventHandler.lastCardPlayed, let lastPlayedEntity = eventHandler.entities[lastCardPlayed] {
                                        actionEntity.info.storedCardIds.append(lastPlayedEntity.cardId)
                                }
                            }
                        case CardIds.Collectible.Shaman.DiligentNotetaker:
                            if let lastCardPlayed = eventHandler.lastCardPlayed, let lastPlayedEntity1 = eventHandler.entities[lastCardPlayed] {
                                addKnownCardId(eventHandler: eventHandler, cardId: lastPlayedEntity1.cardId)
                            }
                        case CardIds.Collectible.Neutral.CthunTheShattered:
                            // The pieces are created in random order. So we can not assign predicted ids to entities the way we usually do.
                            if let actionStartingEntity = actionStartingEntity {
                                if let player = actionStartingEntity.isControlled(by: eventHandler.player.id) ? eventHandler.player : eventHandler.opponent {
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_EyeOfCthunToken, isCreated: true)
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_BodyOfCthunToken, isCreated: true)
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_MawOfCthunToken, isCreated: true)
                                    player.predictUniqueCardInDeck(cardId: CardIds.NonCollectible.Neutral.CThuntheShattered_HeartOfCthunToken, isCreated: true)
                                }
                            }
                        case CardIds.Collectible.Priest.MidaPureLight:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Priest.MidaPureLight_FragmentOfMidaToken)
                        case CardIds.Collectible.Warlock.CurseOfAgony:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.CurseofAgony_AgonyToken, count: 3)
                        case CardIds.Collectible.Neutral.AzsharanSentinel:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.AzsharanSentinel_SunkenSentinelToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Warrior.AzsharanTrident:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.AzsharanTrident_SunkenTridentToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Hunter.AzsharanSaber:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Hunter.AzsharanSaber_SunkenSaberToken, count: 1, location: .bottom)
                        case CardIds.Collectible.DemonHunter.AzsharanDefector:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.DemonHunter.AzsharanDefector_SunkenDefectorToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Druid.Bottomfeeder:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.Bottomfeeder, count: 1, location: .bottom)
                        case CardIds.Collectible.Shaman.PiranhaPoacher:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.PiranhaSwarmer) // is this the correct token? There are 4 different ones
                        default: break
                        }
                    }
                } else { // type == "POWER"
                    if let actionStartingCardId = actionStartingCardId {
                        switch actionStartingCardId {
                        case CardIds.Collectible.DemonHunter.SightlessWatcherCore,
                            CardIds.Collectible.DemonHunter.SightlessWatcherLegacy,
                            CardIds.Collectible.Neutral.SirFinleySeaGuide,
                            CardIds.Collectible.Neutral.AmbassadorFaelin:
                            // These are tricky to implement correctly, so
                            // until the are, we will just reset the state
                            // known about the top/bottom of the deck
                            if actionStartingEntity?.isControlled(by: player?.id ?? 0) ?? false {
                                eventHandler.handlePlayerUnknownCardAddedToDeck()
                            }
                        case CardIds.Collectible.Rogue.GangUp,
                             CardIds.Collectible.Hunter.DireFrenzy,
                             CardIds.Collectible.Rogue.LabRecruiter:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target,
                                           count: 3)
                        case CardIds.Collectible.Rogue.BeneathTheGrounds:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Rogue
                                            .BeneaththeGrounds_NerubianAmbushToken,
                                           count: 3)
                        case CardIds.Collectible.Warrior.IronJuggernaut:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warrior
                                            .IronJuggernaut_BurrowingMineToken)
                        case CardIds.Collectible.Druid.Recycle,
                             CardIds.Collectible.Mage.ManicSoulcaster,
                             CardIds.Collectible.Neutral.ZolaTheGorgon,
                             CardIds.Collectible.Neutral.ZolaTheGorgon1810,
                             CardIds.Collectible.Druid.Splintergraft,
                             //CardIds.Collectible.Priest.HolyWater: -- TODO
                             CardIds.Collectible.Neutral.BalefulBanker,
                             CardIds.Collectible.Neutral.DollmasterDorian,
                             CardIds.Collectible.Priest.Seance,
                             CardIds.Collectible.Druid.MarkOfTheSpikeshell:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target)
                        case CardIds.Collectible.Mage.ForgottenTorch:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Mage
                                            .ForgottenTorch_RoaringTorchToken)
                        case CardIds.Collectible.Warlock.CurseOfRafaam:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warlock
                                            .CurseofRafaam_CursedToken)
                        case CardIds.Collectible.Neutral.AncientShade:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .AncientShade_AncientCurseToken)
                        case CardIds.Collectible.Priest.ExcavatedEvil:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Priest.ExcavatedEvil)
                        case CardIds.Collectible.Neutral.EliseStarseeker,
                             CardIds.Collectible.Neutral.EliseStarseeker1810:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .EliseStarseeker_MapToTheGoldenMonkeyToken)
                        case CardIds.NonCollectible.Neutral
                            .EliseStarseeker_MapToTheGoldenMonkeyToken:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .EliseStarseeker_GoldenMonkeyToken)
                        case CardIds.Collectible.Neutral.Doomcaller:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.Cthun)
                        case CardIds.Collectible.Druid.JadeIdol:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Druid.JadeIdol,
                                           count: 3)
                        case CardIds.NonCollectible.Hunter.TheMarshQueen_QueenCarnassaToken:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Hunter
                                            .TheMarshQueen_CarnassasBroodToken,
                                           count: 15)
                        case CardIds.Collectible.Neutral.EliseTheTrailblazer:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .ElisetheTrailblazer_UngoroPackToken)
                        case CardIds.Collectible.Mage.GhastlyConjurer:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Mage.MirrorImage)
                        case CardIds.Collectible.Druid.ThorngrowthSentries:
                            addKnownCardId(eventHandler: eventHandler, cardId:
                                            CardIds.NonCollectible.Druid.ThorngrowthSentries_ThornguardTurtleToken,
                                           count: 2)
                        case CardIds.Collectible.Mage.DeckOfWonders:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Mage.DeckofWondersScrollOfWonderToken, count: 5)
                        case CardIds.Collectible.Neutral.TheDarkness:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheDarknessDarknessCandleToken, count: 3)
                        case CardIds.Collectible.Rogue.FaldoreiStrider:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Rogue.FaldoreiStrider_SpiderAmbushEnchantment, count: 3)
                        case CardIds.Collectible.Neutral.KingTogwaggle:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.KingTogwaggle_KingsRansomToken)
                        case CardIds.NonCollectible.Neutral.TheCandle:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCandle)
                        case CardIds.NonCollectible.Neutral.CoinPouchGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SackOfCoinsGILNEAS)
                        case CardIds.NonCollectible.Neutral.SackOfCoinsGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.HeftySackOfCoinsGILNEAS)
                        case CardIds.NonCollectible.Neutral.CreepyCurioGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.HauntedCurioGILNEAS)
                        case CardIds.NonCollectible.Neutral.HauntedCurioGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.CursedCurioGILNEAS)
                        case CardIds.NonCollectible.Neutral.OldMilitiaHornGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.MilitiaHornGILNEAS)
                        case CardIds.NonCollectible.Neutral.MilitiaHornGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.VeteransMilitiaHornGILNEAS)
                        case CardIds.NonCollectible.Neutral.SurlyMobGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.AngryMobGILNEAS)
                        case CardIds.NonCollectible.Neutral.AngryMobGILNEAS:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.CrazedMobGILNEAS)
                        case CardIds.Collectible.Neutral.SparkEngine:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SparkDrill_SparkToken)
                        case CardIds.Collectible.Priest.ExtraArms:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Priest.ExtraArms_MoreArmsToken)
                        case CardIds.Collectible.Neutral.SeaforiumBomber,
                             CardIds.Collectible.Warrior.ClockworkGoblin:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
                        //case Collectible.Rogue.Wanted: -- TODO
                        //    AddKnownCardId(gameState, NonCollectible.Neutral.TheCoin);
                        //    break;
                        //TODO: Hex Lord Malacrass
                        //TODO: Krag'wa, the Frog
                        case CardIds.Collectible.Hunter.HalazziTheLynx:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Hunter.Springpaw_LynxToken, count: 10)
                        case CardIds.Collectible.Neutral.BananaVendor:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.BananaBuffoon_BananasToken, count: 4)
                        case CardIds.Collectible.Neutral.BananaBuffoon:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.BananaBuffoon_BananasToken, count: 2)
                        case CardIds.Collectible.Neutral.BootyBayBookie:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Neutral.PortalKeeper, CardIds.Collectible.Neutral.PortalOverfiend:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.PortalKeeper_FelhoundPortalToken)
                        case CardIds.Collectible.Rogue.TogwagglesScheme:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: target)
                        case CardIds.Collectible.Paladin.SandwaspQueen:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Paladin.SandwaspQueen_SandwaspToken,
                                           count: 2)
                        case CardIds.Collectible.Rogue.ShadowOfDeath:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Rogue.ShadowofDeath_ShadowToken,
                                           count: 3)
                        case CardIds.Collectible.Warlock.Impbalming:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warlock.Impbalming_WorthlessImpToken,
                                           count: 3)
                        case CardIds.Collectible.Druid.YseraUnleashed:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.YseraUnleashed_DreamPortalToken, count: 7)
                        case CardIds.Collectible.Rogue.BloodsailFlybooter:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.BloodsailFlybooter_SkyPirateToken, count: 2)
                        case CardIds.Collectible.Rogue.UmbralSkulker:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic, count: 3)
                        case CardIds.Collectible.Neutral.Sathrovarr:
                            addKnownCardId(eventHandler: eventHandler, cardId: target, count: 3)
                        case CardIds.Collectible.Neutral.DragonBreeder:
                            addKnownCardId(eventHandler: eventHandler, cardId: target)
                        case CardIds.Collectible.Warlock.SchoolSpirits, CardIds.Collectible.Warlock.SoulShear, CardIds.Collectible.Warlock.SpiritJailer, CardIds.Collectible.DemonHunter.Marrowslicer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.SchoolSpirits_SoulFragmentToken, count: 2)
                        case CardIds.Collectible.Mage.ConfectionCyclone:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.ConfectionCyclone_SugarElementalToken, count: 2)
                        case CardIds.Collectible.Druid.KiriChosenOfElune:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.LunarEclipse)
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Druid.SolarEclipse)
                        case CardIds.NonCollectible.Neutral.CThuntheShattered_EyeOfCthunToken,
                             CardIds.NonCollectible.Neutral.CThuntheShattered_HeartOfCthunToken,
                             CardIds.NonCollectible.Neutral.CThuntheShattered_BodyOfCthunToken,
                             CardIds.NonCollectible.Neutral.CThuntheShattered_MawOfCthunToken:
                            // A new copy of C'Thun is created in the last of these POWER blocks.
                            // This currently leads to a duplicate copy of C'Thun showing up in the
                            // opponents deck list, but it will have to do for now.
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.CthunTheShattered)
                        case CardIds.Collectible.Hunter.SunscaleRaptor:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Hunter.SunscaleRaptor)
                        case CardIds.Collectible.Neutral.Mankrik:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.Mankrik_OlgraMankriksWifeToken)
                        case CardIds.Collectible.Neutral.ShadowHunterVoljin:
                            addKnownCardId(eventHandler: eventHandler, cardId: target)
                        case CardIds.Collectible.Paladin.AldorAttendant:
                            if let ent = actionStartingEntity {
                                if ent.isControlled(by: eventHandler.player.id) {
                                    eventHandler.handlePlayerLibramReduction(change: 1)
                                } else {
                                    eventHandler.handleOpponentLibramReduction(change: 1)
                                }
                            }
                        case CardIds.Collectible.Paladin.AldorTruthseeker:
                            if let ent = actionStartingEntity {
                                if ent.isControlled(by: eventHandler.player.id) {
                                    eventHandler.handlePlayerLibramReduction(change: 2)
                                } else {
                                    eventHandler.handleOpponentLibramReduction(change: 2)
                                }
                            }
                        case CardIds.Collectible.Druid.VibrantSquirrel:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.VibrantSquirrel_AcornToken, count: 4)
                        case CardIds.Collectible.Mage.FirstFlame:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage
                                            .FirstFlame_SecondFlameToken)
                        case CardIds.Collectible.Rogue.Garrote:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.Garrote_BleedToken, count: 3)
                        case CardIds.Collectible.Neutral.MailboxDancer:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Neutral.NorthshireFarmer:
                            addKnownCardId(eventHandler: eventHandler, cardId: target, count: 3)
                        case CardIds.Collectible.Rogue.LoanShark:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.TheCoinBasic)
                        case CardIds.Collectible.Warlock.SeedsOfDestruction:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.DreadlichTamsin_FelRiftToken, count: 3)
                        case CardIds.Collectible.Mage.BuildASnowman:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.BuildaSnowman_BuildASnowbruteToken)
                        case CardIds.Collectible.Warrior.Scrapsmith:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warrior.Scrapsmith_ScrappyGruntToken)
                        case CardIds.Collectible.Neutral.RamCommander:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.RamCommander_BattleRamToken)
                        case CardIds.Collectible.Warlock.DraggedBelow,
                            CardIds.Collectible.Warlock.SirakessCultist:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.SirakessCultist_AbyssalCurseToken, count: 1)
                        case CardIds.Collectible.Neutral.SchoolTeacher:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Neutral.SchoolTeacher_NagalingToken, count: 1)
                        case CardIds.Collectible.Warlock.AzsharanScavenger:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Warlock.AzsharanScavenger_SunkenScavengerToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Priest.AzsharanRitual:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Priest.AzsharanRitual_SunkenRitualToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Shaman.AzsharanScroll:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Shaman.AzsharanScroll_SunkenScrollToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Paladin.AzsharanMooncatcher:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Paladin.AzsharanMooncatcher_SunkenMooncatcherToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Rogue.AzsharanVessel:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Rogue.AzsharanVessel_SunkenVesselToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Shaman.Schooling:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.Collectible.Neutral.PiranhaSwarmer, count: 3) // is this the correct token? There are 4 different ones
                        case CardIds.Collectible.Druid.AzsharanGardens:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Druid.AzsharanGardens_SunkenGardensToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Mage.AzsharanSweeper:
                            addKnownCardId(eventHandler: eventHandler, cardId: CardIds.NonCollectible.Mage.AzsharanSweeper_SunkenSweeperToken, count: 1, location: .bottom)
                        case CardIds.Collectible.Rogue.BootstrapSunkeneer:
                            if target != nil {
                                addKnownCardId(eventHandler: eventHandler, cardId: target, count: 1, location: .bottom)
                            }
                        default:
                            if let card = Cards.any(byId: actionStartingCardId) {
                                if (player != nil && player![.current_player] == 1
                                    && !eventHandler.playerUsedHeroPower)
                                    || (opponent != nil && opponent![.current_player] == 1
                                        && !eventHandler.opponentUsedHeroPower) {
                                    if card.type == .hero_power {
                                        if player != nil && player![.current_player] == 1 {
                                            eventHandler.playerHeroPower(cardId: actionStartingCardId,
                                                                 turn: eventHandler.turnNumber())
                                            eventHandler.playerUsedHeroPower = true
                                        } else if opponent != nil {
                                            eventHandler.opponentHeroPower(cardId: actionStartingCardId,
                                                                   turn: eventHandler.turnNumber())
                                            eventHandler.opponentUsedHeroPower = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if logLine.line.contains("BlockType=JOUST") {
                eventHandler.joustReveals = 2
            } else if eventHandler.gameTriggerCount == 0
                && logLine.line.contains("BLOCK_START BlockType=TRIGGER Entity=GameEntity") {
                eventHandler.gameTriggerCount += 1
            }
        } else if logLine.line.contains("CREATE_GAME") {
            tagChangeHandler.clearQueuedActions()

            // indicate game start
            maxBlockId = 0
            currentBlock = nil
            resetCurrentEntity()
//            eventHandler.gameStart(at: logLine.time)
        } else if logLine.line.contains("BLOCK_END") {
            if eventHandler.gameTriggerCount < 10 && (eventHandler.gameEntity?.has(tag: .turn) ?? false) {
                eventHandler.gameTriggerCount += 10
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                eventHandler.setupDone = true
            }
            
            if let currentBlock = currentBlock, currentBlock.type == "JOUST" || currentBlock.type == "REVEAL_CARD" {
                //make sure there are no more queued actions that might depend on JoustReveals
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                eventHandler.joustReveals = 0
            }
            
            if let currentBlock = currentBlock, let chameleosReveal = eventHandler.chameleosReveal,
                let chameleos = eventHandler.entities[chameleosReveal.0], currentBlock.type == "TRIGGER"
                && (currentBlock.cardId == CardIds.NonCollectible.Neutral.Chameleos_ShiftingEnchantment
                    || currentBlock.cardId == CardIds.Collectible.Priest.Chameleos) && chameleos.has(tag: .shifting) {
                eventHandler.handleChameleosReveal(cardId: chameleosReveal.1)
            }
            
            eventHandler.chameleosReveal = nil
            
            if currentBlock?.type == "TRIGGER" && currentBlock?.cardId == CardIds.NonCollectible.Neutral.Baconshop8playerenchantTavernBrawl && currentBlock?.hasFullEntityHeroPackets ?? false && (eventHandler.turn() % 2 == 0) {
                eventHandler.startCombat()
            }
            blockEnd()
        }

        if eventHandler.isInMenu { return }

        if !creationTag && eventHandler.determinedPlayers() {
            tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
        }
        if !creationTag {
            resetCurrentEntity()
        }
    }
    
    private func autoDetectDeck() {
        // Autodecting deck might require the full CREATE_GAME block to function properly, thus it should be called right after it
        // detect deck
        if Settings.autoDeckDetection && !(Settings.dontTrackWhileSpectating && eventHandler.currentGameMode == .spectator) {
            let currentMode = eventHandler.currentMode ?? .invalid
            if let deck = AppDelegate._instance?.coreManager.autoDetectDeck(mode: currentMode, playerClass: self.eventHandler.player.playerClass) {
                eventHandler.set(activeDeckId: deck.deckId, autoDetected: true)
            } else if currentMode != .adventure && currentMode != .pvp_dungeon_run {
                logger.warning("could not autodetect deck, setting to empty deck")
                eventHandler.set(activeDeckId: nil, autoDetected: false)
            }
        }
    }
    
    private func ensureValidCardID(cardId: String) -> String {
        if cardId.starts(with: PowerGameStateParser.TransferStudentToken) && !cardId.hasSuffix("e") {
            return CardIds.Collectible.Neutral.TransferStudent
        }
        if let overrideId = CardIds.upgradeOverrides[cardId] {
            return overrideId
        }
        return cardId
    }

    private func getTargetCardId(matches: [Match]) -> String? {
        if matches.count < 5 {
            return nil
        }
        let target = matches[4].value.trim()
        guard target.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity: target) else {
            return nil
        }
        guard CardIdRegex.match(target) else { return nil }

        let cardIdMatch = CardIdRegex.matches(target)
        return cardIdMatch.first?.value.trim()
    }

    private func addKnownCardId(eventHandler: PowerEventHandler, cardId: String?, count: Int = 1, location: DeckLocation = .unknown) {
        guard let cardId = cardId else { return }

        if let blockId = currentBlock?.id {
            for _ in 0 ..< count {
                if eventHandler.knownCardIds[blockId] == nil {
                    eventHandler.knownCardIds[blockId] = []
                }

                eventHandler.knownCardIds[blockId]?.append((cardId, location))
            }
        }
    }

    private func reset() {
        tagChangeHandler.clearQueuedActions()
    }
}
