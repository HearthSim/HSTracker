//
//  ObjectiveProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class ObjectiveProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if ObjectiveProxy._class == nil {
            ObjectiveProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Spells", name: "Objective")
            initializeProperties(properties: ["ScriptDataNum1"])

        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoPrimitiveProperty(property: "ScriptDataNum1", owner: ObjectiveProxy.self)
    var scriptDataNum1: Int32
}
