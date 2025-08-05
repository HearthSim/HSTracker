//
//  WhirringProtector.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/5/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class WhirringProtector: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _rally: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if WhirringProtector._class == nil {
            WhirringProtector._class = MonoHelper.loadClass(ns: "BobsBuddy.Minions.Mech", name: "WhirringProtector")
            WhirringProtector._rally = MonoHelper.getMethod(WhirringProtector._class, "Rally", 1)
        }
    }
    
    static func rally(golden: Bool) -> MonoHandle {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<Int32>>.allocate(capacity: 1)
        let a = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        a.pointee = golden ? 1 : 0
        params[0] = a
        
        let result: UnsafeMutablePointer<MonoObject>? = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            return mono_runtime_invoke(ReplicatingMenace._deathrattle, nil, $0, nil)
        })
        a.deallocate()
        params.deallocate()
        return MonoHandle(obj: result)
    }
}
