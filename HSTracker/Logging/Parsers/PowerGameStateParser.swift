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
import CleanroomLogger
import RegexUtil

class PowerGameStateParser: LogEventParser {

    let BlockStartRegex = RegexPattern(stringLiteral: ".*BLOCK_START.*BlockType=(POWER|TRIGGER)"
        + ".*id=(\\d*).*(cardId=(\\w*)).*Target=(.+)")
    let CardIdRegex: RegexPattern = "cardId=(\\w+)"
    let CreationRegex: RegexPattern = "FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)"
    let CreationTagRegex: RegexPattern = "tag=(\\w+) value=(\\w+)"
    let GameEntityRegex: RegexPattern = "GameEntity EntityID=(\\d+)"
    let PlayerEntityRegex: RegexPattern = "Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)"
    let PlayerNameRegex: RegexPattern = "id=(\\d) Player=(.+) TaskList=(\\d)"
    let TagChangeRegex: RegexPattern = "TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)"
    let UpdatingEntityRegex: RegexPattern = "SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)"
	
    var tagChangeHandler = TagChangeHandler()
    var currentEntity: Entity?
	
	private unowned(unsafe) let eventHandler: PowerEventHandler
	
	init(with eventHandler: PowerEventHandler) {
		self.eventHandler = eventHandler
	}

    func handle(logLine: LogLine) {
        var creationTag = false

        // current game
        if logLine.line.match(GameEntityRegex) {

            if let match = logLine.line.matches(GameEntityRegex).first,
                let id = Int(match.value) {
                //print("**** GameEntityRegex id:'\(id)'")
				let entity = Entity(id: id)
				entity.name = "GameEntity"
				
				eventHandler.add(entity: entity)
                eventHandler.set(currentEntity: id)
				
                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
                return
            }
        }

        // players
        else if logLine.line.match(PlayerEntityRegex) {
            if let match = logLine.line.matches(PlayerEntityRegex).first,
                let id = Int(match.value) {
				let entity = Entity(id: id)
                eventHandler.add(entity: entity)
				
                if eventHandler.wasInProgress {
                    //game.entities[id]?.name = game.getStoredPlayerName(id: id)
                }
                eventHandler.set(currentEntity: id)
                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
                return
            }
        } else if logLine.line.match(TagChangeRegex) {
            let matches = logLine.line.matches(TagChangeRegex)
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
                var entity = eventHandler.entities.map { $0.1 }.firstWhere { $0.name == rawEntity }

                if let entity = entity {
                    tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag,
                                               id: entity.id, rawValue: value)
                } else {
                    let players = eventHandler.entities.map { $0.1 }
                        .filter { $0.has(tag: .player_id) }.take(2)
                    let unnamedPlayers = players.filter { $0.name.isBlank }
                    let unknownHumanPlayer = players
                        .first { $0.name == "UNKNOWN HUMAN PLAYER" }
                    
                    if unnamedPlayers.count == 0 && unknownHumanPlayer != .none {
                        entity = unknownHumanPlayer
                    }

                    var tmpEntity = eventHandler.tmpEntities.firstWhere { $0.name == rawEntity }
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
                            entity = eventHandler.entities.map { $0.1 }
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
                                let playerEntity = eventHandler.entities.map({$0.1}).first({
                                    $0[.player_id] == _player.id
                                }) {
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
        } else if logLine.line.match(CreationRegex) {
            let matches = logLine.line.matches(CreationRegex)
            let id = Int(matches[0].value)!
            guard let zone = Zone(rawString: matches[1].value) else { return }
            var cardId: String? = matches[2].value

            if eventHandler.entities[id] == .none {
                if cardId.isBlank && zone != .setaside {
                    if let blockId = eventHandler.currentBlock?.id,
                        let cards = eventHandler.knownCardIds[blockId] {
                        cardId = cards.first
                        if !cardId.isBlank {
                            Log.verbose?.message("Found known cardId "
                                + "'\(String(describing: cardId))' for entity \(id)")
                            eventHandler.knownCardIds[id] = nil
                        }
                    }
                }

                let entity = Entity(id: id)
                eventHandler.entities[id] = entity
            }

            if !cardId.isBlank {
                eventHandler.entities[id]!.cardId = cardId!
            }

            eventHandler.set(currentEntity: id)
            if eventHandler.determinedPlayers() {
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
            }
            eventHandler.currentEntityHasCardId = !cardId.isBlank
            eventHandler.currentEntityZone = zone
            return
        } else if logLine.line.match(UpdatingEntityRegex) {
            let matches = logLine.line.matches(UpdatingEntityRegex)
            let rawEntity = matches[0].value
            let cardId = matches[1].value
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
                }
                eventHandler.entities[entityId]!.cardId = cardId
                eventHandler.set(currentEntity: entityId)
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
        } else if logLine.line.match(CreationTagRegex)
            && !logLine.line.contains("HIDE_ENTITY") {
            let matches = logLine.line.matches(CreationTagRegex)
            let tag = matches[0].value
            let value = matches[1].value
            tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: eventHandler.currentEntityId,
                                       rawValue: value, isCreationTag: true)
            creationTag = true
        }
        if logLine.line.contains("End Spectator") {
            eventHandler.gameEnd()
        } else if logLine.line.contains("BLOCK_START") {
            eventHandler.blockStart()

            if logLine.line.match(BlockStartRegex) {
                let player = eventHandler.entities.map { $0.1 }
                    .firstWhere { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.player.id }
                let opponent = eventHandler.entities.map { $0.1 }
                    .firstWhere { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.opponent.id }

                let matches = logLine.line.matches(BlockStartRegex)
                let type = matches[0].value
                let actionStartingEntityId = Int(matches[1].value)!
                var actionStartingCardId: String? = matches[3].value

                if actionStartingCardId.isBlank {
                    if let actionEntity = eventHandler.entities[actionStartingEntityId] {
                        actionStartingCardId = actionEntity.cardId
                    }
                }

                if actionStartingCardId.isBlank {
                    return
                }

                if type == "TRIGGER" {
                    if let actionStartingCardId = actionStartingCardId {
                        switch actionStartingCardId {
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
                        default: break
                        }
                    }
                } else {
                    if let actionStartingCardId = actionStartingCardId {
                        switch actionStartingCardId {
                        case CardIds.Collectible.Rogue.GangUp:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: getTargetCardId(matches: matches),
                                           count: 3)
                        case CardIds.Collectible.Rogue.BeneathTheGrounds:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Rogue
                                            .BeneaththeGrounds_AmbushToken,
                                           count: 3)
                        case CardIds.Collectible.Warrior.IronJuggernaut:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Warrior
                                            .IronJuggernaut_BurrowingMineToken)
                        case CardIds.Collectible.Druid.Recycle,
                             CardIds.Collectible.Mage.ManicSoulcaster:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: getTargetCardId(matches: matches))
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
                        case CardIds.Collectible.Neutral.EliseStarseeker:
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
            if Settings.autoDeckDetection {
                if let currentMode = eventHandler.currentMode,
                    let deck = CoreManager.autoDetectDeck(mode: currentMode) {
                    eventHandler.set(activeDeckId: deck.deckId, autoDetected: true)
                } else {
                    Log.warning?.message("could not autodetect deck")
                    eventHandler.set(activeDeckId: nil, autoDetected: false)
                }
            }
            eventHandler.gameStart(at: logLine.time)
        } else if logLine.line.contains("BLOCK_END") {
            if eventHandler.gameTriggerCount < 10 && (eventHandler.gameEntity?.has(tag: .turn) ?? false) {
                eventHandler.gameTriggerCount += 10
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                eventHandler.setupDone = true
            }
            eventHandler.blockEnd()
        }

        if eventHandler.isInMenu { return }

        if !creationTag && eventHandler.determinedPlayers() {
            tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
        }
        if !creationTag {
            eventHandler.resetCurrentEntity()
        }
    }

    private func getTargetCardId(matches: [Match]) -> String? {
        let target = matches[4].value.trim()
        guard target.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity: target) else {
            return nil
        }
        guard target.match(CardIdRegex) else { return nil }

        let cardIdMatch = target.matches(CardIdRegex)
        return cardIdMatch.first?.value.trim()
    }

    private func addKnownCardId(eventHandler: PowerEventHandler, cardId: String?, count: Int = 1) {
        guard let cardId = cardId else { return }

        if let blockId = eventHandler.currentBlock?.id {
            for _ in 0 ..< count {
                if eventHandler.knownCardIds[blockId] == nil {
                    eventHandler.knownCardIds[blockId] = []
                }

                eventHandler.knownCardIds[blockId]?.append(cardId)
            }
        }
    }

    private func reset() {
        tagChangeHandler.clearQueuedActions()
    }
}
