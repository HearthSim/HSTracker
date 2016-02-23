//
//  DeckCard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord

@objc(DeckCard)
class DeckCard: NSManagedObject {

    @NSManaged var cardId: String
    @NSManaged var count: Int
    @NSManaged var deck: Deck

}
