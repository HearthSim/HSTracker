//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class MinionProxy: MonoHandle {
    private static var _class: OpaquePointer?
    private static var _setBaseAttack: OpaquePointer!
    private static var _setBaseHealth: OpaquePointer!
    private static var _setTaunt: OpaquePointer!
    private static var _setDiv: OpaquePointer!
    private static var _setCleave: OpaquePointer!
    private static var _setPoisonous: OpaquePointer!
    private static var _setWindfury: OpaquePointer!
    private static var _setMegaWindfury: OpaquePointer!
    private static var _setGolden: OpaquePointer!
    private static var _tier: OpaquePointer!
    private static var _setReborn: OpaquePointer!
    private static var _getVanillaHealth: OpaquePointer!
    private static var _setVanillaHealth: OpaquePointer!
    private static var _getVanillaAttack: OpaquePointer!
    private static var _setVanillaAttack: OpaquePointer!
    private static var _setReceivesLichKingPower: OpaquePointer!
    private static var _getReceivesLichKingPower: OpaquePointer!
    private static var _getGameId: OpaquePointer!
    private static var _setGameId: OpaquePointer!
    private static var _minionName: OpaquePointer!

    override init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
        
        if MinionProxy._class == nil {
            MinionProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "Minion")
            MinionProxy._setBaseAttack = MonoHelper.getMethod(MinionProxy._class, "set_baseAttack", 1)
            MinionProxy._setBaseHealth = MonoHelper.getMethod(MinionProxy._class, "set_baseHealth", 1)
            MinionProxy._setTaunt = MonoHelper.getMethod(MinionProxy._class, "set_taunt", 1)
            MinionProxy._setDiv = MonoHelper.getMethod(MinionProxy._class, "set_div", 1)
            MinionProxy._setCleave = MonoHelper.getMethod(MinionProxy._class, "set_cleave", 1)
            MinionProxy._setPoisonous = MonoHelper.getMethod(MinionProxy._class, "set_poisonous", 1)
            MinionProxy._setWindfury = MonoHelper.getMethod(MinionProxy._class, "set_windfury", 1)
            MinionProxy._setMegaWindfury = MonoHelper.getMethod(MinionProxy._class, "set_megaWindfury", 1)
            MinionProxy._setGolden = MonoHelper.getMethod(MinionProxy._class, "set_golden", 1)
            MinionProxy._tier = MonoHelper.getField(MinionProxy._class, "tier")
            MinionProxy._setReborn = MonoHelper.getMethod(MinionProxy._class, "set_reborn", 1)
            MinionProxy._getVanillaHealth = MonoHelper.getMethod(MinionProxy._class, "get_vanillaHealth", 0)
            MinionProxy._setVanillaHealth = MonoHelper.getMethod(MinionProxy._class, "set_vanillaHealth", 1)
            MinionProxy._getVanillaAttack = MonoHelper.getMethod(MinionProxy._class, "get_vanillaAttack", 0)
            MinionProxy._setVanillaAttack = MonoHelper.getMethod(MinionProxy._class, "set_vanillaAttack", 1)
            MinionProxy._setReceivesLichKingPower = MonoHelper.getMethod(MinionProxy._class, "set_receivesLichKingPower", 1)
            MinionProxy._getReceivesLichKingPower = MonoHelper.getMethod(MinionProxy._class, "get_receivesLichKingPower", 0)
            MinionProxy._getGameId = MonoHelper.getMethod(MinionProxy._class, "get_game_id", 0)
            MinionProxy._setGameId = MonoHelper.getMethod(MinionProxy._class, "set_game_id", 1)
            MinionProxy._minionName = MonoHelper.getField(MinionProxy._class, "minionName")
        }
    }    

    func setBaseAttack(attack: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setBaseAttack, value: attack)
    }

    func setBaseHealth(health: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setBaseHealth, value: health)
    }

    func setTaunt(taunt: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setTaunt, value: taunt)
    }

    func setDiv(div: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setDiv, value: div)
    }
    
    func setCleave(cleave: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setCleave, value: cleave)
    }
    
    func setPoisonous(poisonous: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setPoisonous, value: poisonous)
    }
    
    func setWindfury(windfury: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setWindfury, value: windfury)
    }
    
    func setMegaWindfury(megaWindfury: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setMegaWindfury, value: megaWindfury)
    }

    func setGolden(golden: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setGolden, value: golden)
    }
    
    func setTier(tier: Int32) {
        MonoHelper.setIntField(obj: self, field: MinionProxy._tier, value: tier)
    }
    
    func setReborn(reborn: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setReborn, value: reborn)
    }
    
    func setVanillaHealth(health: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setVanillaHealth, value: health)
    }
    
    func getVanillaHealth() -> Int32 {
        return MonoHelper.getInt(obj: self, method: MinionProxy._getVanillaHealth)
    }
    
    func setVanillaAttack(attack: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setVanillaAttack, value: attack)
    }
    
    func getVanillaAttack() -> Int32 {
        return MonoHelper.getInt(obj: self, method: MinionProxy._getVanillaAttack)
    }

    func setReceivesLichKingPower(power: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setReceivesLichKingPower, value: power)
    }
    
    func getReceivesLichKingPower() -> Bool {
        return MonoHelper.getBool(obj: self, method: MinionProxy._getReceivesLichKingPower)
    }
    
    func getGameId() -> Int32 {
        return MonoHelper.getInt(obj: self, method: MinionProxy._getGameId)
    }
    
    func setGameId(id: Int32) {
        return MonoHelper.setInt(obj: self, method: MinionProxy._setGameId, value: id)
    }

    func getMinionName() -> String {
        return MonoHelper.getStringField(obj: self, field: MinionProxy._minionName)
    }

    func addDeathrattle(deathrattle: MonoHandle) {
        let field = mono_class_get_field_from_name(MinionProxy._class, "AdditionalDeathrattles")
        let inst = get()
        let obj = mono_field_get_value_object(MonoHelper._monoInstance, field, inst)
        
        let clazz = mono_object_get_class(obj)
        let method = mono_class_get_method_from_name(clazz, "Add", 1)
        
        let params = UnsafeMutablePointer<UnsafeMutablePointer<MonoObject>>.allocate(capacity: 1)

        params[0] = deathrattle.get()!
            
        _ = params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1, {
            mono_runtime_invoke(method, obj, $0, nil)
        })
        params.deallocate()
    }
}
