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

class PowerGameStateHandler {
    static let GameEntityRegex = "GameEntity EntityID=(\\d+)"
    static let PlayerEntityRegex = "Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)"
    static let EntityNameRegex = "TAG_CHANGE Entity=([\\w\\s]+\\w) tag=PLAYER_ID value=(\\d)"
    static let TagChangeRegex = "TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)"
    static let CreationRegex = "FULL_ENTITY - Creating ID=(\\d+) CardID=(\\w*)"
    static let UpdatingEntityRegex = "SHOW_ENTITY - Updating Entity=(.+) CardID=(\\w*)"
    static let CreationTagRegex = "tag=(\\w+) value=(\\w+)"
    static let ActionStartRegex = ".*ACTION_START.*id=(\\d*).*cardId=(\\w*).*BlockType=(POWER|TRIGGER).*Target=(.+)"

    static let tagChangeHandler = TagChangeHandler()
    static var currentEntityId = Int.min
    static var currentEntity: Entity?

    static func handle(line: String) {
        var entity: Entity?

        let game = Game.instance

        // current game
        if line.isMatch(NSRegularExpression.rx(GameEntityRegex)) {
            game.gameStart()

            let match = line.firstMatchWithDetails(NSRegularExpression.rx(GameEntityRegex))
            //DDLogVerbose(@"GameEntityRegex %@ -> %@", GameEntityRegex, match.groups[1]);
            let id = Int(match.groups[1].value!)!
            if game.entities[id] == nil {
                game.entities[id] = Entity(id)
            }
            currentEntityId = id
        }

                // players
        else if line.isMatch(NSRegularExpression.rx(PlayerEntityRegex)) {
            let match = line.firstMatchWithDetails(NSRegularExpression.rx(PlayerEntityRegex))
            //DDLogVerbose(@"PlayerEntityRegex %@ -> %@", PlayerEntityRegex, match.groups[1]);
            let id = Int(match.groups[1].value!)!

            if game.entities[id] == nil {
                game.entities[id] = Entity(id)
            }
            currentEntityId = id
        } else if line.isMatch(NSRegularExpression.rx(TagChangeRegex)) {
            var match = line.firstMatchWithDetails(NSRegularExpression.rx(TagChangeRegex))
            //DDLogVerbose("TagChangeRegex \(TagChangeRegex) -> \(match.groups)")
            let rawEntity = match.groups[1].value.stringByReplacingOccurrencesOfString("UNKNOWN ENTITY ", withString: "")
            let tag: String = match.groups[2].value
            let value: String = match.groups[3].value

            if rawEntity.isMatch(NSRegularExpression.rx("^\\[")) && tagChangeHandler.isEntity(rawEntity) {
                let (id, _, _, _, _, _, _) = tagChangeHandler.parseEntity(rawEntity)
                tagChangeHandler.tagChange(tag, id: id!, rawValue: value)
            } else if rawEntity.isMatch(NSRegularExpression.rx("\\d+")) {
                let id = Int(rawEntity)
                tagChangeHandler.tagChange(tag, id: id!, rawValue: value)
            } else {
                var sEntity: Entity?
                for (_, ent) in game.entities {
                    if ent.name == rawEntity {
                        sEntity = ent
                        break
                    }
                }

                if sEntity == nil {
                    var tmpEntity: Entity?
                    for (_, ent) in game.entities {
                        if ent.name == "UNKNOWN HUMAN PLAYER" {
                            tmpEntity = ent
                            tmpEntity!.name = rawEntity
                        }
                    }

                    if tmpEntity == nil {
                        for (_, ent) in game.entities {
                            if ent.name == rawEntity {
                                tmpEntity = ent
                                break
                            }
                        }
                    }

                    if tmpEntity == nil {
                        tmpEntity = Entity(game.tmpEntities.count + 1)
                        tmpEntity!.name = rawEntity
                        game.tmpEntities.append(tmpEntity!)
                    }

                    let _tag: GameTag = GameTag(rawString: tag)!
                    let tagValue = tagChangeHandler.parseTag(_tag, value)
                    tmpEntity!.setTag(_tag, tagValue)
                    if tmpEntity!.hasTag(GameTag.ENTITY_ID) {
                        let id = tmpEntity!.getTag(GameTag.ENTITY_ID)
                        if (game.entities[id] != nil) {
                            game.entities[id]!.name = tmpEntity!.name
                            for (tag, value) in tmpEntity!.tags {
                                game.entities[id]!.setTag(tag, value)
                            }
                            game.tmpEntities = game.tmpEntities.filter {
                                $0 != tmpEntity!
                            }
                        }
                    }
                } else {
                    tagChangeHandler.tagChange(tag, id: sEntity!.id, rawValue: value)
                }
            }

            if line.isMatch(NSRegularExpression.rx(EntityNameRegex)) {
                match = line.firstMatchWithDetails(NSRegularExpression.rx(EntityNameRegex))
                //DDLogVerbose(@"EntityNameRegex %@ -> %@", EntityNameRegex, match.groups);
                let name: String = match.groups[1].value
                let player = Int(match.groups[2].value)

                for (_, ent) in game.entities {
                    if ent.getTag(GameTag.PLAYER_ID) == player {
                        entity = ent
                        break
                    }
                }

                if entity == nil {
                    return
                }

                if entity!.isPlayer {
                    game.setPlayerName(name)
                } else {
                    game.setOpponentName(name)
                }
            }
        } else if line.isMatch(NSRegularExpression.rx(CreationRegex)) {
            let match = line.firstMatchWithDetails(NSRegularExpression.rx(CreationRegex))
            let id = Int(match.groups[1].value)!
            let cardId: String = match.groups[2].value
            //DDLogVerbose("CreationRegex id \(id), cardId \(cardId) -> \(cardId.isEmpty)")

            if game.entities[id] == nil {
                entity = Entity(id)
                entity!.cardId = cardId
                game.entities[id] = entity
            }
            currentEntityId = id
            tagChangeHandler.currentEntityHasCardId = !cardId.isEmpty
        } else if line.isMatch(NSRegularExpression.rx(UpdatingEntityRegex)) {
            let match = line.firstMatchWithDetails(NSRegularExpression.rx(UpdatingEntityRegex))
            //DDLogVerbose(@"UpdatingEntityRegex %@ -> %@", UpdatingEntityRegex, match);
            let tmpEntity: String = match.groups[1].value
            let cardId: String = match.groups[2].value

            var entityId: Int?;
            if tmpEntity.isMatch(NSRegularExpression.rx("^\\[")) && tagChangeHandler.isEntity(tmpEntity) {
                let (_entityId, _, _, _, _, _, _) = tagChangeHandler.parseEntity(tmpEntity)
                if let __entityId = _entityId {
                    entityId = __entityId
                }
            } else if tmpEntity.isMatch(NSRegularExpression.rx("\\d+")) {
                entityId = Int(tmpEntity)
            }
            if entityId != nil {
                if game.entities[entityId!] != nil {
                    entity = Entity(entityId!)
                    game.entities[entityId!] = entity
                }
                game.entities[entityId!]!.cardId = cardId
            }

            if game.joustReveals > 0 {
                currentEntity = game.entities[entityId!]
                if currentEntity != nil {
                    if currentEntity!.isControllerBy(game.opponent.id!) {
                        game.opponentJoust(currentEntity!, cardId: cardId, turn: game.turnNumber())
                    } else if currentEntity!.isControllerBy(game.player.id!) {
                        game.playerJoust(currentEntity!, cardId: cardId, turn: game.turnNumber())
                    }
                }
            }
        } else if line.isMatch(NSRegularExpression.rx(CreationTagRegex)) && !line.isMatch(NSRegularExpression.rx("HIDE_ENTITY")) {
            let match = line.firstMatchWithDetails(NSRegularExpression.rx(CreationTagRegex))
            //DDLogVerbose("Tag \(CreationTagRegex) -> \(match.groups)");
            let tag: String = match.groups[1].value
            let value: String = match.groups[2].value
            tagChangeHandler.tagChange(tag, id: currentEntityId, rawValue: value)
        } else if line.isMatch(NSRegularExpression.rx("Begin Spectating")) || line.isMatch(NSRegularExpression.rx("Start Spectator")) {
            game.gameMode = GameMode.Spectator
        } else if line.isMatch(NSRegularExpression.rx("End Spectator")) {
            game.gameMode = GameMode.Spectator
            game.gameEnd()
        } else if line.isMatch(NSRegularExpression.rx(ActionStartRegex)) {
            let match = line.firstMatchWithDetails(NSRegularExpression.rx(ActionStartRegex))
            //DDLogVerbose(@"ActionStartRegex %@ -> %@", ActionStartRegex, match);
            let actionStartingEntityId = Int(match.groups[1].value)
            var actionStartingCardId: String? = match.groups[2].value
            //NSString *target = ((NSRegularExpression.rxMatchGroup *) match.groups[3]).value;

            var player: Entity?, opponent: Entity?
            for (_, ent) in game.entities {
                if ent.getTag(GameTag.PLAYER_ID) == game.player.id {
                    player = ent
                } else if ent.getTag(GameTag.PLAYER_ID) == game.opponent.id {
                    opponent = ent
                }
            }

            var actionEntity: Entity
            if let _actionStartingCardId = actionStartingCardId where _actionStartingCardId.isEmpty {
                if game.entities[actionStartingEntityId!] != nil {
                    actionEntity = game.entities[actionStartingEntityId!]!
                    actionStartingCardId = actionEntity.cardId
                }
            }

            if game.entities[actionStartingEntityId!] != nil {
                actionEntity = game.entities[actionStartingEntityId!]!

                if actionEntity.getTag(GameTag.CONTROLLER) == game.player.id
                        && actionEntity.getTag(GameTag.CARDTYPE) == CardType.SPELL.rawValue {
                    //NSInteger targetEntityId = [actionEntity getTag:EGameTag_CARD_TARGET];
                    //Entity *targetEntity;
                    //var targetsMinion = game.Entities.TryGetValue(targetEntityId, out targetEntity) && targetEntity.IsMinion;
                    //gameState.GameHandler.HandlePlayerSpellPlayed(targetsMinion);
                }
            }

            if actionStartingCardId == nil || actionStartingCardId!.isEmpty {
                return
            }

            let type: String = match.groups[3].value;
            if type == "TRIGGER" {

            } else {
                let card = Card.byId(actionStartingCardId!)
                if card != nil && card!.type == "hero power" {
                    if player != nil && player!.getTag(GameTag.CURRENT_PLAYER) == 1 {
                        tagChangeHandler.playerUsedHeroPower = true
                        DDLogInfo("player use hero power")
                    } else if opponent != nil {
                        DDLogInfo("opponent use hero power")
                        tagChangeHandler.opponentUsedHeroPower = true
                    }
                }
            }
        } else if line.isMatch(NSRegularExpression.rx("BlockType=JOUST")) {
            game.joustReveals = 2
        }
    }
}
