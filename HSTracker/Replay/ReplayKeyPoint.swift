//
//  ReplayKeyPoint.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

final class ReplayKeyPoint {
    var data: [Entity]
    var id: Int
    var player: PlayerType
    var type: KeyPointType

    init(data: [Entity]?, type: KeyPointType, id: Int, player: PlayerType) {
        if let data = data {
            self.data = data.flatMap { $0.copy() as? Entity }
        } else {
            self.data = []
        }
        self.type = type
        self.id = id
        self.player = player
    }

    var turn: Int {
        if let entity = data.first {
            return entity[.turn]
        }
        return 0
    }

    func getCardId() -> String? {
        var tag: Int = 0
        if let entity = data.first {
            tag = entity[.proposed_attacker]
        }
        let id = type == .attack ? tag : self.id
        return data.firstWhere { $0.id == id }?.cardId
    }

    func getAdditionalInfo() -> String {
        if type == .victory || type == .defeat {
            return type.rawValue
        }
        return getCardId().isBlank ? "Entity \(id)" : Cards.by(cardId: getCardId()!)!.name
    }
}

extension ReplayKeyPoint: Equatable {
    static func == (lhs: ReplayKeyPoint, rhs: ReplayKeyPoint) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ReplayKeyPoint: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        if ["description"].contains(propertyName) {
            return nil
        }
        
        return propertyName.capitalized
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
