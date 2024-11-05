//
//  ReflectionHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ReflectionHelper {
    private static var cacheMonoClassList = [MonoClassInitializer.Type]()
    private static var cacheActiveEffectClassList = [EntityBasedEffect.Type]()
    private static var cacheCounterClassList = [BaseCounter.Type]()

    static func initialize() {
        var count: UInt32 = 0
        let classListPtr = objc_copyClassList(&count)
        defer {
          free(UnsafeMutableRawPointer(classListPtr))
        }
        let classListBuffer = UnsafeBufferPointer(
          start: classListPtr, count: Int(count)
        )
        
        classListBuffer.forEach { cl in
            // checking the name of the class for HSTracker prefix speeds it up from 12s to 100ms
            // it also avoids some werid crashes that happen when trying to cast it to a type instead of
            // protocol
            let name = class_getName(cl)
            if memcmp(name, "HSTracker.", 10) != 0 {
                return
            }
            if let mcl = cl as? MonoClassInitializer.Type {
                cacheMonoClassList.append(mcl)
            } else if let aecl = cl as? EntityBasedEffect.Type {
                cacheActiveEffectClassList.append(aecl)
            } else if let dccl = cl as? BaseCounter.Type, cl != BaseCounter.self && cl != StatsCounter.self && cl != NumericCounter.self {
                cacheCounterClassList.append(dccl)
            }
        }
    }
    
    static func getMonoClasses() -> [MonoClassInitializer.Type] {
        return cacheMonoClassList
    }
    
    static func getActiveEffectClasses() -> [EntityBasedEffect.Type] {
        return cacheActiveEffectClassList
    }
    
    static func getCounterClasses() -> [BaseCounter.Type] {
        return cacheCounterClassList
    }
}
