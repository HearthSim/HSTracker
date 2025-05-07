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
            initializeProperties(properties: ["ScriptDataNum1", "ScriptDataNum2"])
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoPrimitiveProperty(property: "ScriptDataNum1", owner: TrinketProxy.self)
    var scriptDataNum1: Int32
    @MonoPrimitiveProperty(property: "ScriptDataNum2", owner: TrinketProxy.self)
    var scriptDataNum2: Int32}
