//
//  Collection.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/16/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation
import CryptoKit

enum CollectionType {
    case constructed
    case mercenaries
}

class CollectionBase: Codable {
    let accountHi: Int64
    let accountLo: Int64
    let battleTag: String
    
    init(accountHi: Int64, accountLo: Int64, battleTag: String) {
        self.accountHi = accountHi
        self.accountLo = accountLo
        self.battleTag = battleTag
    }
}

class Collection: CollectionBase {
    let collection: [Int: [Int]]
    let favorite_heroes: [Int: Int]
    let cardbacks: [Int]
    let favorite_cardback: Int
    let dust: Int
    
    private enum CodingKeys: String, CodingKey {
        case collection, favorite_heroes, cardbacks, favorite_cardback, dust
    }
    
    func hash() -> String {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = .sortedKeys
            let value = try enc.encode(self)
            
            let sha = Insecure.MD5.hash(data: value)
            
            let hashString = sha.compactMap { String(format: "%02x", $0) }.joined()
            return hashString
        } catch {
            return "00"
        }
    }
    
    init(accountHi: Int64, accountLo: Int64, battleTag: String, collection: MirrorCollection) {
        var c: [Int: [Int]] = [:]
        for mirrorCard in collection.cards {
            if let card = Cards.any(byId: mirrorCard.cardId) {
                if mirrorCard.count.intValue > 0 {
                    var counts = c[card.dbfId] ?? [0, 0, 0]
                    let premiumType = mirrorCard.premium.intValue
                    if premiumType >= 0 && premiumType <= 2 {
                        counts[premiumType] = mirrorCard.count.intValue
                    }
                    c[card.dbfId] = counts
                }
            }
        }

        self.collection = c
        
        var h = [:] as [Int: Int]
        for (playerclassid, mirrorCard) in collection.favoriteHeroes {
            if let card = Cards.any(byId: mirrorCard.cardId) {
                h[playerclassid.intValue] = card.dbfId
            }
        }

        self.favorite_heroes = h
        self.cardbacks = collection.cardbacks.compactMap { x in x.intValue}.sorted()
        self.favorite_cardback = collection.favoriteCardback.intValue
        self.dust = collection.dust.intValue
        
        super.init(accountHi: accountHi, accountLo: accountLo, battleTag: battleTag)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(collection, forKey: .collection)
        try container.encode(favorite_heroes, forKey: .favorite_heroes)
        try container.encode(cardbacks, forKey: .cardbacks)
        try container.encode(favorite_cardback, forKey: .favorite_cardback)
        try container.encode(dust, forKey: .dust)
    }
}

class MercenariesCollection: CollectionBase {
    class Ability: Codable {
        let id: Int
        let tier: Int
        
        init(ability: MirrorAbility) {
            id = ability.id.intValue
            tier = ability.tier.intValue
        }
    }
    
    class ArtVariation: Codable {
        let dbfId: Int
        let equipped: Bool
        let premium: Int
        init(variation: MirrorArtVariation) {
            dbfId = variation.dbfId.intValue
            equipped = variation.equipped
            premium = variation.premium.intValue
        }
    }

    class Mercenary: Codable {
        let id: Int
        let level: Int
        let coins: Int
        let abilities: [Ability]
        let equipment: [Ability]
        let art_variations: [ArtVariation]
        
        init(merc: MirrorCollectionMercenary) {
            id = merc.id.intValue
            level = merc.level.intValue
            coins = merc.currencyAmount.intValue
            abilities = merc.abilities.compactMap { x in Ability(ability: x) }
            equipment = merc.equipments.compactMap { x in Ability(ability: x) }
            art_variations = merc.artVariations.compactMap { x in ArtVariation(variation: x) }
        }
    }
    
    let mercenaries: [Mercenary]
    
    private enum CodingKeys: String, CodingKey {
        case mercenaries
    }
    
    func hash() -> String {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = .sortedKeys
            let value = try enc.encode(self)
            
            let sha = Insecure.MD5.hash(data: value)
            
            let hashString = sha.compactMap { String(format: "%02x", $0) }.joined()
            return hashString
        } catch {
            return "00"
        }
    }
    
    init(accountHi: Int64, accountLo: Int64, battleTag: String, collection: [MirrorCollectionMercenary]) {
        mercenaries = collection.compactMap { x in Mercenary(merc: x) }
        
        super.init(accountHi: accountHi, accountLo: accountLo, battleTag: battleTag)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mercenaries, forKey: .mercenaries)
    }
}
