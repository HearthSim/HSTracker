//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class GenericDeathrattles {
    static var _class: OpaquePointer?
    static var _sneedHeroPower: OpaquePointer!
    static var _plants: OpaquePointer!

    static func _init() {
        if GenericDeathrattles._class == nil {
            GenericDeathrattles._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "GenericDeathrattles")
            mono_class_init(GenericDeathrattles._class)
            _sneedHeroPower = MonoHelper.getField(GenericDeathrattles._class, "SneedHeroPower")
            _plants = MonoHelper.getField(GenericDeathrattles._class, "Plants")
        }
    }
    
    static func sneedHeroPower() -> MonoHandle {
        _init()
        
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, _sneedHeroPower, nil)
        let result = MonoHandle(obj: obj)

        return result
    }

    static func plants() -> MonoHandle {
        _init()
        
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, _plants, nil)
        let result = MonoHandle(obj: obj)

        return result
    }
}
