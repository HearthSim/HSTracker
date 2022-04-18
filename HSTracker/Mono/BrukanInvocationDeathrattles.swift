//
//  TestInputProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/11/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class BrukanInvocationDeathrattles: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _earth: OpaquePointer!
    static var _fire: OpaquePointer!
    static var _water: OpaquePointer!
    static var _lightning: OpaquePointer!

    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if BrukanInvocationDeathrattles._class == nil {
            BrukanInvocationDeathrattles._class = MonoHelper.loadClass(ns: "BobsBuddy", name: "BrukanInvocationDeathrattleActions")
            mono_class_init(BrukanInvocationDeathrattles._class)
            _earth = MonoHelper.getField(BrukanInvocationDeathrattles._class, "Earth")
            _fire = MonoHelper.getField(BrukanInvocationDeathrattles._class, "Fire")
            _water = MonoHelper.getField(BrukanInvocationDeathrattles._class, "Water")
            _lightning = MonoHelper.getField(BrukanInvocationDeathrattles._class, "Lightning")
        }
    }
    
    static func earth() -> MonoHandle {
        let obj = MonoHandle()
        
        return MonoHelper.getField(obj: obj, field: _earth)
    }

    static func fire() -> MonoHandle {
        let obj = MonoHandle()

        return MonoHelper.getField(obj: obj, field: _fire)
    }

    static func water() -> MonoHandle {
        let obj = MonoHandle()

        return MonoHelper.getField(obj: obj, field: _water)
    }

    static func lightning() -> MonoHandle {
        let obj = MonoHandle()

        return MonoHelper.getField(obj: obj, field: _lightning)
    }
}
