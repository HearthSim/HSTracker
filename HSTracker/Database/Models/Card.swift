//
//  Card.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord

@objc(Card)
class Card: NSManagedObject {

    @NSManaged var cardId: String
    @NSManaged var collectible: Bool
    @NSManaged var cost: Int
    @NSManaged var faction: String
    @NSManaged var flavor: String
    @NSManaged var health: Int
    @NSManaged var name: String
    @NSManaged var enName: String
    @NSManaged var playerClass: String
    @NSManaged var rarity: String
    @NSManaged var set: String
    @NSManaged var text: String
    @NSManaged var type: String
    @NSManaged var mechanics: Set<CardMechanic>
    @NSManaged var isStandard: Bool

    var count: Int = 0
    var handCount: Int = 0
    var hasChanged: Bool = false

    var jousted: Bool = false
    var isStolen: Bool = false
    var isCreated: Bool = false
    var wasDiscarded: Bool = false

    var highlightDraw: Bool = false
    var highlightInHand: Bool = false

    static func byId(cardId: String) -> Card? {
        return Card.MR_findFirstWithPredicate(NSPredicate(format: "cardId = %@", cardId))
    }
    
    static func byEnglishName(name: String) -> Card? {
        //where(collectible: true)
        //.and(:card_type).ne('hero')
          //  .and(:card_type).ne('hero power')
        
        return Card.MR_findFirstWithPredicate(NSPredicate(format: "enName = %@ and collectible = %@ and type != %@ and type != %@", name, true, "hero", "hero power"))
    }

    var englishName: String {
        if let language = Settings.instance.hearthstoneLanguage where language == "enUS" {
            return self.name
        }
        return self.enName
    }
    
    override var description : String {
        return "<\(NSStringFromClass(self.dynamicType)): "
            + "self.cardId=\(self.cardId)"
            + ", self.collectible=\(self.collectible)"
            + ", self.cost=\(self.cost)"
            + ", self.faction=\(self.faction)"
            + ", self.flavor=\(self.flavor)"
            + ", self.health=\(self.health)"
            + ", self.name=\(self.name)"
            + ", self.enName=\(self.enName)"
            + ", self.playerClass=\(self.playerClass)"
            + ", self.rarity=\(self.rarity)"
            + ", self.set=\(self.set)"
            + ", self.text=\(self.text)"
            + ", self.type=\(self.type)"
            + ", self.mechanics=\(self.mechanics)"
            + ", self.isStandard=\(self.isStandard)"
            + ", self.count=\(self.count)"
            + ", self.handCount=\(self.handCount)"
            + ", self.hasChanged=\(self.hasChanged)"
            + ", self.jousted=\(self.jousted)"
            + ", self.isStolen=\(self.isStolen)"
            + ", self.isCreated=\(self.isCreated)"
            + ", self.wasDiscarded=\(self.wasDiscarded)"
            + ", self.highlightDraw=\(self.highlightDraw)"
            + ", self.highlightInHand=\(self.highlightInHand)"
    }

}
