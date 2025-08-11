//
//  QuestDataProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/30/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class QuestDataProxy: MonoHandle, MonoClassInitializer {
    static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if QuestDataProxy._class == nil {
            QuestDataProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "QuestData")
            
            initializeProperties(properties: ["QuestCardId", "RewardCardId", "QuestProgress", "QuestProgressTotal", "RewardScriptDataNum1", "RewardScriptDataNum2"])
        }
    }
    
    override init() {
        super.init()
        
        let obj = MonoHelper.objectNew(clazz: QuestDataProxy._class!)
        set(obj: obj)
        
        let inst = self.get()
        
        mono_runtime_object_init(inst)
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        fatalError("init(obj:) has not been implemented")
    }
    
    @MonoStringProperty(property: "QuestCardId", owner: QuestDataProxy.self)
    var questCardId: String
    
    @MonoStringProperty(property: "RewardCardId", owner: QuestDataProxy.self)
    var rewardCardId: String
    
    @MonoPrimitiveProperty(property: "QuestProgress", owner: QuestDataProxy.self)
    var questProgress: Int32
    
    @MonoPrimitiveProperty(property: "QuestProgressTotal", owner: QuestDataProxy.self)
    var questProgressTotal: Int32
    
    @MonoPrimitiveProperty(property: "RewardScriptDataNum1", owner: QuestDataProxy.self)
    var rewardScriptDataNum1: Int32
    
    @MonoPrimitiveProperty(property: "RewardScriptDataNum2", owner: QuestDataProxy.self)
    var rewardScriptDataNum2: Int32
}
