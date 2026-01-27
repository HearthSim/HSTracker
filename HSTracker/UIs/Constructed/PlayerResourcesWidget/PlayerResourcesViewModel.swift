//
//  PlayerResourcesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

@available(macOS 10.15, *)
class PlayerResourcesViewModel: ObservableObject {
    
    struct Resource: Equatable {
        var icon: String
        var value: Int
    }
        
    private var _initialMaxHealth = 0
    private var _initialMaxMana = 0
    private var _initialMaxHandSize = 0

    private var _healthChanged = false
    private var _manaChanged = false
    private var _handSizeChanged = false
    private var _corpsesChanged = false
    
    @Published var resources: [Resource] = []
    
    @Published var visibility = false
    
    public var hasVisibleResources: Bool {
        return resources.count > 0
    }
    
    init() {
        
    }
    
    func initialize(_ maxHealth: Int, _ maxMana: Int, _ maxHandSize: Int) {
        _initialMaxHealth = maxHealth
        _initialMaxMana = maxMana
        _initialMaxHandSize  = maxHandSize
        
        _healthChanged = false
        _manaChanged = false
        _handSizeChanged = false
        _corpsesChanged = false
    }
    
    func updatePlayerResourcesWidget(_ maxHealth: Int, _ maxMana: Int, _ maxHandSize: Int, _ corpsesLeft: Int? = nil) {
        _healthChanged = _healthChanged || (maxHealth != _initialMaxHealth)
        _manaChanged = _manaChanged || (maxMana != _initialMaxMana)
        _handSizeChanged = _handSizeChanged || (maxHandSize != _initialMaxHandSize)
        _corpsesChanged = corpsesLeft != nil
        
        var updated = [Resource]()
        
        if _healthChanged {
            updated.append(Resource(icon: "health", value: maxHealth))
        }
        
        if _manaChanged {
            updated.append(Resource(icon: "mana", value: maxMana))
        }
        
        if _handSizeChanged {
            updated.append(Resource(icon: "card-icon-drawn", value: maxHandSize))
        }
        
        if _corpsesChanged, let corpsesLeft {
            updated.append(Resource(icon: "corpses", value: corpsesLeft))
        }
        
        resources = updated
    }
}

@available(macOS 10.15, *)
extension PlayerResourcesViewModel.Resource: Identifiable {
    var id: String {
        icon
    }
}
