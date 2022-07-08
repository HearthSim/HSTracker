//
//  SynchronizedArray.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/6/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class SynchronizedArray<T> {
    let lock = UnfairLock()
    var arr = [T]()
    
    var count: Int {
        return lock.around {
            return arr.count
        }
    }
    
    func array() -> [T] {
        return lock.around {
            var res = [T]()
            res.append(contentsOf: arr)
            return res
        }
    }
    
    func removeAll() {
        lock.around {
            arr.removeAll()
        }
    }
    
    func removeAll(where shouldBeRemoved: (T) -> Bool) {
        lock.around {
            arr.removeAll(where: shouldBeRemoved)
        }
    }
    
    @discardableResult func remove(at index: Int) -> T {
        return lock.around {
            return arr.remove(at: index)
        }
    }
    
    func append(_ newElement: T) {
        lock.around {
            arr.append(newElement)
        }
    }
    
    func removeFirst() -> T {
        return lock.around {
            return arr.removeFirst()
        }
    }
    
    func insert(_ newElement: T, at: Int) {
        lock.around {
            arr.insert(newElement, at: at)
        }
    }
    
    func first(where predicate: (T) -> Bool) -> T? {
        return lock.around {
            return arr.first(where: predicate)
        }
    }
    
    func filter(_ isIncluded: (T) -> Bool) -> [T] {
        return lock.around {
            return arr.filter(isIncluded)
        }
    }
    
    subscript(index: Int) -> T {
        get {
            return lock.around {
                return arr[index]
            }
        }
        set(newValue) {
            lock.around {
                arr[index] = newValue
            }
        }
    }
}
