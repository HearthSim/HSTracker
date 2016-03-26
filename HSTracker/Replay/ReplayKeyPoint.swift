//
//  ReplayKeyPoint.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

func deepClone(data: [Entity]) -> [Entity] {
    var copy = [Entity]()
    data.forEach({ copy.append($0.copy()) })
    return copy
}

final class ReplayKeyPoint: Equatable, Dictable  {
    var data: [Entity]
    var id: Int
    var player: PlayerType
    var type: KeyPointType

    init(data: [Entity]?, type: KeyPointType, id: Int, player: PlayerType) {
        if data != nil {
            self.data = deepClone(data!)
        } else {
            self.data = [Entity]()
        }
        self.type = type
        self.id = id
        self.player = player
    }

    var turn: Int {
        if let entity = data.first {
            return entity.getTag(.TURN)
        }
        return 0
    }

    func getCardId() -> String? {
        var tag: Int = 0
        if let entity = data.first {
            tag = entity.getTag(.PROPOSED_ATTACKER)
        }
        let id = type == KeyPointType.Attack ? tag : self.id
        return data.firstWhere { $0.id == id }?.cardId
    }

    func getAdditionalInfo() -> String {
        if type == KeyPointType.Victory || type == KeyPointType.Defeat {
            return type.rawValue
        }
        return String.isNullOrEmpty(getCardId()) ? "Entity \(id)" : Cards.byId(getCardId()!)!.name
    }
    
    func toDict() -> [String: AnyObject] {
        return [
            "id": self.id,
            "player": self.player.rawValue,
            "type": self.type.rawValue,
            "turn": self.turn,
            "data": self.data.toDict()
        ]
    }
}
func == (lhs: ReplayKeyPoint, rhs: ReplayKeyPoint) -> Bool {
    return lhs.id == rhs.id
}
