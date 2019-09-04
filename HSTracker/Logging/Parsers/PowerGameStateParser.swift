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
import RegexUtil

class PowerGameStateParser: LogEventParser {

    let BlockStartRegex = RegexPattern(stringLiteral: ".*BLOCK_START.*BlockType=(POWER|TRIGGER)"
        + ".*id=(\\d*).*(cardId=(\\w*)).*player=(\\d*).*Target=(.+).*SubOption=(.+)")
    let CardIdRegex: RegexPattern = "cardId=(\\w+)"
    let CreationRegex: RegexPattern = "FULL_ENTITY - Updating.*id=(\\d+).*zone=(\\w+).*CardID=(\\w*)"
    let CreationTagRegex: RegexPattern = "tag=(\\w+) value=(\\w+)"
    let GameEntityRegex: RegexPattern = "GameEntity EntityID=(\\d+)"
    let PlayerEntityRegex: RegexPattern = "Player EntityID=(\\d+) PlayerID=(\\d+) GameAccountId=(.+)"
    let PlayerIDRegex: RegexPattern = "\\[hi\\=(\\d+)\\slo=(\\d+)"
    let PlayerNameRegex: RegexPattern = "id=(\\d) Player=(.+) TaskList=(\\d)"
    let TagChangeRegex: RegexPattern = "TAG_CHANGE Entity=(.+) tag=(\\w+) value=(\\w+)"
    let UpdatingEntityRegex: RegexPattern = "(SHOW_ENTITY|CHANGE_ENTITY) - Updating Entity=(.+) CardID=(\\w*)"
    let BuildNumberRegex: RegexPattern = "BuildNumber=(\\d+)"
    let PlayerIDNameRegex: RegexPattern = "PlayerID=(\\d+), PlayerName=(.+)"

    var tagChangeHandler = TagChangeHandler()
    var currentEntity: Entity?

	private unowned(unsafe) let eventHandler: PowerEventHandler

	init(with eventHandler: PowerEventHandler) {
		self.eventHandler = eventHandler
	}

    // MARK: - Entities

    private var currentEntityId = 0

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
    private var inCreateGameBlock = false

    // MARK: - line handling

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
                set(currentEntity: id)

                if eventHandler.determinedPlayers() {
                    tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
                }
                return
            }
        }

        // players
        else if logLine.line.match(PlayerEntityRegex) {
            let matches = logLine.line.matches(PlayerEntityRegex)
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
                        
                        if matches.count > 2 {
                            let idmatch = matches[2].value
                            let idmatches = idmatch.matches(PlayerIDRegex)
                            if idmatches.count >= 2 {
                                if let accountId = MirrorHelper.getAccountId() {
                                    if let hi = UInt64(idmatches[0].value),
                                        let lo = UInt64(idmatches[1].value), (NSNumber(value: hi) == accountId.hi) && (NSNumber(value: lo) == accountId.lo) {
                                        eventHandler.player.id = playerId
                                        if let name = entity.name {
                                            eventHandler.player.name = name
                                        }
                                    } else {
                                        if let isSpectating = MirrorHelper.isSpectating(), isSpectating == false {
                                            eventHandler.opponent.id = playerId
                                        }
                                        if let name = entity.name, name != "UNKNOWN HUMAN PLAYER" {
                                            eventHandler.opponent.name = name
                                        }
                                    }
                                }
                            }
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
        } else if logLine.line.match(TagChangeRegex) {
            if self.inCreateGameBlock {
                self.inCreateGameBlock = false
                self.autoDetectDeck()
            }
            
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
                var entity = eventHandler.entities.map { $0.1 }
                    .first { $0.name == rawEntity }

                if let entity = entity {
                    tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag,
                                               id: entity.id, rawValue: value)
                } else {
                    let players = eventHandler.entities.map { $0.1 }
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
                                let playerEntity = eventHandler.entities.map({$0.1})
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
        } else if logLine.line.match(CreationRegex) {
            if self.inCreateGameBlock {
                self.inCreateGameBlock = false
                self.autoDetectDeck()
            }
            
            let matches = logLine.line.matches(CreationRegex)
            let id = Int(matches[0].value)!
            guard let zone = Zone(rawString: matches[1].value) else { return }
            var cardId: String? = matches[2].value

            if eventHandler.entities[id] == .none {
                if cardId.isBlank && zone != .setaside {
                    if let blockId = currentBlock?.id,
                        let cards = eventHandler.knownCardIds[blockId] {
                        cardId = cards.first
                        if !cardId.isBlank {
                            logger.verbose("Found known cardId "
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

            set(currentEntity: id)
            if eventHandler.determinedPlayers() {
                tagChangeHandler.invokeQueuedActions(eventHandler: eventHandler)
            }
            eventHandler.currentEntityHasCardId = !cardId.isBlank
            eventHandler.currentEntityZone = zone
            return
        } else if logLine.line.match(UpdatingEntityRegex) {
            if self.inCreateGameBlock {
                self.inCreateGameBlock = false
                self.autoDetectDeck()
            }
            
            let matches = logLine.line.matches(UpdatingEntityRegex)
            let type = matches[0].value
            let rawEntity = matches[1].value
            let cardId = matches[2].value
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
                if type != "CHANGE_ENTITY" || eventHandler.entities[entityId]!.cardId.isBlank {
                    eventHandler.entities[entityId]!.cardId = cardId
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
        } else if logLine.line.match(CreationTagRegex)
            && !logLine.line.contains("HIDE_ENTITY") {
            let matches = logLine.line.matches(CreationTagRegex)
            let tag = matches[0].value
            let value = matches[1].value
            tagChangeHandler.tagChange(eventHandler: eventHandler, rawTag: tag, id: currentEntityId,
                                       rawValue: value, isCreationTag: true)
            creationTag = true
        } else if logLine.line.match(BuildNumberRegex) {
            if let buildNumber = Int(logLine.line.matches(BuildNumberRegex)[0].value) {
                eventHandler.set(buildNumber: buildNumber)
            }
        } else if logLine.line.match(PlayerIDNameRegex) {
            let matches = logLine.line.matches(PlayerIDNameRegex)
            if matches.count >= 2, let playerID = Int(matches[0].value) {
                let playerName = matches[1].value
                eventHandler.add(playerName: playerName, for: playerID)
            }
        }
        if logLine.line.contains("End Spectator") {
            eventHandler.gameEnd()
        } else if logLine.line.contains("BLOCK_START") {
            if self.inCreateGameBlock {
                self.inCreateGameBlock = false
                self.autoDetectDeck()
            }
            
            var type: String?
            var cardId: String?
            var correspondPlayer: Int?
            let matches = logLine.line.matches(BlockStartRegex)
            if matches.count > 0 {
                type = matches[0].value
            }
            
            if matches.count > 3 {
                cardId = matches[3].value
            }
            
            if matches.count > 4 {
                correspondPlayer = Int(matches[4].value)!
            }
            
            blockStart(type: type, cardId: cardId)

            if logLine.line.match(BlockStartRegex) {
                let player = eventHandler.entities.map { $0.1 }
                    .first { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.player.id }
                let opponent = eventHandler.entities.map { $0.1 }
                    .first { $0.has(tag: .player_id) && $0[.player_id] == eventHandler.opponent.id }

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
                
                if type == "TRIGGER" && actionStartingCardId == CardIds.Collectible.Neutral.AugmentedElekk {
                    if currentBlock?.parent != nil {
                        actionStartingCardId = currentBlock?.parent?.cardId
                        type = currentBlock?.parent?.type
                    }
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
                        case CardIds.Collectible.Mage.FrozenClone:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: getTargetCardId(matches: matches),
                                           count: 2)
                        case CardIds.Collectible.Shaman.Moorabi, CardIds.Collectible.Rogue.SonyaShadowdancer:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: getTargetCardId(matches: matches))
                        case CardIds.Collectible.Neutral.HoardingDragon:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoin, count: 2)
                        case CardIds.Collectible.Priest.GildedGargoyle:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.TheCoin)
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
                        case CardIds.Collectible.Warrior.Wrenchcalibur:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
                        case CardIds.Collectible.Priest.SpiritOfTheDead:
                            if correspondPlayer == eventHandler.player.id {
                                addKnownCardId(eventHandler: eventHandler, cardId: eventHandler.player.lastDiedMinionCardId)
                            } else if correspondPlayer == eventHandler.opponent.id {
                                addKnownCardId(eventHandler: eventHandler, cardId: eventHandler.opponent.lastDiedMinionCardId)
                            }
                        default: break
                        }
                    }
                } else { // type == "POWER"
                    if let actionStartingCardId = actionStartingCardId {
                        switch actionStartingCardId {
                        case CardIds.Collectible.Rogue.GangUp,
                             CardIds.Collectible.Hunter.DireFrenzy,
                             CardIds.Collectible.Rogue.LabRecruiter:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: getTargetCardId(matches: matches),
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
                             CardIds.Collectible.Druid.Splintergraft,
                             CardIds.Collectible.Neutral.BalefulBanker,
                             CardIds.Collectible.Neutral.DollmasterDorian:
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
                        case CardIds.Collectible.Mage.GhastlyConjurer:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.Collectible.Mage.MirrorImage)
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
                        case CardIds.NonCollectible.Neutral.CoinPouch:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SackOfCoins)
                        case CardIds.NonCollectible.Neutral.SackOfCoins:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.HeftySackOfCoins)
                        case CardIds.NonCollectible.Neutral.CreepyCurio:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.HauntedCurio)
                        case CardIds.NonCollectible.Neutral.HauntedCurio:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.CursedCurio)
                        case CardIds.NonCollectible.Neutral.OldMilitiaHorn:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.MilitiaHorn)
                        case CardIds.NonCollectible.Neutral.MilitiaHorn:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.VeteransMilitiaHorn)
                        case CardIds.NonCollectible.Neutral.SurlyMob:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.AngryMob)
                        case CardIds.NonCollectible.Neutral.AngryMob:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.CrazedMob)                        
                        case CardIds.Collectible.Neutral.SparkEngine:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SparkDrill_SparkToken)
                        case CardIds.Collectible.Priest.ExtraArms:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Priest.ExtraArms_MoreArmsToken)
                        case CardIds.Collectible.Neutral.SeaforiumBomber:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
                        case CardIds.Collectible.Warrior.ClockworkGoblin:
                            addKnownCardId(eventHandler: eventHandler,
                                           cardId: CardIds.NonCollectible.Neutral.SeaforiumBomber_BombToken)
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
            self.inCreateGameBlock = true
            tagChangeHandler.clearQueuedActions()

            // indicate game start
            maxBlockId = 0
            currentBlock = nil
            resetCurrentEntity()
            eventHandler.gameStart(at: logLine.time)
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
            if let currentMode = eventHandler.currentMode,
                let deck = CoreManager.autoDetectDeck(mode: currentMode, playerClass: self.eventHandler.player.playerClass) {
                eventHandler.set(activeDeckId: deck.deckId, autoDetected: true)
            } else {
                logger.warning("could not autodetect deck")
                eventHandler.set(activeDeckId: nil, autoDetected: false)
            }
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

        if let blockId = currentBlock?.id {
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
