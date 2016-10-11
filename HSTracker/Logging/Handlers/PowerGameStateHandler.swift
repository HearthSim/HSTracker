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

class PowerGameStateHandler {

    let BlockStartRegex = ".*BLOCK_START.*BlockType=(POWER|TRIGGER).*id=(\\d*)"
        + ".*cardId=(\\w*).*Target=(.+)"
    let CardIdRegex = "cardId=(\\w+)"
    let CreationRegex = "FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)"
    let CreationTagRegex = "tag=(\\w+) value=(\\w+)"
    let EntityNameRegex = "TAG_CHANGE Entity=([\\w\\s]+\\w) tag=PLAYER_ID value=(\\d)"
    let GameEntityRegex = "GameEntity EntityID=(\\d+)"
    let PlayerEntityRegex = "Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)"
    let PlayerNameRegex = "id=(\\d) Player=(.+) TaskList=(\\d)"
    let TagChangeRegex = "TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)"
    let UpdatingEntityRegex = "SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)"

    var tagChangeHandler = TagChangeHandler()
    var currentEntity: Entity?

    func handle(game: Game, logLine: LogLine) {
        var creationTag = false

        // current game
        if logLine.line.match(GameEntityRegex) {
            game.gameStart(logLine.time)

            if let match = logLine.line.matches(GameEntityRegex).first,
                id = Int(match.value) {
                //print("**** GameEntityRegex id:'\(id)'")
                if game.entities[id] == .None {
                    let entity = Entity(id: id)
                    entity.name = "GameEntity"
                    game.entities[id] = entity
                }
                game.setCurrentEntity(id)
                if game.determinedPlayers {
                    tagChangeHandler.invokeQueuedActions(game)
                }
                return
            }
        }

        // players
        else if logLine.line.match(PlayerEntityRegex) {
            if let match = logLine.line.matches(PlayerEntityRegex).first,
                id = Int(match.value) {
                if game.entities[id] == .None {
                    game.entities[id] = Entity(id: id)
                }
                /*if game.wasInProgress {
                    game.entities[id].name = game.getStoredPlayerName(id)
                }*/
                game.setCurrentEntity(id)
                if game.determinedPlayers {
                    tagChangeHandler.invokeQueuedActions(game)
                }
                return
            }
        } else if logLine.line.match(PlayerNameRegex) {
            let matches = logLine.line.matches(PlayerNameRegex)
            if let id = Int(matches[0].value) {
                let name = matches[1].value
                setPlayerName(game, playerId: id, name: name)
            }
        } else if logLine.line.match(TagChangeRegex) {
            let matches = logLine.line.matches(TagChangeRegex)
            let rawEntity = matches[0].value
                .stringByReplacingOccurrencesOfString("UNKNOWN ENTITY ", withString: "")
            let tag = matches[1].value
            let value = matches[2].value

            if rawEntity.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity) {
                let entity = tagChangeHandler.parseEntity(rawEntity)
                if let id = entity.id {
                    tagChangeHandler.tagChange(game, rawTag: tag, id: id, rawValue: value)
                }
            } else if let id = Int(rawEntity) {
                //print("**** TagChangeRegex \\d+ id:'\(id)', tag:'\(tag)', value:'\(value)'")
                tagChangeHandler.tagChange(game, rawTag: tag, id: id, rawValue: value)
            } else {
                var entity = game.entities.map { $0.1 }.firstWhere { $0.name == rawEntity }

                if let entity = entity {
                    tagChangeHandler.tagChange(game, rawTag: tag, id: entity.id, rawValue: value)
                } else {
                    let players = game.entities.map { $0.1 }
                        .filter { $0.hasTag(GameTag.PLAYER_ID) }.take(2)
                    let unnamedPlayers = players.filter { String.isNullOrEmpty($0.name) }
                    let unknownHumanPlayer = players
                        .firstWhere { $0.name == "UNKNOWN HUMAN PLAYER" }
                    
                    if unnamedPlayers.count == 0 && unknownHumanPlayer != .None {
                        entity = unknownHumanPlayer
                        if let entity = entity {
                            setPlayerName(game,
                                          playerId: entity.getTag(.PLAYER_ID),
                                          name: rawEntity)
                        }
                    }

                    var tmpEntity = game.tmpEntities.firstWhere { $0.name == rawEntity }
                    if tmpEntity == .None {
                        tmpEntity = Entity(id: game.tmpEntities.count + 1)
                        tmpEntity!.name = rawEntity
                        game.tmpEntities.append(tmpEntity!)
                    }

                    if let _tag: GameTag = GameTag(rawString: tag) {
                        let tagValue = tagChangeHandler.parseTag(_tag, rawValue: value)

                        if unnamedPlayers.count == 1 {
                            entity = unnamedPlayers.first
                        } else if unnamedPlayers.count == 2 &&
                            _tag == .CURRENT_PLAYER && tagValue == 0 {
                            entity = game.entities.map { $0.1 }
                                .firstWhere { $0.hasTag(.CURRENT_PLAYER) }
                        }

                        if let entity = entity, tmpEntity = tmpEntity {
                            entity.name = tmpEntity.name
                            tmpEntity.tags.forEach({ (gameTag, val) in
                                tagChangeHandler.tagChange(game,
                                    tag: gameTag, id: tmpEntity.id,
                                    value: val)
                            })
                            setPlayerName(game,
                                          playerId: entity.getTag(.PLAYER_ID),
                                          name: tmpEntity.name!)
                            game.tmpEntities.remove(tmpEntity)
                            tagChangeHandler.tagChange(game,
                                                       rawTag: tag,
                                                       id: entity.id,
                                                       rawValue: value)
                        }

                        if let tmpEntity = tmpEntity where game.tmpEntities.contains(tmpEntity) {
                            tmpEntity.setTag(_tag, value: tagValue)
                            if tmpEntity.hasTag(.ENTITY_ID) {
                                let id = tmpEntity.getTag(.ENTITY_ID)
                                if game.entities[id] != .None {
                                    game.entities[id]!.name = tmpEntity.name
                                    tmpEntity.tags.forEach({ (gameTag, val) -> () in
                                        tagChangeHandler.tagChange(game,
                                            tag: gameTag,
                                            id: id,
                                            value: val)
                                    })
                                    game.tmpEntities.remove(tmpEntity)
                                }
                            }
                        }
                    }
                }
            }

            if logLine.line.match(EntityNameRegex) {
                let matches = logLine.line.matches(EntityNameRegex)
                let name = matches[0].value
                if let player = Int(matches[1].value) {
                    setPlayerName(game, playerId: player, name: name)
                }
            }
        } else if logLine.line.match(CreationRegex) {
            let matches = logLine.line.matches(CreationRegex)
            let id = Int(matches[0].value)!
            let zone = matches[1].value
            var cardId = matches[2].value

            if game.entities[id] == .None {
                if String.isNullOrEmpty(cardId) {
                    if game.knownCardIds[id] != .None {
                        cardId = game.knownCardIds[id]!
                        Log.verbose?.message("Found known cardId '\(cardId)' for entity \(id)")
                        game.knownCardIds[id] = nil
                    }
                }

                let entity = Entity(id: id)
                game.entities[id] = entity
            }

            if !String.isNullOrEmpty(cardId) {
                game.entities[id]!.cardId = cardId
            }

            game.setCurrentEntity(id)
            if game.determinedPlayers {
                tagChangeHandler.invokeQueuedActions(game)
            }
            game.currentEntityHasCardId = !String.isNullOrEmpty(cardId)
            game.currentEntityZone = Zone(rawString: zone)!
            return
        } else if logLine.line.match(UpdatingEntityRegex) {
            let matches = logLine.line.matches(UpdatingEntityRegex)
            let rawEntity = matches[0].value
            let cardId = matches[1].value
            var entityId: Int?

            if rawEntity.hasPrefix("[") && tagChangeHandler.isEntity(rawEntity) {
                let entity = tagChangeHandler.parseEntity(rawEntity)
                if let _entityId = entity.id {
                    entityId = _entityId
                }
            } else if let _entityId = Int(rawEntity) {
                entityId = _entityId
            }

            if let entityId = entityId {
                if game.entities[entityId] == .None {
                    let entity = Entity(id: entityId)
                    game.entities[entityId] = entity
                }
                game.entities[entityId]!.cardId = cardId
                game.setCurrentEntity(entityId)
                if game.determinedPlayers {
                    tagChangeHandler.invokeQueuedActions(game)
                }
            }

            if game.joustReveals > 0 {
                if let currentEntity = game.entities[entityId!] {
                    if currentEntity.isControlledBy(game.opponent.id) {
                        game.opponentJoust(currentEntity, cardId: cardId, turn: game.turnNumber())
                    } else if currentEntity.isControlledBy(game.player.id) {
                        game.playerJoust(currentEntity, cardId: cardId, turn: game.turnNumber())
                    }
                }
            }
            return
        } else if logLine.line.match(CreationTagRegex)
            && !logLine.line.contains("HIDE_ENTITY") {
            let matches = logLine.line.matches(CreationTagRegex)
            let tag = matches[0].value
            let value = matches[1].value
            tagChangeHandler.tagChange(game, rawTag: tag, id: game.currentEntityId,
                                       rawValue: value, isCreationTag: true)
            creationTag = true
        } else if logLine.line.contains("Begin Spectating")
            || logLine.line.contains("Start Spectator")
            && game.isInMenu {
            game.currentGameMode = GameMode.Spectator
        } else if logLine.line.contains("End Spectator") {
            game.currentGameMode = GameMode.Spectator
            game.gameEnd()
        } else if logLine.line.match(BlockStartRegex) {
            let matches = logLine.line.matches(BlockStartRegex)
            let type = matches[0].value
            let actionStartingEntityId = Int(matches[1].value)!
            var actionStartingCardId: String? = matches[2].value

            let player = game.entities.map { $0.1 }
                .firstWhere { $0.hasTag(.PLAYER_ID) && $0.getTag(.PLAYER_ID) == game.player.id }
            let opponent = game.entities.map { $0.1 }
                .firstWhere { $0.hasTag(.PLAYER_ID) && $0.getTag(.PLAYER_ID) == game.opponent.id }

            if String.isNullOrEmpty(actionStartingCardId) {
                if let actionEntity = game.entities[actionStartingEntityId] {
                    actionStartingCardId = actionEntity.cardId
                }
            }

            if String.isNullOrEmpty(actionStartingCardId) {
                return
            }

            // swiftlint:disable line_length
            if type == "TRIGGER" {
                if actionStartingCardId == CardIds.Collectible.Rogue.TradePrinceGallywix {
                    if let lastCardPlayed = game.lastCardPlayed,
                        entity = game.entities[lastCardPlayed] {
                        let cardId = entity.cardId
                        addKnownCardId(game, cardId: cardId)
                    }
                    addKnownCardId(game,
                                   cardId: CardIds.NonCollectible.Neutral.TradePrinceGallywix_GallywixsCoinToken)
                }
            } else {
                if let actionStartingCardId = actionStartingCardId {
                    switch actionStartingCardId {
                    case CardIds.Collectible.Rogue.GangUp:
                        addTargetAsKnownCardId(game, matches: matches, count: 3)
                    case CardIds.Collectible.Rogue.BeneathTheGrounds:
                        addKnownCardId(game,
                                       cardId: CardIds.NonCollectible.Rogue.BeneaththeGrounds_AmbushToken,
                                       count: 3)
                    case CardIds.Collectible.Warrior.IronJuggernaut:
                        addKnownCardId(game,
                                       cardId: CardIds.NonCollectible.Warrior.IronJuggernaut_BurrowingMineToken)
                    case CardIds.Collectible.Druid.Recycle:
                        addTargetAsKnownCardId(game, matches: matches)
                    case CardIds.Collectible.Mage.ForgottenTorch:
                        addKnownCardId(game,
                                       cardId: CardIds.NonCollectible.Mage.ForgottenTorch_RoaringTorchToken)
                    case CardIds.Collectible.Warlock.CurseOfRafaam:
                        addKnownCardId(game,
                                       cardId: CardIds.NonCollectible.Warlock.CurseofRafaam_CursedToken)
                    case CardIds.Collectible.Neutral.AncientShade:
                        addKnownCardId(game,
                                       cardId: CardIds.NonCollectible.Neutral.AncientShade_AncientCurseToken)
                    case CardIds.Collectible.Priest.ExcavatedEvil:
                        addKnownCardId(game,
                                       cardId: CardIds.Collectible.Priest.ExcavatedEvil)
                    case CardIds.Collectible.Neutral.EliseStarseeker:
                        addKnownCardId(game,
                                       cardId: CardIds.NonCollectible.Neutral.EliseStarseeker_MapToTheGoldenMonkeyToken)
                    case CardIds.NonCollectible.Neutral.EliseStarseeker_MapToTheGoldenMonkeyToken:
                        addKnownCardId(game,
                                       cardId: CardIds.NonCollectible.Neutral.EliseStarseeker_GoldenMonkeyToken)
                    case CardIds.Collectible.Neutral.Doomcaller:
                        addKnownCardId(game, cardId: CardIds.NonCollectible.Neutral.Cthun)
                    default:
                        if let card = Cards.any(byId: actionStartingCardId) {
                            if (player != nil && player!.getTag(.CURRENT_PLAYER) == 1 && !game.playerUsedHeroPower)
                                || (opponent != nil && opponent!.getTag(.CURRENT_PLAYER) == 1
                                    && !game.opponentUsedHeroPower) {
                                if card.type == .HERO_POWER {
                                    if player != nil && player!.getTag(GameTag.CURRENT_PLAYER) == 1 {
                                        game.playerHeroPower(actionStartingCardId, turn: game.turnNumber())
                                        game.playerUsedHeroPower = true
                                    } else if opponent != nil {
                                        game.opponentHeroPower(actionStartingCardId, turn: game.turnNumber())
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
        } else if logLine.line.contains("CREATE_GAME") {
            tagChangeHandler.clearQueuedActions()
        } else if game.gameTriggerCount == 0 && logLine.line.contains("BLOCK_START BlockType=TRIGGER Entity=GameEntity") {
            game.gameTriggerCount += 1
        } else if game.gameTriggerCount < 10 && logLine.line.contains("BLOCK_END") {
            if let entity = game.gameEntity where entity.hasTag(.TURN) {
                game.gameTriggerCount += 10
                tagChangeHandler.invokeQueuedActions(game)
                game.setupDone = true
            }
        }

        if game.isInMenu { return }

        if !creationTag && game.determinedPlayers {
            tagChangeHandler.invokeQueuedActions(game)
        }
        if !creationTag {
            game.resetCurrentEntity()
        }
        if !game.determinedPlayers && game.setupDone {
            if let playerCard = game.entities.map({ $0.1 })
                .firstWhere({ $0.isInHand
                    && !String.isNullOrEmpty($0.cardId) && $0.hasTag(.CONTROLLER) }) {
                    tagChangeHandler.determinePlayers(game,
                                                      playerId: playerCard.getTag(.CONTROLLER),
                                                      isOpponentId: false)
            }
        }
        // swiftlint:enable line_length
    }

    private func addTargetAsKnownCardId(game: Game, matches: [Match], count: Int = 1) {
        let target: String = matches[3].value.trim()
        guard target.hasPrefix("[") && tagChangeHandler.isEntity(target) else { return }
        guard target.match(CardIdRegex) else { return }

        let cardIdMatch = target.matches(CardIdRegex)
        let targetCardId: String = cardIdMatch[0].value.trim()
        //print("**** CardIdRegex -> targetCardId:'\(targetCardId)'")
        for i in 0 ..< count {
            let id = getMaxEntityId() + i + 1
            if game.knownCardIds[id] != nil {
                game.knownCardIds[id] = targetCardId
            }
        }
    }

    private func addKnownCardId(game: Game, cardId: String, count: Int = 1) {
        for i in 0 ..< count {
            let id = getMaxEntityId() + 1 + i
            if game.knownCardIds[id] != nil {
                game.knownCardIds[id] = cardId
            }
        }
    }

    private func getMaxEntityId() -> Int {
        let game = Game.instance
        return [game.entities.count, game.maxId].maxElement()!
    }

    private func reset() {
        tagChangeHandler.clearQueuedActions()
    }

    private func setPlayerName(game: Game, playerId: Int, name: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if game.player.id == -1 && game.opponent.id == -1 {
                while game.player.id == -1 && game.opponent.id == -1 {
                    NSThread.sleepForTimeInterval(0.1)
                }
            }
            Log.verbose?.message("Trying player name \(name) for \(playerId) "
                + "(player: \(game.player.id) / opp \(game.opponent.id))")
            if playerId == game.player.id {
                game.player.name = name
                if let player = game.entities.map({ $0.1 }).firstWhere({ $0.isPlayer }) {
                    player.name = name
                }
                
                Log.info?.message("Player name is \(name)")
            } else if playerId == game.opponent.id {
                game.opponent.name = name
                if let opponent = game.entities.map({ $0.1 })
                    .firstWhere({ $0.hasTag(.PLAYER_ID) && !$0.isPlayer }) {
                    opponent.name = name
                }
                Log.info?.message("Opponent name is \(name)")
            }
        }
    }
}
