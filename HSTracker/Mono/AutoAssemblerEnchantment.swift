//
//  AutoAssembler 2.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class AutoAssemblerEnchantmentProxy: MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if AutoAssemblerEnchantmentProxy._class == nil {
            AutoAssemblerEnchantmentProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Enchantments", name: "AutoAssemblerEnchantment")
        }
    }
}

class AutoAssemblerEnchantmentGoldenProxy: MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if AutoAssemblerEnchantmentGoldenProxy._class == nil {
            AutoAssemblerEnchantmentGoldenProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Enchantments", name: "AutoAssemblerEnchantmentGolden")
        }
    }
}
