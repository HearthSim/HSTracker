//
//  SynchronizedDictionary.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/19/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class SynchronizedDictionary<Key: Hashable, Value> {
    private let lock = UnfairLock()
    private var dictionary = [Key: Value]()
    
    var count: Int {
        return lock.around {
            return dictionary.count
        }
    }
    
    subscript(index: Key) -> Value? {
        get {
            return lock.around {
                return dictionary[index]
            }
        }
        set(newValue) {
            lock.around {
                dictionary[index] = newValue
            }
        }
    }
    
    var values: [Value] {
        return lock.around {
            return [Value](dictionary.values)
        }
    }
    
    var first: (Key, Value)? {
        return lock.around {
            return dictionary.first
        }
    }
    
    @discardableResult func removeValue(forKey key: Key) -> Value? {
        return lock.around {
            return dictionary.removeValue(forKey: key)
        }
    }
    
    func removeAll() {
        lock.around {
            dictionary.removeAll()
        }
    }
    
    func first(where predicate: (Key, Value) -> Bool) -> (Key, Value)? {
        return lock.around {
            return dictionary.first(where: predicate)
        }
    }
    
    func filter(_ isIncluded: (Key, Value) -> Bool) -> [Key: Value] {
        return lock.around {
            return dictionary.filter(isIncluded)
        }
    }
    
    func forEach(_ body: ((Key, Value)) -> Void) {
        lock.around {
            dictionary.forEach(body)
        }
    }
    
    func map<T>(_ transform: ((Key, Value)) -> T) -> [T] {
        return lock.around {
            return dictionary.map(transform)
        }
    }
    
    func compactMap<T>(_ transform: ((Key, Value)) -> T) -> [T] {
        return lock.around {
            return dictionary.compactMap(transform)
        }
    }
    
    func containsKey(_ other: Key) -> Bool {
        return lock.around {
            return dictionary.keys.contains(other)
        }
    }
}
