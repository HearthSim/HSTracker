//
//  CounterManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/23/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

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
        
        let counterTypes = ReflectionHelper.getCounterClasses()
        
        for type in counterTypes {
            let playerCounter = type.init(controlledByPlayer: true, game: game)
            playerCounter.counterChanged = { [weak self] in self?.notifyCountersChanged() }
            playerCounters.append(playerCounter)

            let opponentCounter = type.init(controlledByPlayer: false, game: game)
            opponentCounter.counterChanged = { [weak self] in self?.notifyCountersChanged() }
            opponentCounters.append(opponentCounter)
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
    
    func handleChoicePicked(choice: IHsCompletedChoice) {
        for playerCounter in playerCounters {
            playerCounter.handleChoicePicked(choice: choice)
        }
        
        for opponentCounter in opponentCounters {
            opponentCounter.handleChoicePicked(choice: choice)
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
}
