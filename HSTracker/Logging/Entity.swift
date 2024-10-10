/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */

import Foundation

class Entity {
    var id: Int
	
    var cardId = ""
    var name: String?
    var tags = SynchronizedDictionary<GameTag, Int>()
    /*
     * tags is accessed from the reader thread as well as from the main thread.
     * There are some crashes in AppCenter on access to tags so we're trying to play it safe here.
     * There are still a few cases where this is used illegally. Ideally, we should make tags private to enforce
     * locking the semaphore every time.
     */
	
    lazy var info: EntityInfo = { [unowned(unsafe) self] in
        return EntityInfo(entity: self) }()

    init() {
        self.id = -1
    }

    init(id: Int) {
        self.id = id
    }

    subscript(tag: GameTag) -> Int {
        get {
            guard let value = tags[tag] else {
                return 0
            }
            return value
        }
        set {
            tags[tag] = newValue
        }
    }

    func has(tag: GameTag) -> Bool {
        return self[tag] > 0
    }
	
	func isPlayer(eventHandler: PowerEventHandler) -> Bool {
		return self[.player_id] == eventHandler.player.id
	}

    var isActiveDeathrattle: Bool {
        return has(tag: .deathrattle) && self[.deathrattle] == 1
    }

    var isCurrentPlayer: Bool {
        return has(tag: .current_player)
    }
    
    var isTheCoin: Bool {
        return cardId == CardIds.NonCollectible.Neutral.TheCoinBasic || (isSpell && self[.gametag_2088] == 1)
    }
    
    func isInZone(zone: Zone) -> Bool {
        if zone.rawValue < 0 {
            return false
        }
        let fake = self[.fake_zone]
        if fake > 0 {
            return fake == zone.rawValue
        }
        return self[.zone] == zone.rawValue
    }

    func isControlled(by controller: Int) -> Bool {
        let lettuceController = self[.lettuce_controller]
        if lettuceController > 0 {
            return lettuceController == controller
        }
        return self.has(tag: .controller) ? self[.controller] == controller : false
    }
    
    func isAttachedTo(entityId: Int) -> Bool {
        return self[.attached] == entityId
    }

    var isSecret: Bool {
        return has(tag: .secret)
    }
    var isQuest: Bool {
        return has(tag: .quest) || isQuestline
    }
    var isQuestline: Bool {
        return has(tag: .questline)
    }
    var isQuestlinePart: Bool {
        return isQuestline && self[.questline_part] > 1
    }
    var isBattlegroundsQuest: Bool {
        return self.has(tag: .quest_reward_database_id)
    }
    var isBattlegroundsSpell: Bool {
        return self[.cardtype] == CardType.battleground_spell.rawValue
    }
    var isBattlegroundsTrinket: Bool {
        return self.has(tag: .bacon_trinket)
    }
    var isSideQuest: Bool {
        return has(tag: .sidequest)
    }
    var isSigil: Bool {
        return has(tag: .sigil)
    }
    var isObjective: Bool {
        return has(tag: .objective)
    }
    var isSpell: Bool {
        return self[.cardtype] == CardType.spell.rawValue
    }
	func isOpponent(eventHandler: PowerEventHandler) -> Bool {
		return !isPlayer(eventHandler: eventHandler) && has(tag: .player_id)
    }
    var isEnchantment: Bool {
        return self[.cardtype] == CardType.enchantment.rawValue
    }
    var takesBoardSlot: Bool {
        return isMinion || isLocation || isBattlegroundsSpell
    }
    var isMinion: Bool {
        return has(tag: .cardtype) && self[.cardtype] == CardType.minion.rawValue
    }
    var isLocation: Bool {
        return self[.cardtype] == CardType.location.rawValue
    }
    var isPlayableCard: Bool {
        return isMinion || isLocation || isSpell || isWeapon || isPlayableHero
    }
    var isWeapon: Bool {
        return has(tag: .cardtype) && self[.cardtype] == CardType.weapon.rawValue
    }
    var isHero: Bool {
        return self[.cardtype] == CardType.hero.rawValue
    }
    var isHeroPower: Bool {
        return self[.cardtype] == CardType.hero_power.rawValue
    }
    var isBgsQuestReward: Bool {
        return self[.cardtype] == CardType.battleground_quest_reward.rawValue
    }
    var isPlayableHero: Bool {
        return isHero && card.set != .hero_skins && card.collectible
    }

    var isInHand: Bool {
        return isInZone(zone: .hand)
    }
    var isInDeck: Bool {
        return isInZone(zone: .deck)
    }
    var isInPlay: Bool {
        return isInZone(zone: .play)
    }
    var isInGraveyard: Bool {
        return isInZone(zone: .graveyard)
    }
    var isInSetAside: Bool {
        return isInZone(zone: .setaside)
    }
    var isInSecret: Bool {
        return isInZone(zone: .secret)
    }

    var health: Int {
        return self[.health] - self[.damage]
    }
    var attack: Int {
        return self[.atk]
    }

    var hasCardId: Bool {
        return !cardId.isBlank
    }
    
    var hasDredge: Bool {
        return has(tag: .dredge) || cardId == CardIds.Collectible.Warrior.FromTheDepths
    }
    
    var creatorId: Int {
        // TODO: add hidden support
        /*
        if isHidden {
            return 0
        }
        */
        var creatorId = self[.displayed_creator]
        if creatorId == 0 {
            creatorId = self[.creator]
        }
        return creatorId
    }
    
    func clearCardId() {
        cardId = ""
        info.clearCardId()
    }

    private var _cachedCard: Card?
    var card: Card {
        if let card = _cachedCard {
            return card
        } else if let card = Cards.any(byId: cardId) {
            return card
        }
        return Card()
    }

    func set(cardCount count: Int) {
        card.count = count
    }
    
    var zonePosition: Int {
        let fake = self[.fake_zone_position]
        if fake > 0 {
            return fake
        }
        return self[.zone_position]
    }
}

extension Entity: NSCopying {
    func copy() -> Entity {
        // swiftlint:disable force_cast
        return copy(with: nil) as! Entity
        // swiftlint:enable force_cast
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let e = Entity(id: id)
        e.cardId = cardId
        e.name = name
        tags.forEach({ e.tags[$0.0] = $0.1 })
        e.info.discarded = info.discarded
        e.info.returned = info.returned
        e.info.mulliganed = info.mulliganed
        e.info.created = info.created
        e.info.hasOutstandingTagChanges = info.hasOutstandingTagChanges
        e.info.originalController = info.originalController
        e.info.hidden = info.hidden
        e.info.turn = info.turn
        e.info.deckIndex = info.deckIndex
        e.info.inGraveyardAtStartOfGame = info.inGraveyardAtStartOfGame
        e.info.guessedCardState = info.guessedCardState
        e.info.latestCardId = info.latestCardId
        e.info.storedCardIds = info.storedCardIds
        e.info.forged = info.forged

        return e
    }
}

extension Entity: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Entity, rhs: Entity) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Entity: CustomStringConvertible {
    var description: String {
        let cardName = Cards.any(byId: cardId)?.name ?? ""
        let tags = self.tags.map {
            "\($0.0)=\($0.1)"
        }.joined(separator: ",")
        let hide = info.hidden && (isInHand || isInDeck)
        return "[Entity: id=\(id), cardId=\(hide ? "" : cardId), "
                + "cardName=\(hide ? "" : cardName), "
                + "name=\(String(describing: hide ? "" : name)), "
                + "tags=(\(tags)), "
                + "info=\(info)]"
    }
}
