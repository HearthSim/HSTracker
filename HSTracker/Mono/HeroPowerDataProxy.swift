//
//  HeroPowerInfoProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/6/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

enum HeroPowerEnum: Int {
    case none = 0,
    deathwing = 1,
    ragnaros = 2,
    nefarian = 3,
    patches = 4,
    lichKing = 5,
    yShaarj = 6,
    roame = 7
}

class HeroPowerDataProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _get_cardId: OpaquePointer!
    static var _set_cardId: OpaquePointer!
    static var _get_isActivated: OpaquePointer!
    static var _set_isActivated: OpaquePointer!
    static var _get_data: OpaquePointer!
    static var _set_data: OpaquePointer!

    static func initialize() {
        if HeroPowerDataProxy._class == nil {
            HeroPowerDataProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "HeroPowerData")
            
            HeroPowerDataProxy._get_cardId = MonoHelper.getMethod(HeroPowerDataProxy._class, "get_CardId", 0)
            HeroPowerDataProxy._set_cardId = MonoHelper.getMethod(HeroPowerDataProxy._class, "set_CardId", 1)
            HeroPowerDataProxy._get_isActivated = MonoHelper.getMethod(HeroPowerDataProxy._class, "get_IsActivated", 0)
            HeroPowerDataProxy._set_isActivated = MonoHelper.getMethod(HeroPowerDataProxy._class, "set_IsActivated", 1)
            HeroPowerDataProxy._get_data = MonoHelper.getMethod(HeroPowerDataProxy._class, "get_Data", 0)
            HeroPowerDataProxy._set_data = MonoHelper.getMethod(HeroPowerDataProxy._class, "set_Data", 1)
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    func cardId() -> String {
        return MonoHelper.getString(obj: self, method: HeroPowerDataProxy._get_cardId)
    }
    
    func setCardId(value: String) {
        MonoHelper.setString(obj: self, method: HeroPowerDataProxy._set_cardId, value: value)
    }

    func isActivated() -> Bool {
        return MonoHelper.getBool(obj: self, method: HeroPowerDataProxy._get_isActivated)
    }

    func setIsActivated(value: Bool) {
        MonoHelper.setBool(obj: self, method: HeroPowerDataProxy._set_isActivated, value: value)
    }

    func setData(value: Int32) {
        MonoHelper.setInt(obj: self, method: HeroPowerDataProxy._set_data, value: value)
    }
}
