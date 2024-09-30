//
//  JarredFrostling.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class JarredFrostling: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _deathrattle: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if JarredFrostling._class == nil {
            JarredFrostling._class = MonoHelper.loadClass(ns: "BobsBuddy.Trinkets", name: "JarredFrostling")
            JarredFrostling._deathrattle = MonoHelper.getMethod(JarredFrostling._class, "Deathrattle", 0)
        }
    }
    
    static func deathrattle() -> MonoHandle {
        let result = mono_runtime_invoke(JarredFrostling._deathrattle, nil, nil, nil)
        return MonoHandle(obj: result)
    }
}
