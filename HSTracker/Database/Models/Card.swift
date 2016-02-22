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

    class func byId(cardId: String) -> Card? {
        return Card.MR_findFirstWithPredicate(NSPredicate(format: "cardId = %@ and", cardId))
    }

    var englishName: String {
        if let language = Settings.instance.hearthstoneLanguage where language == "enUS" {
            return self.name
        }
        return self.enName
    }

}
