//
//  RealmCard.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 22/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift

class RealmCard: Object {
    @objc dynamic var id = ""
    @objc dynamic var count = 0

    convenience init(id: String, count: Int) {
        self.init()
        self.id = id
        self.count = count
    }
}
