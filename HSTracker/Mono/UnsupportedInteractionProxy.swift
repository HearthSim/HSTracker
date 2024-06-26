//
//  UnsupportedInteractionProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/27/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class UnsupportedInteractionExceptionProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if UnsupportedInteractionExceptionProxy._class == nil {
            UnsupportedInteractionExceptionProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "UnsupportedInteractionException")
            
            initializeProperties(properties: [ "Entity", "Message" ])
        }
    }

    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoStringProperty(property: "Message", owner: UnsupportedInteractionExceptionProxy.self)
    var message: String
    
    @MonoHandleProperty(property: "Entity", owner: UnsupportedInteractionExceptionProxy.self)
    var entity: EntityProxy
}
