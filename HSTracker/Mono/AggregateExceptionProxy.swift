//
//  AggregateExceptionProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/27/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class AggregateExceptionProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if AggregateExceptionProxy._class == nil {
            let corlib = mono_get_corlib()
            if let cl = mono_class_from_name(corlib, "System", "AggregateException") {
                AggregateExceptionProxy._class = cl
                
                initializeProperties(properties: [ "InnerException", "Message" ])
            } else {
                fatalError("Failed to load AggregateException")
            }
        }
    }

    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoStringProperty(property: "Message", owner: AggregateExceptionProxy.self)
    var message: String
    
    @MonoHandleProperty(property: "InnerException", owner: AggregateExceptionProxy.self)
    var innerException: MonoHandle
}
