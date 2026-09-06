//
//  CounterManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/23/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

// The counter lists are rebuilt from the log reader queue (reset() runs off
// gameStart/handleEndGame) while the main thread reads them to refresh the
// counters overlay, so every access goes through `lock`. The public
// playerCounters/opponentCounters return a snapshot taken under the lock:
// filtering a plain stored array while another thread was appending to it is
// what trapped in Array._checkSubscript.
class CounterManager {
    private var game: Game!

    private let lock = UnfairLock()
    private var _playerCounters: [BaseCounter] = []
    private var _opponentCounters: [BaseCounter] = []

    var playerCounters: [BaseCounter] { lock.around { _playerCounters } }
    var opponentCounters: [BaseCounter] { lock.around { _opponentCounters } }

    typealias CountersChangedListener = (() -> Void)
    private var countersChanged = [CountersChangedListener]()

    init() {
    }

    func initialize(game: Game) {
        self.game = game

        let counterTypes = ReflectionHelper.getCounterClasses()

        var playerCounters = [BaseCounter]()
        var opponentCounters = [BaseCounter]()

        for type in counterTypes {
            let playerCounter = type.init(controlledByPlayer: true, game: game)
            playerCounter.counterChanged = { [weak self] in self?.notifyCountersChanged() }
            playerCounters.append(playerCounter)

            let opponentCounter = type.init(controlledByPlayer: false, game: game)
            opponentCounter.counterChanged = { [weak self] in self?.notifyCountersChanged() }
            opponentCounters.append(opponentCounter)
        }

        // Swapped in as a whole so readers never see a partially built list.
        lock.around {
            _playerCounters = playerCounters
            _opponentCounters = opponentCounters
        }
    }

    func getVisibleCounters(controlledByPlayer: Bool) -> [BaseCounter] {
        let counters = controlledByPlayer ? playerCounters : opponentCounters
        return counters.filter { $0.shouldShow() || $0.mirrorsPlayerDeckKnowledge }
    }

    func getExampleCounters(controlledByPlayer: Bool) -> [BaseCounter] {
        let counters = controlledByPlayer ? playerCounters : opponentCounters
        return Array(counters.prefix(3))
    }

    func handleTagChange(tag: GameTag, id: Int, value: Int, prevValue: Int) {
        guard let entity = game.entities[id] else { return }

        let isBattlegroundsMatch = game.isBattlegroundsMatch()
        let isTraditionalHearthstoneMatch = game.isTraditionalHearthstoneMatch
        guard isBattlegroundsMatch || isTraditionalHearthstoneMatch else { return }

        for playerCounter in playerCounters {
            if playerCounter.isBattlegroundsCounter != isBattlegroundsMatch { continue }
            playerCounter.handleTagChange(tag: tag, entity: entity, value: value, prevValue: prevValue)
        }

        for opponentCounter in opponentCounters {
            if opponentCounter.isBattlegroundsCounter != isBattlegroundsMatch { continue }
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
        let discarded = playerCounters + opponentCounters

        initialize(game: game)

        // BaseCounter.onCounterChanged reads counterChanged on the main queue,
        // so unhooking the counters we just dropped has to happen there too.
        // They are unreachable by now, and a last notification from one before
        // it is unhooked only re-reads the new lists.
        DispatchQueue.main.async {
            for counter in discarded {
                counter.counterChanged = nil
            }
        }

        notifyCountersChanged()
    }
    
    func addCountersChangedListener(_ listener: @escaping CountersChangedListener) {
        lock.around {
            countersChanged.append(listener)
        }
    }

    private func notifyCountersChanged() {
        let listeners = lock.around { countersChanged }
        for listener in listeners {
            listener()
        }
    }
}
