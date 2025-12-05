//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class GenericDeathrattles: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _sneedHeroPower: OpaquePointer!
    static var _plants: OpaquePointer!
    static var _earthInvocation: OpaquePointer!
    static var _crab: OpaquePointer!
    static var _crabGolden: OpaquePointer!
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if GenericDeathrattles._class == nil {
            GenericDeathrattles._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "GenericDeathrattleActions")
            mono_class_init(GenericDeathrattles._class)
            _sneedHeroPower = MonoHelper.getField(GenericDeathrattles._class, "SneedHeroPower")
            _plants = MonoHelper.getField(GenericDeathrattles._class, "Plants")
            _earthInvocation = MonoHelper.getField(GenericDeathrattles._class, "EarthInvocationDeathrattle")
            _crab = MonoHelper.getField(GenericDeathrattles._class, "Crab")
            _crabGolden = MonoHelper.getField(GenericDeathrattles._class, "CrabGolden")
        }
    }
    
    static func sneedHeroPower() -> MonoHandle {
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, _sneedHeroPower, nil)
        let result = MonoHandle(obj: obj)
        
        return result
    }
    
    static func plants() -> MonoHandle {
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, _plants, nil)
        let result = MonoHandle(obj: obj)
        
        return result
    }
    
    static func earthInvocation() -> MonoHandle {
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, _earthInvocation, nil)
        let result = MonoHandle(obj: obj)
        
        return result
    }
    
    static func crab() -> MonoHandle {
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, _crab, nil)
        let result = MonoHandle(obj: obj)
        
        return result
    }
    
    static func crabGolden() -> MonoHandle {
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, _crabGolden, nil)
        let result = MonoHandle(obj: obj)

        return result
    }
}
