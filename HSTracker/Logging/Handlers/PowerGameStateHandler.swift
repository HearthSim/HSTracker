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

class PowerGameStateHandler: LogEventHandler {

    let BlockStartRegex = ".*BLOCK_START.*BlockType=(POWER|TRIGGER).*id=(\\d*)"
        + ".*(cardId=(\\w*)).*Target=(.+)"
    let CardIdRegex = "cardId=(\\w+)"
    let CreationRegex = "FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)"
    let CreationTagRegex = "tag=(\\w+) value=(\\w+)"
    let GameEntityRegex = "GameEntity EntityID=(\\d+)"
    let PlayerEntityRegex = "Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)"
    let PlayerNameRegex = "id=(\\d) Player=(.+) TaskList=(\\d)"
    let TagChangeRegex = "TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)"
    let UpdatingEntityRegex = "SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)"

    var tagChangeHandler = TagChangeHandler()
    var currentEntity: Entity?
	
	private unowned let coreManager: CoreManager
	
	init(with coreManager: CoreManager) {
		self.coreManager = coreManager
	}

    func handle(logLine: LogLine) {
        var creationTag = false
		let game = coreManager.game

        // current game
        if logLine.line.match(GameEntityRegex) {
            game.gameStart(at: logLine.time)

            if let match = logLine.line.matches(GameEntityRegex).first,
                let id = Int(match.value) {
                //print("**** GameEntityRegex id:'\(id)'")
                if game.entities[id] == .none {
                    let entity = Entity(id: id)
                    entity.name = "GameEntity"
                    game.entities[id] = entity
                }
                game.set(currentEntity: id)
                if game.determinedPlayers {
                    tagChangeHandler.invokeQueuedActions(game: game)
                }
                return
            }
        }

        // players
        else if logLine.line.match(PlayerEntityRegex) {
            if let match = logLine.line.matches(PlayerEntityRegex).first,
                let id = Int(match.value) {
                if game.entities[id] == .none {
                    game.entities[id] = Entity(id: id)
                }
                if game.wasInProgress {
                    //game.entities[id]?.name = game.getStoredPlayerName(id: id)
                }
                game.set(currentEntity: id)
                if game.determinedPlayers {
                    tagChangeHandler.invokeQueuedActions(game: game)
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
                    tagChangeHandler.tagChange(game: game, rawTag: tag, id: id, rawValue: value)
                }
            } else if let id = Int(rawEntity) {
                tagChangeHandler.tagChange(game: game, rawTag: tag, id: id, rawValue: value)
            } else {
                var entity = game.entities.map { $0.1 }.firstWhere { $0.name == rawEntity }

                if let entity = entity {
                    tagChangeHandler.tagChange(game: game, rawTag: tag,
                                               id: entity.id, rawValue: value)
                } else {
                    let players = game.entities.map { $0.1 }
                        .filter { $0.has(tag: .player_id) }.take(2)
                    let unnamedPlayers = players.filter { String.isNullOrEmpty($0.name) }
                    let unknownHumanPlayer = players
                        .first { $0.name == "UNKNOWN HUMAN PLAYER" }
                    
                    if unnamedPlayers.count == 0 && unknownHumanPlayer != .none {
                        entity = unknownHumanPlayer
                    }

                    var tmpEntity = game.tmpEntities.firstWhere { $0.name == rawEntity }
                    if tmpEntity == .none {
                        tmpEntity = Entity(id: game.tmpEntities.count + 1)
                        tmpEntity!.name = rawEntity
                        game.tmpEntities.append(tmpEntity!)
                    }

                    if let _tag = GameTag(rawString: tag) {
                        let tagValue = tagChangeHandler.parseTag(tag: _tag, rawValue: value)

                        if unnamedPlayers.count == 1 {
                            entity = unnamedPlayers.first
                        } else if unnamedPlayers.count == 2 &&
                            _tag == .current_player && tagValue == 0 {
                            entity = game.entities.map { $0.1 }
                                .first { $0.has(tag: .current_player) }
                        }

                        if let entity = entity, let tmpEntity = tmpEntity {
                            entity.name = tmpEntity.name
                            tmpEntity.tags.forEach({ (gameTag, val) in
                                tagChangeHandler.tagChange(game: game,
                                    tag: gameTag, id: entity.id,
                                    value: val)
                            })
                            game.tmpEntities.remove(tmpEntity)
                            tagChangeHandler.tagChange(game: game,
                                                       rawTag: tag,
                                                       id: entity.id,
                                                       rawValue: value)
                        }

                        if let tmpEntity = tmpEntity, game.tmpEntities.contains(tmpEntity) {
                            tmpEntity[_tag] = tagValue
                            let player: Player? = game.player.name == tmpEntity.name
                                ? game.player
                                : (game.opponent.name == tmpEntity.name ? game.opponent : nil)

                            if let _player = player,
                                let playerEntity = game.entities.map({$0.1}).first({
                                    $0[.player_id] == _player.id
                                }) {
                                playerEntity.name = tmpEntity.name
                                tmpEntity.tags.forEach({ gameTag, val in
                                    tagChangeHandler.tagChange(game: game,
                                                               tag: gameTag,
                                                               id: playerEntity.id,
                                                               value: val)
                                })
                                game.tmpEntities.remove(tmpEntity)
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

            if game.entities[id] == .none {
                if String.isNullOrEmpty(cardId) && zone != .setaside {
                    if let blockId = game.currentBlock?.id,
                        let cards = game.knownCardIds[blockId] {
                        cardId = cards.first
                        if !String.isNullOrEmpty(cardId) {
                            Log.verbose?.message("Found known cardId '\(cardId)' for entity \(id)")
                            game.knownCardIds[id] = nil
                        }
                    }
                }

                let entity = Entity(id: id)
                game.entities[id] = entity
            }

            if !String.isNullOrEmpty(cardId) {
                game.entities[id]!.cardId = cardId!
            }

            game.set(currentEntity: id)
            if game.determinedPlayers {
                tagChangeHandler.invokeQueuedActions(game: game)
            }
            game.currentEntityHasCardId = !String.isNullOrEmpty(cardId)
            game.currentEntityZone = zone
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
                if game.entities[entityId] == .none {
                    let entity = Entity(id: entityId)
                    game.entities[entityId] = entity
                }
                game.entities[entityId]!.cardId = cardId
                game.set(currentEntity: entityId)
                if game.determinedPlayers {
                    tagChangeHandler.invokeQueuedActions(game: game)
                }
            }

            if game.joustReveals > 0 {
                if let currentEntity = game.entities[entityId!] {
                    if currentEntity.isControlled(by: game.opponent.id) {
                        game.opponentJoust(entity: currentEntity, cardId: cardId,
                                           turn: game.turnNumber())
                    } else if currentEntity.isControlled(by: game.player.id) {
                        game.playerJoust(entity: currentEntity, cardId: cardId,
                                         turn: game.turnNumber())
                    }
                }
            }
            return
        } else if logLine.line.match(CreationTagRegex)
            && !logLine.line.contains("HIDE_ENTITY") {
            let matches = logLine.line.matches(CreationTagRegex)
            let tag = matches[0].value
            let value = matches[1].value
            tagChangeHandler.tagChange(game: game, rawTag: tag, id: game.currentEntityId,
                                       rawValue: value, isCreationTag: true)
            creationTag = true
        }
        if logLine.line.contains("End Spectator") {
            game.gameEnd()
        } else if logLine.line.contains("BLOCK_START") {
            game.blockStart()

            if logLine.line.match(BlockStartRegex) {
                let player = game.entities.map { $0.1 }
                    .firstWhere { $0.has(tag: .player_id) && $0[.player_id] == game.player.id }
                let opponent = game.entities.map { $0.1 }
                    .firstWhere { $0.has(tag: .player_id) && $0[.player_id] == game.opponent.id }

                let matches = logLine.line.matches(BlockStartRegex)
                let type = matches[0].value
                let actionStartingEntityId = Int(matches[1].value)!
                var actionStartingCardId: String? = matches[3].value

                if String.isNullOrEmpty(actionStartingCardId) {
                    if let actionEntity = game.entities[actionStartingEntityId] {
                        actionStartingCardId = actionEntity.cardId
                    }
                }

                if String.isNullOrEmpty(actionStartingCardId) {
                    return
                }

                if type == "TRIGGER" {
                    if let actionStartingCardId = actionStartingCardId {
                        switch actionStartingCardId {
                        case CardIds.Collectible.Rogue.TradePrinceGallywix:
                            if let lastCardPlayed = game.lastCardPlayed,
                                let entity = game.entities[lastCardPlayed] {
                                let cardId = entity.cardId
                                addKnownCardId(game: game, cardId: cardId)
                            }
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .TradePrinceGallywix_GallywixsCoinToken)
                        case CardIds.Collectible.Shaman.WhiteEyes:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Shaman
                                            .WhiteEyes_TheStormGuardianToken)
                        default: break
                        }
                    }
                } else {
                    if let actionStartingCardId = actionStartingCardId {
                        switch actionStartingCardId {
                        case CardIds.Collectible.Rogue.GangUp:
                            addKnownCardId(game: game,
                                           cardId: getTargetCardId(matches: matches),
                                           count: 3)
                        case CardIds.Collectible.Rogue.BeneathTheGrounds:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Rogue
                                            .BeneaththeGrounds_AmbushToken,
                                           count: 3)
                        case CardIds.Collectible.Warrior.IronJuggernaut:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Warrior
                                            .IronJuggernaut_BurrowingMineToken)
                        case CardIds.Collectible.Druid.Recycle,
                             CardIds.Collectible.Mage.ManicSoulcaster:
                            addKnownCardId(game: game,
                                           cardId: getTargetCardId(matches: matches))
                        case CardIds.Collectible.Mage.ForgottenTorch:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Mage
                                            .ForgottenTorch_RoaringTorchToken)
                        case CardIds.Collectible.Warlock.CurseOfRafaam:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Warlock
                                            .CurseofRafaam_CursedToken)
                        case CardIds.Collectible.Neutral.AncientShade:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .AncientShade_AncientCurseToken)
                        case CardIds.Collectible.Priest.ExcavatedEvil:
                            addKnownCardId(game: game,
                                           cardId: CardIds.Collectible.Priest.ExcavatedEvil)
                        case CardIds.Collectible.Neutral.EliseStarseeker:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .EliseStarseeker_MapToTheGoldenMonkeyToken)
                        case CardIds.NonCollectible.Neutral
                            .EliseStarseeker_MapToTheGoldenMonkeyToken:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Neutral
                                            .EliseStarseeker_GoldenMonkeyToken)
                        case CardIds.Collectible.Neutral.Doomcaller:
                            addKnownCardId(game: game,
                                           cardId: CardIds.NonCollectible.Neutral.Cthun)
                        case CardIds.Collectible.Druid.JadeIdol:
                            addKnownCardId(game: game,
                                           cardId: CardIds.Collectible.Druid.JadeIdol,
                                           count: 3)
                        default:
                            if let card = Cards.any(byId: actionStartingCardId) {
                                if (player != nil && player![.current_player] == 1
                                    && !game.playerUsedHeroPower)
                                    || (opponent != nil && opponent![.current_player] == 1
                                        && !game.opponentUsedHeroPower) {
                                    if card.type == .hero_power {
                                        if player != nil && player![.current_player] == 1 {
                                            game.playerHeroPower(cardId: actionStartingCardId,
                                                                 turn: game.turnNumber())
                                            game.playerUsedHeroPower = true
                                        } else if opponent != nil {
                                            game.opponentHeroPower(cardId: actionStartingCardId,
                                                                   turn: game.turnNumber())
                                            game.opponentUsedHeroPower = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if logLine.line.contains("BlockType=JOUST") {
                game.joustReveals = 2
            } else if game.gameTriggerCount == 0
                && logLine.line.contains("BLOCK_START BlockType=TRIGGER Entity=GameEntity") {
                game.gameTriggerCount += 1
            }
        } else if logLine.line.contains("CREATE_GAME") {
            tagChangeHandler.clearQueuedActions()
        } else if logLine.line.contains("BLOCK_END") {
            if game.gameTriggerCount < 10 && (game.gameEntity?.has(tag: .turn) ?? false) {
                game.gameTriggerCount += 10
                tagChangeHandler.invokeQueuedActions(game: game)
                game.setupDone = true
            }
            game.blockEnd()
        }

        if game.isInMenu { return }

        if !creationTag && game.determinedPlayers {
            tagChangeHandler.invokeQueuedActions(game: game)
        }
        if !creationTag {
            game.resetCurrentEntity()
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

    private func addKnownCardId(game: Game, cardId: String?, count: Int = 1) {
        guard let cardId = cardId else { return }

        if let blockId = game.currentBlock?.id {
            for _ in 0 ..< count {
                if game.knownCardIds[blockId] == nil {
                    game.knownCardIds[blockId] = []
                }

                game.knownCardIds[blockId]?.append(cardId)
            }
        }
    }

    private func reset() {
        tagChangeHandler.clearQueuedActions()
    }
}
