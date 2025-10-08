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
    
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if HeroPowerDataProxy._class == nil {
            HeroPowerDataProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "HeroPowerData")
            
            initializeProperties(properties: ["CardId", "IsActivated", "Data"])
        }
    }

    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
    
    @MonoStringProperty(property: "CardId", owner: HeroPowerDataProxy.self)
    var cardId: String

    @MonoPrimitiveProperty(property: "IsActivated", owner: HeroPowerDataProxy.self)
    var isActivated: Bool

    @MonoPrimitiveProperty(property: "Data", owner: HeroPowerDataProxy.self)
    var data: Int32
    
    @MonoHandleProperty(property: "AttachedMinion", owner: HeroPowerDataProxy.self)
    var attachedMinion: MinionProxy
}
