//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class SandyProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if SandyProxy._class == nil {
            SandyProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Minions.Duos", name: "Sandy")
            
            initializeProperties(properties: ["AttachedMinion"])
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoHandleProperty(property: "AttachedMinion", owner: MinionProxy.self)
    var attachedMinion: MinionProxy
}
