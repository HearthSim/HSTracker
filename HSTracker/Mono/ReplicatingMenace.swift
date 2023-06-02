//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class ReplicatingMenace: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _deathrattle: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if ReplicatingMenace._class == nil {
            ReplicatingMenace._class = MonoHelper.loadClass(ns: "BobsBuddy.Minions.Mech", name: "ReplicatingMenace")
            ReplicatingMenace._deathrattle = MonoHelper.getMethod(ReplicatingMenace._class, "Deathrattle", 1)
        }
    }
    
    static func deathrattle(golden: Bool) -> MonoHandle {
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
