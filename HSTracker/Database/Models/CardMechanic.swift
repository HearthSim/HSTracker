//
//  CardMechanic.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord

@objc(CardMechanic)
class CardMechanic: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var cards: Set<Card>

}
