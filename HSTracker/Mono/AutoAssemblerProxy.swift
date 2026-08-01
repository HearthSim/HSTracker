//
//  AutoAssemblerProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//
import Foundation

class AutoAssemblerProxy: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _deathrattle: OpaquePointer!
    static var _deathrattleGolden: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if AutoAssemblerProxy._class == nil {
            AutoAssemblerProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Minions.Mech", name: "AutoAssembler")
            AutoAssemblerProxy._deathrattle = MonoHelper.getMethod(AutoAssemblerProxy._class, "Deathrattle", 0)
            AutoAssemblerProxy._deathrattleGolden = MonoHelper.getMethod(AutoAssemblerProxy._class, "GoldenDeathrattle", 0)
        }
    }
    
    static func deathrattle() -> MonoHandle {
        let result = mono_runtime_invoke(AutoAssemblerProxy._deathrattle, nil, nil, nil)
        return MonoHandle(obj: result)
    }
        
    static func goldenDeathrattle() -> MonoHandle {
        let result = mono_runtime_invoke(AutoAssemblerProxy._deathrattleGolden, nil, nil, nil)
        return MonoHandle(obj: result)
    }
}
