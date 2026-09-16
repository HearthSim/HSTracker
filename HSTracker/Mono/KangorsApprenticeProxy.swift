//
//  KangorsApprenticeProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

class KangorsApprenticeProxy: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _members = [String: OpaquePointer]()

    static func initialize() {
        if KangorsApprenticeProxy._class == nil {
            KangorsApprenticeProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Minions.Neutral", name: "KangorsApprentice")
        }
    }
}
