//
//  EntityProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/27/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class EntityProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if EntityProxy._class == nil {
            EntityProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "Entity")
            
            initializeProperties(properties: [ "CardID" ])
        }
    }

    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoStringProperty(property: "CardID", owner: EntityProxy.self)
    var cardID: String
}
