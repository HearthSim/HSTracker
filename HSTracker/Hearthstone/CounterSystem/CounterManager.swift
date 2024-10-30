//
//  CounterManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/23/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol DynamicCounter {
    init(controlledByPlayer: Bool, game: Game)
}

class CounterManager {
    private var game: Game!
    private(set) var playerCounters: [BaseCounter] = []
    private(set) var opponentCounters: [BaseCounter] = []

    typealias CountersChangedListener = (() -> Void)
    private var countersChanged = [CountersChangedListener]()

    init() {
    }

    func initialize(game: Game) {
        self.game = game
        
        let counterTypes = getCounterTypes()
        
        for type in counterTypes {
            if let playerCounter = type.init(controlledByPlayer: true, game: game) as? BaseCounter {
                playerCounter.counterChanged = { [weak self] in self?.notifyCountersChanged() }
                playerCounters.append(playerCounter)
            }

            if let opponentCounter = type.init(controlledByPlayer: false, game: game) as? BaseCounter {
                opponentCounter.counterChanged = { [weak self] in self?.notifyCountersChanged() }
                opponentCounters.append(opponentCounter)
            }
        }
    }

    func getVisibleCounters(controlledByPlayer: Bool) -> [BaseCounter] {
        let counters = controlledByPlayer ? playerCounters : opponentCounters
        return counters.filter { $0.shouldShow() }
    }

    func getExampleCounters(controlledByPlayer: Bool) -> [BaseCounter] {
        let counters = controlledByPlayer ? playerCounters : opponentCounters
        return Array(counters.prefix(3))
    }

    func handleTagChange(tag: GameTag, id: Int, value: Int, prevValue: Int) {
        guard let entity = game.entities[id] else { return }

        for playerCounter in playerCounters {
            playerCounter.handleTagChange(tag: tag, entity: entity, value: value, prevValue: prevValue)
        }

        for opponentCounter in opponentCounters {
            opponentCounter.handleTagChange(tag: tag, entity: entity, value: value, prevValue: prevValue)
        }
    }

    func reset() {
        for counter in playerCounters {
            counter.counterChanged = nil
        }
        for counter in opponentCounters {
            counter.counterChanged = nil
        }
        playerCounters.removeAll()
        opponentCounters.removeAll()
        initialize(game: game)
        notifyCountersChanged()
    }
    
    func addCountersChangedListener(_ listener: @escaping CountersChangedListener) {
        countersChanged.append(listener)
    }

    private func notifyCountersChanged() {
        for listener in countersChanged {
            listener()
        }
    }
    
    private var _counterTypes: [DynamicCounter.Type]?
    
    private func getCounterTypes() -> [DynamicCounter.Type] {
        if let _counterTypes {
            return _counterTypes
        }
        let counterTypes: [DynamicCounter.Type] = MonoHelper.withAllClasses({ x in x.compactMap { c in
            if let t = c as? DynamicCounter.Type {
                let s = String(cString: class_getName(c))
                if s != "HSTracker.BaseCounter" && s != "HSTracker.NumericCounter" && s != "HSTracker.StatsCounter" {
                    return t
                }
            }
            return nil
        }})
        _counterTypes = counterTypes
        return counterTypes
    }
}
