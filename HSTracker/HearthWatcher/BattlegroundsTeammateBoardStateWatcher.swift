//
//  BattlegroundsTeammateBoardStateWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsTeammateBoardStateEntity: Equatable {
    var cardId: String
    var tags: [Int: Int]
    
    init(entity: MirrorBattlegroundsTeammateBoardStateEntity) {
        cardId = entity.cardId
        tags = Dictionary(uniqueKeysWithValues: entity.tags.compactMap { x in (x.key.intValue, x.value.intValue) })
    }
}

struct BattlegroundsTeammateBoardStateArgs: Equatable {
    var isViewingTeammate: Bool
    var mulliganHeroes: [String]
    var entities: [BattlegroundsTeammateBoardStateEntity]
    
    init(boardState: MirrorBattlegroundsTeammateBoardState?) {
        isViewingTeammate = boardState?.viewingTeammate ?? false
        mulliganHeroes = boardState?.mulliganHeroes ?? [String]()
        entities = boardState?.entities.compactMap { be in BattlegroundsTeammateBoardStateEntity(entity: be) } ?? [BattlegroundsTeammateBoardStateEntity]()
    }
}

class BattlegroundsTeammateBoardStateWatcher {
    var change: ((_ sender: BattlegroundsTeammateBoardStateWatcher, _ args: BattlegroundsTeammateBoardStateArgs) -> Void)?
    private let delay: TimeInterval
    private var _running = false
    private var _watch = false
    private var _prev: BattlegroundsTeammateBoardStateArgs?
    internal var queue: DispatchQueue?

    init(delay: TimeInterval = 0.200) {
        self.delay = delay
    }
    
    func run() {
        _watch = true
        if _running {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                Thread.current.name = queue.label
                self?.update()
            }
        }
    }
    
    func stop() {
        _watch = false
    }

    private func update() {
        _running = true
        while _watch {
            Thread.sleep(forTimeInterval: delay)
            if !_watch {
                break
            }
            
            let value = MirrorHelper.getBattlegroundsTeammateBoardState()
            let curr = BattlegroundsTeammateBoardStateArgs(boardState: value)
            if curr == _prev {
                continue
            }
            change?(self, curr)
            _prev = curr
        }
        _prev = nil
        _running = false
    }
}
