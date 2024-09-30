//
//  HoggyBank.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class HoggyBank: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _deathrattle: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if HoggyBank._class == nil {
            HoggyBank._class = MonoHelper.loadClass(ns: "BobsBuddy.Trinkets", name: "HoggyBank")
            HoggyBank._deathrattle = MonoHelper.getMethod(HoggyBank._class, "Deathrattle", 0)
        }
    }
    
    static func deathrattle() -> MonoHandle {
        let result = mono_runtime_invoke(HoggyBank._deathrattle, nil, nil, nil)
        return MonoHandle(obj: result)
    }
}
