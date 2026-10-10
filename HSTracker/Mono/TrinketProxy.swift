//
//  TrinketProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/20/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class TrinketProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?
    internal static var _attachEnchantment: OpaquePointer!

    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if TrinketProxy._class == nil {
            TrinketProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Trinkets", name: "Trinket")

            TrinketProxy._attachEnchantment = MonoHelper.getMethod(TrinketProxy._class, "AttachEnchantment", 1)

            initializeProperties(properties: ["CardID", "ScriptDataNum1", "ScriptDataNum2", "ContainerCardId", "game_id", "TrinketUpdatedDuringCombat", "ControlledByPlayer"])
        }
    }

    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }

    @MonoStringProperty(property: "CardID", owner: TrinketProxy.self)
    var cardID: String
    @MonoPrimitiveProperty(property: "ScriptDataNum1", owner: TrinketProxy.self)
    var scriptDataNum1: Int32
    @MonoPrimitiveProperty(property: "ScriptDataNum2", owner: TrinketProxy.self)
    var scriptDataNum2: Int32
    @MonoStringProperty(property: "ContainerCardId", owner: TrinketProxy.self)
    var containerCardId: String
    @MonoPrimitiveProperty(property: "game_id", owner: TrinketProxy.self)
    var game_id: Int32
    @MonoPrimitiveProperty(property: "TrinketUpdatedDuringCombat", owner: TrinketProxy.self)
    var trinketUpdatedDuringCombat: Bool
    @MonoPrimitiveProperty(property: "ControlledByPlayer", owner: TrinketProxy.self)
    var controlledByPlayer: Bool

    func attachEnchantment(enchantment: EnchantmentProxy) {
        let params = UnsafeMutablePointer<UnsafeMutablePointer<MonoObject>>.allocate(capacity: 1)
        params[0] = enchantment.get()!
        _ = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            mono_runtime_invoke(TrinketProxy._attachEnchantment, self.get(), $0, nil)
        })
    }
}

class SoulFermenterProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if SoulFermenterProxy._class == nil {
            SoulFermenterProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Trinkets", name: "SoulFermenter")

            initializeProperties(properties: [ "ExtraSavedMinions" ])
        }
    }

    @MonoHandleProperty(property: "ExtraSavedMinions", owner: SoulFermenterProxy.self)
    var extraSavedMinions: MonoHandle
}
