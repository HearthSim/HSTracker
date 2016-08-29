//
//  ReplayKeyPoint.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

final class ReplayKeyPoint: Equatable {
    var data: [Entity]
    var id: Int
    var player: PlayerType
    var type: KeyPointType

    init(data: [Entity]?, type: KeyPointType, id: Int, player: PlayerType) {
        if let data = data {
            self.data = data.map { $0.copy() }
        } else {
            self.data = []
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
}

extension ReplayKeyPoint: WrapCustomizable {
    func keyForWrappingPropertyNamed(propertyName: String) -> String? {
        if ["description"].contains(propertyName) {
            return nil
        }
        
        return propertyName.capitalizedString
    }
}

extension ReplayKeyPoint: CustomStringConvertible {
    var description: String {
        return "[ReplayKeyPoint: data: \(data), "
            + "id: \(id), "
            + "player: \(player), "
            + "type: \(type)]"
    }
}

func == (lhs: ReplayKeyPoint, rhs: ReplayKeyPoint) -> Bool {
    return lhs.id == rhs.id
}
