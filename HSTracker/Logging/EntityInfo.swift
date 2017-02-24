//
//  EntityInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 15/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

struct EntityInfo {
    private unowned var _entity: Entity
    var discarded = false
    var returned = false
    var mulliganed = false
    var stolen: Bool {
        return originalController > 0 && originalController != _entity[.controller]
    }
    var created = false
    var hasOutstandingTagChanges = false
    var originalController = 0
    var hidden = false
    var turn = 0
    var costReduction = 0
    var originalZone: Zone?
    var createdInDeck: Bool { return originalZone == .deck }
    var createdInHand: Bool { return originalZone == .hand }

    init(entity: Entity) {
        _entity = entity
    }

    var cardMark: CardMark {
        if hidden {
            return .none
        }

        if _entity.cardId == CardIds.NonCollectible.Neutral.TheCoin || _entity.cardId ==
            CardIds.NonCollectible.Neutral.TradePrinceGallywix_GallywixsCoinToken {
            return .coin
        }
        if returned {
            return .returned
        }
        if created || stolen {
            return .created
        }
        if mulliganed {
            return .mulliganed
        }
        return .none
    }
}

extension EntityInfo: CustomStringConvertible {
    var description: String {
        var description = "[EntityInfo: "
            + "turn=\(turn)"

        if cardMark != .none {
            description += ", cardMark=\(cardMark)"
        }
        if discarded {
            description += ", discarded=true"
        }
        if created {
            description += ", created=true"
        }
        if returned {
            description += ", returned=true"
        }
        if stolen {
            description += ", stolen=true"
        }
        if mulliganed {
            description += ", mulliganed=true"
        }
        description += "]"

        return description
    }
}

extension EntityInfo: WrapCustomizable {
    func keyForWrapping(propertyNamed propertyName: String) -> String? {
        if ["_entity", "description"].contains(propertyName) {
            return nil
        }

        return propertyName.capitalized
    }
}
