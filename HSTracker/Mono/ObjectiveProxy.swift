//
//  ObjectiveProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class ObjectiveProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if ObjectiveProxy._class == nil {
            ObjectiveProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Spells", name: "Objective")
            initializeProperties(properties: ["ScriptDataNum1", "ScriptDataNum2", "ScriptDataNum3"])

        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoPrimitiveProperty(property: "ScriptDataNum1", owner: ObjectiveProxy.self)
    var scriptDataNum1: Int32
    @MonoPrimitiveProperty(property: "ScriptDataNum2", owner: ObjectiveProxy.self)
    var scriptDataNum2: Int32
    @MonoPrimitiveProperty(property: "ScriptDataNum3", owner: ObjectiveProxy.self)
    var scriptDataNum3: Int32

    /// Sets `IOnAttachedMinion.AttachedMinion`, which only some objectives implement -
    /// the Deity Sigil being the one this is here for. HDT tests the interface with
    /// `is IOnAttachedMinion`; the property is looked up on the objective's own runtime
    /// class here instead, since the proxy is bound to the abstract Objective base and
    /// an objective without the interface simply has no such property.
    ///
    /// Returns whether the objective took it.
    @discardableResult
    func setAttachedMinion(_ minion: MinionProxy) -> Bool {
        guard let inst = get() else {
            return false
        }
        guard let property = mono_class_get_property_from_name(mono_object_get_class(inst), "AttachedMinion") else {
            return false
        }
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        defer { params.deallocate() }
        params[0] = UnsafeMutableRawPointer(minion.get())
        mono_property_set_value(property, inst, params, nil)
        return true
    }
}
