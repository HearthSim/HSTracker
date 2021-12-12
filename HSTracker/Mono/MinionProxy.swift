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
    private static var _setMechDeathCount: OpaquePointer!
    private static var _setMechDeathCountGold: OpaquePointer!
    private static var _setPlantDeathCount: OpaquePointer!
    private static var _setReceivesLichKingPower: OpaquePointer!
    private static var _getReceivesLichKingPower: OpaquePointer!
    private static var _getGameId: OpaquePointer!
    private static var _setGameId: OpaquePointer!
    private static var _minionName: OpaquePointer!
    private static var _addToBackOfList: OpaquePointer!
    private static var _setSneedsHeroPowerCount: OpaquePointer!

    override init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
        
        if MinionProxy._class == nil {
            MinionProxy._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "Minion")
            MinionProxy._setBaseAttack = mono_class_get_method_from_name(MinionProxy._class, "set_baseAttack", 1)
            MinionProxy._setBaseHealth = mono_class_get_method_from_name(MinionProxy._class, "set_baseHealth", 1)
            MinionProxy._setTaunt = mono_class_get_method_from_name(MinionProxy._class, "set_taunt", 1)
            MinionProxy._setDiv = mono_class_get_method_from_name(MinionProxy._class, "set_div", 1)
            MinionProxy._setCleave = mono_class_get_method_from_name(MinionProxy._class, "set_cleave", 1)
            MinionProxy._setPoisonous = mono_class_get_method_from_name(MinionProxy._class, "set_poisonous", 1)
            MinionProxy._setWindfury = mono_class_get_method_from_name(MinionProxy._class, "set_windfury", 1)
            MinionProxy._setMegaWindfury = mono_class_get_method_from_name(MinionProxy._class, "set_megaWindfury", 1)
            MinionProxy._setGolden = mono_class_get_method_from_name(MinionProxy._class, "set_golden", 1)
            MinionProxy._tier = mono_class_get_field_from_name(MinionProxy._class, "tier")
            MinionProxy._setReborn = mono_class_get_method_from_name(MinionProxy._class, "set_reborn", 1)
            MinionProxy._getVanillaHealth = mono_class_get_method_from_name(MinionProxy._class, "get_vanillaHealth", 0)
            MinionProxy._setVanillaHealth = mono_class_get_method_from_name(MinionProxy._class, "set_vanillaHealth", 1)
            MinionProxy._setMechDeathCount = mono_class_get_method_from_name(MinionProxy._class, "set_mechDeathCount", 1)
            MinionProxy._setMechDeathCountGold = mono_class_get_method_from_name(MinionProxy._class, "set_mechDeathCountGold", 1)
            MinionProxy._setPlantDeathCount = mono_class_get_method_from_name(MinionProxy._class, "set_plantDeathCount", 1)
            MinionProxy._setReceivesLichKingPower = mono_class_get_method_from_name(MinionProxy._class, "set_receivesLichKingPower", 1)
            MinionProxy._getReceivesLichKingPower = mono_class_get_method_from_name(MinionProxy._class, "get_receivesLichKingPower", 0)
            MinionProxy._getGameId = mono_class_get_method_from_name(MinionProxy._class, "get_game_id", 0)
            MinionProxy._setGameId = mono_class_get_method_from_name(MinionProxy._class, "set_game_id", 1)
            MinionProxy._minionName = mono_class_get_field_from_name(MinionProxy._class, "minionName")
            MinionProxy._addToBackOfList = mono_class_get_method_from_name(MinionProxy._class, "AddToBackOfList", 2)
            MinionProxy._setSneedsHeroPowerCount = mono_class_get_method_from_name(MinionProxy._class, "set_SneedsHeroPowerCount", 1)
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
    
    func setMechDeathCount(count: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setMechDeathCount, value: count)
    }
    
    func setMechDeathCountGold(count: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setMechDeathCountGold, value: count)
    }

    func setPlantDeathCount(count: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setPlantDeathCount, value: count)
    }

    func setReceivesLichKingPower(power: Bool) {
        MonoHelper.setBool(obj: self, method: MinionProxy._setReceivesLichKingPower, value: power)
    }
    
    func setSneedsHeroCount(count: Int32) {
        MonoHelper.setInt(obj: self, method: MinionProxy._setSneedsHeroPowerCount, value: count)
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

    func addToBackOfList(list: MonoHandle, sim: SimulatorProxy) {
        let params = UnsafeMutablePointer<OpaquePointer>.allocate(capacity: 2)
        
        params[0] = OpaquePointer(list.get()!)
        params[1] = OpaquePointer(sim.get()!)
        
        params.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 2, {
            let me = self.get()
            mono_runtime_invoke(MinionProxy._addToBackOfList, me, $0, nil)
        })
        params.deallocate()
    }
}
