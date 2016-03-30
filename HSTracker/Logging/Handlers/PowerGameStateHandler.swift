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
    
    let ActionStartRegex = ".*ACTION_START.*BlockType=(POWER|TRIGGER).*id=(\\d*).*cardId=(\\w*).*Target=(.+)"
    let CardIdRegex = "cardId=(\\w+)"
    let CreationRegex = "FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)"
    let CreationTagRegex = "tag=(\\w+) value=(\\w+)"
    let EntityNameRegex = "TAG_CHANGE Entity=([\\w\\s]+\\w) tag=PLAYER_ID value=(\\d)"
    let GameEntityRegex = "GameEntity EntityID=(\\d+)"
    let PlayerEntityRegex = "Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)"
    let TagChangeRegex = "TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)"
    let UpdatingEntityRegex = "SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)"

    var tagChangeHandler = TagChangeHandler()
    var currentEntity: Entity?

    func handle(game: Game, _ line: String) {
        var setup = false
        var creationTag = false

        // current game
        if line.match(GameEntityRegex) {
            game.gameStart()

            if let match = line.matches(GameEntityRegex).first, id = Int(match.value) {
                //print("**** GameEntityRegex id:'\(id)'")
                if game.entities[id] == .None {
                    let entity = Entity(id)
                    entity.name = "GameEntity"
                    game.entities[id] = entity
                }
                game.currentEntityId = id
                setup = true
            }
        }

        // players
        else if line.match(PlayerEntityRegex) {
            if let match = line.matches(PlayerEntityRegex).first, id = Int(match.value) {
                //print("**** PlayerEntityRegex id:'\(id)'")
                if game.entities[id] == .None {
                    game.entities[id] = Entity(id)
                }
                game.currentEntityId = id
                setup = true
                /*if game.wasInProgress {
                    game.entities[id].name = game.getStoredPlayerName(id)
                }*/
            }
        }

        else if line.match(TagChangeRegex) {
            let matches = line.matches(TagChangeRegex)
            let rawEntity = matches[0].value.stringByReplacingOccurrencesOfString("UNKNOWN ENTITY ", withString: "")
            let tag = matches[1].value
            let value = matches[2].value
            
            //print("**** TagChangeRegex rawEntity:'\(rawEntity)', tag:'\(tag)', value:'\(value)'")

            if rawEntity.startsWith("[") && tagChangeHandler.isEntity(rawEntity) {
                let entity = tagChangeHandler.parseEntity(rawEntity)
                if let id = entity.id {
                    //print("**** TagChangeRegex isEntity id:'\(id)', tag:'\(tag)', value:'\(value)'")
                    tagChangeHandler.tagChange(game, tag, id, value)
                }
            }
            else if let id = Int(rawEntity) {
                //print("**** TagChangeRegex \\d+ id:'\(id)', tag:'\(tag)', value:'\(value)'")
                tagChangeHandler.tagChange(game, tag, id, value)
            }
            else {
                var entity = game.entities.map { $0.1 }.firstWhere { $0.name == rawEntity }

                if let entity = entity {
                    tagChangeHandler.tagChange(game, tag, entity.id, value)
                }
                else {
                    let players = game.entities.map { $0.1 }.filter { $0.hasTag(GameTag.PLAYER_ID) }.take(2)
                    let unnamedPlayers = players.filter { String.isNullOrEmpty($0.name) }
                    let unknownHumanPlayer = players.firstWhere { $0.name == "UNKNOWN HUMAN PLAYER" }

                    if unnamedPlayers.count == 0 && unknownHumanPlayer != .None {
                        entity = unknownHumanPlayer
                        if let entity = entity {
                            setPlayerName(game, entity.getTag(.PLAYER_ID), rawEntity)
                        }
                    }

                    var tmpEntity = game.tmpEntities.firstWhere { $0.name == rawEntity }
                    if tmpEntity == .None {
                        tmpEntity = Entity(game.tmpEntities.count + 1)
                        tmpEntity!.name = rawEntity
                        game.tmpEntities.append(tmpEntity!)
                    }

                    if let _tag: GameTag = GameTag(rawString: tag) {
                        let tagValue = tagChangeHandler.parseTag(_tag, value)

                        if unnamedPlayers.count == 1 {
                            entity = unnamedPlayers.first
                        }
                        else if unnamedPlayers.count == 2 && _tag == .CURRENT_PLAYER && tagValue == 0 {
                            entity = game.entities.map { $0.1 }.firstWhere { $0.hasTag(.CURRENT_PLAYER) }
                        }

                        if let entity = entity, tmpEntity = tmpEntity {
                            entity.name = tmpEntity.name
                            tmpEntity.tags.forEach({ (gameTag, val) in
                                tagChangeHandler.tagChange(game, gameTag, tmpEntity.getTag(.ENTITY_ID), val)
                            })
                            setPlayerName(game, entity.getTag(.PLAYER_ID), tmpEntity.name!)
                            game.tmpEntities.remove(tmpEntity)
                            tagChangeHandler.tagChange(game, tag, entity.id, value)
                        }

                        if let tmpEntity = tmpEntity where game.tmpEntities.contains(tmpEntity) {
                            tmpEntity.setTag(_tag, tagValue)
                            if tmpEntity.hasTag(.ENTITY_ID) {
                                let id = tmpEntity.getTag(.ENTITY_ID)
                                if game.entities[id] != .None {
                                    game.entities[id]!.name = tmpEntity.name
                                    tmpEntity.tags.forEach({ (gameTag, val) -> () in
                                        tagChangeHandler.tagChange(game, gameTag, id, val)
                                    })
                                    game.tmpEntities.remove(tmpEntity)
                                }
                            }
                        }
                    }
                }
            }

            if line.match(EntityNameRegex) {
                let matches = line.matches(EntityNameRegex)
                let name = matches[0].value
                if let player = Int(matches[1].value) {
                    //print("**** EntityNameRegex name:'\(name)', player:'\(player)'")
                    setPlayerName(game, player, name)
                }
            }
        }

        else if line.match(CreationRegex) {
            let matches = line.matches(CreationRegex)
            let id = Int(matches[0].value)!
            let zone = matches[1].value
            var cardId = matches[2].value
            
            //print("**** CreationRegex id:'\(id)', zone:'\(zone)', cardId:'\(cardId)'")
            if game.entities[id] == .None {
                if String.isNullOrEmpty(cardId) {
                    if game.knownCardIds[id] != .None {
                        cardId = game.knownCardIds[id]!
                        Log.verbose?.message("Found known cardId '\(cardId)' for entity \(id)")
                        game.knownCardIds[id] = nil
                    }
                }

                let entity = Entity(id)
                game.entities[id] = entity
            }

            if !String.isNullOrEmpty(cardId) {
                game.entities[id]!.cardId = cardId
            }

            game.currentEntityId = id
            game.currentEntityHasCardId = !String.isNullOrEmpty(cardId)
            game.currentEntityZone = Zone(rawString: zone)
            setup = true
        }

        else if line.match(UpdatingEntityRegex) {
            let matches = line.matches(UpdatingEntityRegex)
            let rawEntity = matches[0].value
            let cardId = matches[1].value
            //print("**** UpdatingEntityRegex rawEntity:'\(rawEntity)', cardId:'\(cardId)'")
            var entityId: Int?

            if rawEntity.startsWith("[") && tagChangeHandler.isEntity(rawEntity) {
                let entity = tagChangeHandler.parseEntity(rawEntity)
                if let _entityId = entity.id {
                    entityId = _entityId
                    //print("**** UpdatingEntityRegex isEntity entityId:'\(entityId)'")
                }
            }
            else if let _entityId = Int(rawEntity) {
                entityId = _entityId
                //print("**** UpdatingEntityRegex \\d -> entityId:'\(entityId)'")
            }

            if let entityId = entityId {
                //print("**** Updating entity '\(entityId)' with card '\(cardId)'")
                game.currentEntityId = entityId
                if game.entities[entityId] == .None {
                    let entity = Entity(entityId)
                    game.entities[entityId] = entity
                }
                game.entities[entityId]!.cardId = cardId
            }

            if game.joustReveals > 0 {
                if let currentEntity = game.entities[entityId!] {
                    if currentEntity.isControlledBy(game.opponent.id!) {
                        game.opponentJoust(currentEntity, cardId, game.turnNumber())
                    }
                    else if currentEntity.isControlledBy(game.player.id!) {
                        game.playerJoust(currentEntity, cardId, game.turnNumber())
                    }
                }
            }
        }

        else if line.match(CreationTagRegex) && !line.contains("HIDE_ENTITY") {
            let matches = line.matches(CreationTagRegex)
            let tag = matches[0].value
            let value = matches[1].value
            //print("**** CreationTagRegex currentEntity:'\(game.currentEntityId)', tag:'\(tag)', value:'\(value)'")
            tagChangeHandler.tagChange(game, tag, game.currentEntityId, value, true)
            setup = true
            creationTag = true
        }

        else if line.contains("Begin Spectating") || line.contains("Start Spectator") && game.isInMenu {
            game.currentGameMode = GameMode.Spectator
        }

        else if line.contains("End Spectator") {
            game.currentGameMode = GameMode.Spectator
            game.gameEnd()
        }

        else if line.match(ActionStartRegex) {
            let matches = line.matches(ActionStartRegex)
            let type = matches[0].value
            let actionStartingEntityId = Int(matches[1].value)!
            var actionStartingCardId: String? = matches[2].value
            //let target = matches[3].value
            
            //print("**** ActionStartRegex type:'\(type)', actionStartingEntityId:'\(actionStartingEntityId)', actionStartingCardId:'\(actionStartingCardId)'")

            let player = game.entities.map { $0.1 }.firstWhere { $0.hasTag(.PLAYER_ID) && $0.getTag(.PLAYER_ID) == game.player.id }
            let opponent = game.entities.map { $0.1 }.firstWhere { $0.hasTag(.PLAYER_ID) && $0.getTag(.PLAYER_ID) == game.opponent.id }

            if String.isNullOrEmpty(actionStartingCardId) {
                if let actionEntity = game.entities[actionStartingEntityId] {
                    actionStartingCardId = actionEntity.cardId
                }
            }

            if String.isNullOrEmpty(actionStartingCardId) {
                return
            }

            if type == "TRIGGER" {
                if actionStartingCardId == CardIds.Collectible.Rogue.TradePrinceGallywix {
                    if let lastCardPlayed = game.lastCardPlayed,
                        let entity = game.entities[lastCardPlayed],
                        let cardId = entity.cardId {
                            addKnownCardId(cardId)
                    }
                    addKnownCardId(CardIds.NonCollectible.Neutral.GallywixsCoinToken)
                }
            } else {
                if actionStartingCardId == CardIds.Collectible.Rogue.GangUp {
                    addTargetAsKnownCardId(matches, 3)
                } else if actionStartingCardId == CardIds.Collectible.Rogue.BeneathTheGrounds {
                    addKnownCardId(CardIds.NonCollectible.Rogue.AmbushToken, 3)
                } else if actionStartingCardId == CardIds.Collectible.Warrior.IronJuggernaut {
                    addKnownCardId(CardIds.NonCollectible.Warrior.BurrowingMineToken)
                } else if actionStartingCardId == CardIds.Collectible.Druid.Recycle {
                    addTargetAsKnownCardId(matches)
                } else if actionStartingCardId == CardIds.Collectible.Mage.ForgottenTorch {
                    addKnownCardId(CardIds.NonCollectible.Mage.RoaringTorchToken)
                } else if actionStartingCardId == CardIds.Collectible.Warlock.CurseOfRafaam {
                    addKnownCardId(CardIds.NonCollectible.Warlock.CursedToken)
                } else if actionStartingCardId == CardIds.Collectible.Neutral.AncientShade {
                    addKnownCardId(CardIds.NonCollectible.Neutral.AncientCurseToken)
                } else if actionStartingCardId == CardIds.Collectible.Priest.ExcavatedEvil {
                    addKnownCardId(CardIds.Collectible.Priest.ExcavatedEvil)
                } else if actionStartingCardId == CardIds.Collectible.Neutral.EliseStarseeker {
                    addKnownCardId(CardIds.NonCollectible.Neutral.MapToTheGoldenMonkeyToken)
                } else if actionStartingCardId == CardIds.NonCollectible.Neutral.MapToTheGoldenMonkeyToken {
                    addKnownCardId(CardIds.NonCollectible.Neutral.GoldenMonkeyToken)
                } else {
                    if let actionStartingCardId = actionStartingCardId,
                        let card = Cards.anyById(actionStartingCardId) {
                            if (player != nil && player!.getTag(.CURRENT_PLAYER) == 1 && !game.playerUsedHeroPower) || (opponent != nil && opponent!.getTag(.CURRENT_PLAYER) == 1 && !game.opponentUsedHeroPower) {
                                if card.type == "hero power" {
                                    if player != nil && player!.getTag(GameTag.CURRENT_PLAYER) == 1 {
                                        game.playerHeroPower(actionStartingCardId, game.turnNumber())
                                        game.playerUsedHeroPower = true
                                    } else if opponent != nil {
                                        game.opponentHeroPower(actionStartingCardId, game.turnNumber())
                                        game.opponentUsedHeroPower = true
                                    }
                                }
                            }
                    }
                }
            }
        }

        else if line.contains("BlockType=JOUST") {
            game.joustReveals = 2
        }
        else if line.contains("CREATE_GAME") {
            setup = true
            tagChangeHandler.clearQueuedActions()
        }

        if !setup {
            game.setupDone = true
        }

        guard !game.isInMenu else { return }

        if !creationTag && game.determinedPlayers {
            tagChangeHandler.invokeQueuedActions()
        }
        else if !game.determinedPlayers && game.setupDone
        {
            if let playerCard = game.entities.map({ $0.1 })
                .firstWhere({ $0.isInHand && !String.isNullOrEmpty($0.cardId) && $0.hasTag(.CONTROLLER) }) {
                    tagChangeHandler.determinePlayers(game, playerCard.getTag(.CONTROLLER), false)
            }
        }
    }

    private func addTargetAsKnownCardId(matches: [Match], _ count: Int = 1) {
        let target: String = matches[3].value.trim()
        guard target.startsWith("[") && tagChangeHandler.isEntity(target) else { return }
        guard target.match(CardIdRegex) else { return }
        
        let cardIdMatch = target.matches(CardIdRegex)
        let targetCardId: String = cardIdMatch[0].value.trim()
        //print("**** CardIdRegex -> targetCardId:'\(targetCardId)'")
        let game = Game.instance
        for i in 0 ..< count {
            let id = getMaxEntityId() + i + 1
            if game.knownCardIds[id] != nil {
                game.knownCardIds[id] = targetCardId
            }
        }
    }

    private func addKnownCardId(cardId: String, _ count: Int = 1) {
        //print("**** Add know card -> cardId:'\(cardId)'")
        let game = Game.instance
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

    private func setPlayerName(game: Game, _ playerId: Int, _ name: String) {
        if playerId == game.player.id {
            game.player.name = name
            Log.info?.message("Player name is \(name)")
            //print("player name : '\(name)'")
        }
        else if playerId == game.opponent.id {
            game.opponent.name = name
            Log.info?.message("Opponent name is \(name)")
            //print("opponent name : '\(name)'")
        }
    }
}
