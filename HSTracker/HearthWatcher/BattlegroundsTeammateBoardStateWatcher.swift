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

class BattlegroundsTeammateBoardStateWatcher: Watcher {
    var change: ((_ sender: BattlegroundsTeammateBoardStateWatcher, _ args: BattlegroundsTeammateBoardStateArgs) -> Void)?
    private var _prev: BattlegroundsTeammateBoardStateArgs?

    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let value = MirrorHelper.getBattlegroundsTeammateBoardState()
        let curr = BattlegroundsTeammateBoardStateArgs(boardState: value)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
