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
    var startsWithFiltersGroup: [[String]]
    var containsFiltersGroup: [[String]]
    var filePath: String?
    var prefix = "D "
    var reset = true
    var include = true

    var hasFilters: Bool {
        return !startsWithFiltersGroup.isEmpty || !containsFiltersGroup.isEmpty
    }

    init(name: LogLineNamespace, startsWithFilters: [[String]] = [],
         containsFilters: [[String]] = [], reset: Bool = true, include: Bool = true) {
        self.name = name
        self.startsWithFiltersGroup = startsWithFilters
        self.containsFiltersGroup = containsFilters
        self.reset = reset
        self.include = include
    }

}
