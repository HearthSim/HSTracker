//
//  TimewarpedMagnanimooseEnchantmentProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

class TimewarpedMagnanimooseEnchantmentProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if TimewarpedMagnanimooseEnchantmentProxy._class == nil {
            TimewarpedMagnanimooseEnchantmentProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Enchantments", name: "TimewarpedMagnanimooseEnchantment")
            
            initializeProperties(properties: [ "SummonedMinions" ])
        }
    }
    
    @MonoHandleProperty(property: "SummonedMinions", owner: TimewarpedMagnanimooseEnchantmentProxy.self)
    var summonedMinions: MonoHandle
}

class TimewarpedNelliesShipEnchantmentProxy: MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if TimewarpedNelliesShipEnchantmentProxy._class == nil {
            TimewarpedNelliesShipEnchantmentProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Enchantments", name: "TimewarpedNelliesShipEnchantment")
        }
    }
}
