//
//  HoggyBank.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ICopiesDeathrattlesProxy: MonoClassInitializer {
    static var _class: OpaquePointer?
    static var _members =  [String: OpaquePointer]()    

    static func initialize() {
        if ICopiesDeathrattlesProxy._class == nil {
            ICopiesDeathrattlesProxy._class = MonoHelper.loadClass(ns: "BobsBuddy.Simulation", name: "ICopiesDeathrattles")
        }
    }
}
