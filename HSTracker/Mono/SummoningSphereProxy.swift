//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class SummoningSphereProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if SummoningSphereProxy._class == nil {
            SummoningSphereProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Trinkets", name: "SummoningSphere")
            
            initializeProperties(properties: ["AttachedMinion"])
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoHandleProperty(property: "AttachedMinion", owner: SummoningSphereProxy.self)
    var attachedMinion: MinionProxy
}
