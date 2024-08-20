//
//  TrinketProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/20/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrinketProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if TrinketProxy._class == nil {
            TrinketProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Trinkets", name: "Trinket")
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
}
