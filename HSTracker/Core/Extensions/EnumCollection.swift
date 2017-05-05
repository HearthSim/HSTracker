//
//  EnumCollection.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol EnumCollection: Hashable {}

extension EnumCollection {
    static func cases() -> AnySequence<Self> {
        typealias SelfAlias = Self
        return AnySequence { () -> AnyIterator<SelfAlias> in
            var raw = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &raw) {
                    $0.withMemoryRebound(to: SelfAlias.self, capacity: 1) { $0.pointee }
                }
                guard current.hashValue == raw else { return nil }
                raw += 1
                return current
            }
        }
    }
}
