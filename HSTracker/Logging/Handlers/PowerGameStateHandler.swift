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
import RegExCategories

class PowerGameStateHandler {
    static let CardIdRegex = NSRegularExpression.rx("cardId=(\\w+)")
    static let GameEntityRegex = NSRegularExpression.rx("GameEntity EntityID=(\\d+)")
    static let PlayerEntityRegex = NSRegularExpression.rx("Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)")
    static let EntityNameRegex = NSRegularExpression.rx("TAG_CHANGE Entity=([\\w\\s]+\\w) tag=PLAYER_ID value=(\\d)")
    static let TagChangeRegex = NSRegularExpression.rx("TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)")
    static let CreationRegex = NSRegularExpression.rx("FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)")
    static let UpdatingEntityRegex = NSRegularExpression.rx("SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)")
    static let CreationTagRegex = NSRegularExpression.rx("tag=(\\w+) value=(\\w+)")
    static let ActionStartRegex = NSRegularExpression.rx(".*ACTION_START.*id=(\\d*).*cardId=(\\w*).*BlockType=(POWER|TRIGGER).*Target=(.+)")

    static let ParseEntityIDRegex = NSRegularExpression.rx("id=(\\d+)")
    static let ParseEntityZonePosRegex = NSRegularExpression.rx("zonePos=(\\d+)")
    static let ParseEntityPlayerRegex = NSRegularExpression.rx("player=(\\d+)")
    static let ParseEntityNameRegex = NSRegularExpression.rx("name=(\\d+)")
    static let ParseEntityZoneRegex = NSRegularExpression.rx("zone=(\\d+)")
    static let ParseEntityCardIDRegex = NSRegularExpression.rx("cardId=(\\d+)")
    static let ParseEntityTypeRegex = NSRegularExpression.rx("type=(\\d+)")

    static let tagChangeHandler = TagChangeHandler()
    static var currentEntity: Entity?

    static func handle(line: String) {
        let game = Game.instance
        var setup = false
        var creationTag = false

        // current game
        if line.isMatch(GameEntityRegex) {
            game.gameStart()

            let match = line.firstMatchWithDetails(GameEntityRegex)
            if let id = Int(match.groups[1].value) {
                // DDLogVerbose("GameEntityRegex id : \(id)")
                if game.entities[id] == nil {
                    let entity = Entity(id)
                    entity.name = "GameEntity"
                    game.entities[id] = entity
                }
                game.currentEntityId = id
            }
        }

        // players
        else if line.isMatch(PlayerEntityRegex) {
            let match = line.firstMatchWithDetails(PlayerEntityRegex)
            if let id = Int(match.groups[1].value) {
                // DDLogVerbose("PlayerEntityRegex id: \(id)")
                if game.entities[id] == nil {
                    game.entities[id] = Entity(id)
                }
                game.currentEntityId = id
            }
        }

        else if line.isMatch(TagChangeRegex) {
            var match = line.firstMatchWithDetails(TagChangeRegex)

            let rawEntity = match.groups[1].value.stringByReplacingOccurrencesOfString("UNKNOWN ENTITY ", withString: "")
            let tag: String = match.groups[2].value
            let value: String = match.groups[3].value

            if rawEntity.startsWith("[") && tagChangeHandler.isEntity(rawEntity) {
                let entity = tagChangeHandler.parseEntity(rawEntity)
                if let id = entity.id {
                    // DDLogVerbose("TagChangeRegex isEntity -> \(id)")
                    tagChangeHandler.tagChange(tag, id, value)
                }
            } else if rawEntity.isMatch(NSRegularExpression.rx("\\d+")) {
                if let id = Int(rawEntity) {
                    // DDLogVerbose("TagChangeRegex \\d+ -> \(id)")
                    tagChangeHandler.tagChange(tag, id, value)
                }
            } else {
                var entity: Entity? = Array(game.entities.values).filter({ $0.name == rawEntity }).first

                if let entity = entity {
                    tagChangeHandler.tagChange(tag, entity.id, value)
                }
                else {
                    let players = game.entities.filter { $0.1.hasTag(GameTag.PLAYER_ID) }.map { $0.1 }
                    let unnamedPlayers = players.filter { $0.name == nil || $0.name!.isEmpty }
                    let unknownHumanPlayer = players.firstWhere { $0.name == "UNKNOWN HUMAN PLAYER" }

                    if unnamedPlayers.count == 0 && unknownHumanPlayer != nil {
                        entity = unknownHumanPlayer
                        if let entity = entity {
                            setPlayerName(entity.getTag(GameTag.PLAYER_ID), rawEntity)
                        }
                    }

                    var tmpEntity: Entity? = game.tmpEntities.filter({ $0.name == rawEntity }).first
                    if tmpEntity == nil {
                        tmpEntity = Entity(game.tmpEntities.count + 1)
                        tmpEntity!.name = rawEntity
                        game.tmpEntities.append(tmpEntity!)
                    }

                    if let _tag: GameTag = GameTag(rawString: tag) {
                        let tagValue = tagChangeHandler.parseTag(_tag, value)

                        if unnamedPlayers.count == 1 {
                            entity = unnamedPlayers.first
                        }
                        else if unnamedPlayers.count == 2 && _tag == GameTag.CURRENT_PLAYER && tagValue == 0 {
                            entity = game.entities.map { $0.1 }.firstWhere { $0.hasTag(GameTag.CURRENT_PLAYER) }
                        }

                        if let entity = entity, tmpEntity = tmpEntity {
                            entity.name = tmpEntity.name
                            tmpEntity.tags.forEach({ (gameTag, value) -> () in
                                tagChangeHandler.tagChange(gameTag, tmpEntity.getTag(GameTag.ENTITY_ID), value)
                            })
                            setPlayerName(entity.getTag(GameTag.PLAYER_ID), tmpEntity.name!)
                            game.tmpEntities.remove(tmpEntity)
                            tagChangeHandler.tagChange(tag, entity.id, value)
                        }

                        if let tmpEntity = tmpEntity where game.tmpEntities.contains(tmpEntity) {
                            tmpEntity.setTag(_tag, tagValue)
                            if tmpEntity.hasTag(GameTag.ENTITY_ID) {
                                let id = tmpEntity.getTag(GameTag.ENTITY_ID)
                                if game.entities[id] != nil {
                                    game.entities[id]!.name = tmpEntity.name
                                    tmpEntity.tags.forEach({ (gameTag, value) -> () in
                                        tagChangeHandler.tagChange(gameTag, id, value)
                                    })
                                    game.tmpEntities.remove(tmpEntity)
                                }
                            }
                        }
                    }
                }
            }

            if line.isMatch(EntityNameRegex) {
                match = line.firstMatchWithDetails(EntityNameRegex)
                // DDLogVerbose(@"EntityNameRegex %@ -> %@", EntityNameRegex, match.groups);
                let name: String = match.groups[1].value
                let player = Int(match.groups[2].value)

                if player == game.player.id {
                    game.setPlayerName(name)
                }
                else if player == game.opponent.id {
                    game.setOpponentName(name)
                }
            }
        }

        else if line.isMatch(CreationRegex) {
            let match = line.firstMatchWithDetails(CreationRegex)
            let id = Int(match.groups[1].value)!
            let zone: String = match.groups[2].value
            var cardId: String = match.groups[3].value

            if game.entities[id] == nil {
                if cardId.isEmpty {
                    if game.knownCardIds[id] != nil {
                        DDLogVerbose("Found known cardId for entity \(id): \(cardId)")
                        cardId = game.knownCardIds[id]!
                        let index = game.knownCardIds.indexForKey(id)
                        if let index = index {
                            game.knownCardIds.removeAtIndex(index)
                        }
                    }
                }

                let entity = Entity(id)
                entity.cardId = cardId
                game.entities[id] = entity
            }
            game.currentEntityId = id
            game.currentEntityHasCardId = !cardId.isEmpty
            game.currentEntityZone = Zone(rawString: zone)
            setup = true
        }

        else if line.isMatch(UpdatingEntityRegex) {
            let match = line.firstMatchWithDetails(UpdatingEntityRegex)
            let rawEntity: String = match.groups[1].value
            let cardId: String = match.groups[2].value
            // DDLogVerbose("UpdatingEntityRegex \(rawEntity) -> \(cardId)")
            var entityId: Int?

            if rawEntity.startsWith("[") && tagChangeHandler.isEntity(rawEntity) {
                let entity = tagChangeHandler.parseEntity(rawEntity)
                if let _entityId = entity.id {
                    entityId = _entityId
                }
            } else if rawEntity.isMatch(NSRegularExpression.rx("\\d+")) {
                entityId = Int(rawEntity)
            }
            if let entityId = entityId {
                // DDLogVerbose("updating entity \(entityId) with card \(cardId)")
                game.currentEntityId = entityId
                if game.entities[entityId] == nil {
                    let entity = Entity(entityId)
                    game.entities[entityId] = entity
                }
                game.entities[entityId]!.cardId = cardId
            }

            if game.joustReveals > 0 {
                if let currentEntity = game.entities[entityId!] {
                    if currentEntity.isControllerBy(game.opponent.id!) {
                        game.opponentJoust(currentEntity, cardId, game.turnNumber())
                    } else if currentEntity.isControllerBy(game.player.id!) {
                        game.playerJoust(currentEntity, cardId, game.turnNumber())
                    }
                }
            }
        }

        else if line.isMatch(CreationTagRegex) && !line.containsString("HIDE_ENTITY") {
            let match = line.firstMatchWithDetails(CreationTagRegex)
            // DDLogVerbose("CreationTagRegex \(game.currentEntityId)")
            let tag: String = match.groups[1].value
            let value: String = match.groups[2].value
            tagChangeHandler.tagChange(tag, game.currentEntityId, value, true)
            setup = true
            creationTag = true
        }

        else if line.containsString("Begin Spectating") || line.containsString("Start Spectator") {
            game.currentGameMode = GameMode.Spectator
        }

        else if line.containsString("End Spectator") {
            game.currentGameMode = GameMode.Spectator
            game.gameEnd()
        }

        else if line.isMatch(ActionStartRegex) {
            let match = line.firstMatchWithDetails(ActionStartRegex)
            // DDLogVerbose(@"ActionStartRegex %@ -> %@", ActionStartRegex, match);
            let actionStartingEntityId = Int(match.groups[1].value)!
            var actionStartingCardId: String? = match.groups[2].value

            let player: Entity? = Array(game.entities.values).filter { $0.getTag(GameTag.PLAYER_ID) == game.player.id }.first
            let opponent: Entity? = Array(game.entities.values).filter { $0.getTag(GameTag.PLAYER_ID) == game.opponent.id }.first

            if let _actionStartingCardId = actionStartingCardId where _actionStartingCardId.isEmpty {
                if game.entities[actionStartingEntityId] != nil {
                    let actionEntity = game.entities[actionStartingEntityId]!
                    actionStartingCardId = actionEntity.cardId
                }
            }

            if actionStartingCardId == nil || actionStartingCardId!.isEmpty {
                return
            }

            let type: String = match.groups[3].value;
            if type == "TRIGGER" {
                if actionStartingCardId == CardIds.Collectible.Rogue.TradePrinceGallywix {
                    if let lastCardPlayed = game.lastCardPlayed {
                        if let entity = game.entities[lastCardPlayed] {
                            if let cardId = entity.cardId {
                                addKnownCardId(cardId)
                            }
                        }
                    }
                    addKnownCardId(CardIds.NonCollectible.Neutral.GallywixsCoinToken)
                }
            } else {
                if actionStartingCardId == CardIds.Collectible.Rogue.GangUp {
                    addTargetAsKnownCardId(match, 3)
                } else if actionStartingCardId == CardIds.Collectible.Rogue.BeneathTheGrounds {
                    addKnownCardId(CardIds.NonCollectible.Rogue.AmbushToken, 3)
                } else if actionStartingCardId == CardIds.Collectible.Warrior.IronJuggernaut {
                    addKnownCardId(CardIds.NonCollectible.Warrior.BurrowingMineToken)
                } else if actionStartingCardId == CardIds.Collectible.Druid.Recycle {
                    addTargetAsKnownCardId(match)
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
                    let card = Cards.byId(actionStartingCardId!)
                    if card != nil && card!.type == "hero power" {
                        if player != nil && player!.getTag(GameTag.CURRENT_PLAYER) == 1 {
                            game.playerUsedHeroPower = true
                            DDLogInfo("player use hero power")
                        } else if opponent != nil {
                            DDLogInfo("opponent use hero power")
                            game.opponentUsedHeroPower = true
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

        if game.isInMenu {
            return
        }
        if !creationTag && game.determinedPlayers {
            tagChangeHandler.invokeQueuedActions()
        }
        else if !game.determinedPlayers && game.setupDone
        {
            DDLogWarn("Could not determine players by checking for opponent hand.")
            let playerCard = game.entities.map { $0.1 }.firstWhere { $0.isInHand && !String.isNullOrEmpty($0.cardId) }

            if let playerCard = playerCard {
                tagChangeHandler.determinePlayers(playerCard.getTag(.CONTROLLER), false)
            }
            else {
                DDLogWarn("Could not determine players by checking for player hand either... waiting for draws...")
            }
        }
    }

    private static func addTargetAsKnownCardId(match: RxMatch, _ count: Int = 1) {
        let target: String = match.groups[4].value.trim()
        if !target.startsWith("[") || !tagChangeHandler.isEntity(target) {
            return
        }
        if !target.isMatch(CardIdRegex) {
            return
        }
        let cardIdMatch = target.firstMatchWithDetails(CardIdRegex)
        let targetCardId: String = cardIdMatch.groups[1].value.trim()
        let game = Game.instance
        for (var i = 0; i < count; i++) {
            let id = getMaxEntityId() + i + 1
            if game.knownCardIds[id] != nil {
                game.knownCardIds[id] = targetCardId
            }
        }
    }

    private static func addKnownCardId(cardId: String, _ count: Int = 1) {
        let game = Game.instance
        for i in 0 ..< count {
            let id = getMaxEntityId() + 1 + i;
            if game.knownCardIds[id] != nil {
                game.knownCardIds[id] = cardId
            }
        }
    }

    private static func getMaxEntityId() -> Int {
        let game = Game.instance
        return [game.entities.count, game.maxId].maxElement()!
    }

    private static func setPlayerName(playerId: Int, _ name: String) {
        let game = Game.instance
        if playerId == game.player.id {
            game.player.name = name
            DDLogInfo("Player name is \(name)")
        }
        else if playerId == game.opponent.id {
            game.opponent.name = name
            DDLogInfo("Opponent name is \(name)")
        }
    }
}
