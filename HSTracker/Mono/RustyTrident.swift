//
//  RustyTrident.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class RustyTrident: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _deathrattle: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if RustyTrident._class == nil {
            RustyTrident._class = MonoHelper.loadClass(ns: "BobsBuddy.Trinkets", name: "RustyTrident")
            RustyTrident._deathrattle = MonoHelper.getMethod(RustyTrident._class, "Deathrattle", 0)
        }
    }
    
    static func deathrattle() -> MonoHandle {
        let result = mono_runtime_invoke(RustyTrident._deathrattle, nil, nil, nil)
        return MonoHandle(obj: result)
    }
}
