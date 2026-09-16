//
//  MercenariesAbility.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// The three abilities HDT reads off a Mercenaries board minion, as
// OverlayWindow.GetMercAbilities builds them. An ability is either live (an
// entity on the board, so its real cooldown and speed are known) or static (the
// remote config's definition for a mercenary whose abilities have not been
// revealed yet, so the values are the printed ones).
class MercAbilityData {
    var entity: Entity?
    var card: Card?
    var active = false
    var gameTurn = 0
    var hasTiers = false

    init(entity: Entity?, card: Card?, active: Bool, gameTurn: Int, hasTiers: Bool) {
        self.entity = entity
        self.card = card
        self.active = active
        self.gameTurn = gameTurn
        self.hasTiers = hasTiers
    }
}

// OverlayWindow.GetMercAbilities, unchanged from the AppKit board overlay that
// used to own it.
func getMercAbilities(player: Player) -> [[MercAbilityData]] {
    let game = AppDelegate.instance().coreManager.game

    let result: [[MercAbilityData]] = player.board.filter { x in x.isMinion }.sorted { (a, b) in a.zonePosition < b.zonePosition }.compactMap { entity in
        let dbfId = entity.card.dbfId
        let actualAbilities = player.playerEntities.filter { x in x[.lettuce_ability_owner] == entity.id && !x.has(tag: .lettuce_is_equipment) && !x.has(tag: .dont_show_in_history) && x.hasCardId }
        let staticAbilities = dbfId != 0 ? RemoteConfig.mercenaries?.first { x in x.skinDbfIds.contains(dbfId)}?.specializations.first?.abilities ?? [MercenaryAbility]() : [MercenaryAbility]()
        var data = [MercAbilityData]()
        let max_ = min(3, max(staticAbilities.count, actualAbilities.count))

        for i in 0 ..< max_ {
            let staticAbility = i < staticAbilities.count ? staticAbilities[i] : nil
            let actual = staticAbility != nil ? actualAbilities.first(where: { x in staticAbility!.tiers.any { t in t.dbf_id == x.card.dbfId }}) : actualAbilities.first { x in data.all({ d in d.entity?.cardId != x.cardId }) }
            if let actual = actual {
                let active = entity[.lettuce_ability_tile_visual_self_only] == actual.id || entity[.lettuce_ability_tile_visual_all_visible] == actual.id
                data.append(MercAbilityData(entity: actual, card: nil, active: active, gameTurn: 0, hasTiers: false))
            } else if let staticAbility = staticAbility {
                if let card = actual?.card ?? Cards.by(dbfId: staticAbility.tiers.last?.dbf_id ?? 0, collectible: false) {
                    let gameTurn = game.gameEntity?[.turn] ?? 0
                    data.append(MercAbilityData(entity: nil, card: card, active: false, gameTurn: gameTurn, hasTiers: staticAbility.tiers.count > 1))
                }
            }
        }
        return data
    }
    return result
}

// HDT's MercenariesAbilityViewModel. Immutable, so a struct - the board rebuilds
// the whole array whenever the entities change.
@available(macOS 10.15, *)
struct MercenariesAbilityModel: Identifiable, Equatable {
    // Position in the minion's strip. HDT identifies items by reference; SwiftUI
    // needs a key, and a minion never has more than three.
    let id: Int
    let entity: Entity?
    let card: Card?
    let active: Bool
    let gameTurn: Int

    init(id: Int, data: MercAbilityData) {
        self.id = id
        self.entity = data.entity
        self.card = data.card
        self.active = data.active
        self.gameTurn = data.gameTurn
    }

    var turnsElapsed: Int { max(0, gameTurn - 1) }

    var cooldown: Int {
        entity?[.lettuce_current_cooldown] ?? max(0, (card?.mercenariesAbilityCooldown ?? 0) - turnsElapsed)
    }

    var speed: Int { entity?[.cost] ?? card?.cost ?? 0 }
    var baseSpeed: Int { entity?.card.cost ?? card?.cost ?? 0 }

    var cooldownShading: Bool { cooldown > 0 }
    var cooldownText: String? { cooldown > 0 ? cooldown.description : nil }
    var speedText: String { speed.description }

    // SpeedUncertainIndicatorVisibility: no entity means the ability came from
    // the remote config rather than the board, so its speed is the printed one
    // and may not be what the mercenary actually has.
    var speedUncertain: Bool { entity == nil }

    // SpeedColorBrush: red when the speed has been raised, green when lowered.
    var speedColor: Color {
        speed > baseSpeed ? .red : speed < baseSpeed ? Color(red: 0, green: 1, blue: 0) : .white
    }

    var cardId: String? { entity?.cardId ?? card?.id }

    static func == (lhs: MercenariesAbilityModel, rhs: MercenariesAbilityModel) -> Bool {
        lhs.id == rhs.id && lhs.entity === rhs.entity && lhs.card === rhs.card
            && lhs.active == rhs.active && lhs.gameTurn == rhs.gameTurn
            && lhs.cooldown == rhs.cooldown && lhs.speed == rhs.speed
    }
}
