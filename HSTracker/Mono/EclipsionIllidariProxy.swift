//
//  EclipsionIllidariProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

class EclipsionIllidariProxy: MonoHandle, MonoClassInitializer {
    internal static var _class: OpaquePointer?

    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if EclipsionIllidariProxy._class == nil {
            EclipsionIllidariProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Minions.Buddy", name: "EclipsionIllidari")

            initializeProperties(properties: [ "ScoreValue2" ])
        }
    }

    required init(obj: UnsafeMutablePointer<MonoObject>?) {
        super.init(obj: obj)
    }

    // int? on the simulator side, so it is carried as a boxed value like Player.MagnetizeCounter.
    @MonoHandleProperty(property: "ScoreValue2", owner: EclipsionIllidariProxy.self)
    var scoreValue2: MonoHandle
}
