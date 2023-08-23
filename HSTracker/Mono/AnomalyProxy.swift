//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class AnomalyProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?
    
    static var _members = [String: OpaquePointer]()
    
    static func initialize() {
        if AnomalyProxy._class == nil {
            AnomalyProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Anomalies", name: "Anomaly")
        }
    }
    
    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }
}
