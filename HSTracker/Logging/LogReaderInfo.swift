//
//  LogReaderInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 21/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class LogReaderInfo {

    var name: LogLineNamespace
    var startsWithFilters: [String]
    var containsFilters: [String]
    var filePath: String?
    var reset = true

    var hasFilters: Bool {
        return !startsWithFilters.isEmpty || !containsFilters.isEmpty
    }

    init(name: LogLineNamespace, startsWithFilters: [String] = [],
         containsFilters: [String] = [], reset: Bool = true) {
        self.name = name
        self.startsWithFilters = startsWithFilters
        self.containsFilters = containsFilters
        self.reset = reset
    }

}
