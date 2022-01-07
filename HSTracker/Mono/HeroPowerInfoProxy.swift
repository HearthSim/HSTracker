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

class HeroPowerInfoProxy: MonoHandle {
    static var _class: OpaquePointer?
    
    static var _playerActivatedPower: OpaquePointer!
    static var _opponentActivatedPower: OpaquePointer!

    override init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)

        if HeroPowerInfoProxy._class == nil {
            HeroPowerInfoProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "HeroPowerInfo")
            
            HeroPowerInfoProxy._playerActivatedPower = MonoHelper.getMethod(HeroPowerInfoProxy._class, "get_PlayerActivatedPower", 0)
            HeroPowerInfoProxy._opponentActivatedPower = MonoHelper.getMethod(HeroPowerInfoProxy._class, "get_OpponentActivatedPower", 0)
        }

    }
    
    func playerActivatedPower() -> HeroPowerEnum {
        return HeroPowerEnum(rawValue: Int(MonoHelper.getInt(obj: self, method: HeroPowerInfoProxy._playerActivatedPower))) ?? .none
    }

    func opponentActivatedPower() -> HeroPowerEnum {
        return HeroPowerEnum(rawValue: Int(MonoHelper.getInt(obj: self, method: HeroPowerInfoProxy._opponentActivatedPower))) ?? .none
    }
}
