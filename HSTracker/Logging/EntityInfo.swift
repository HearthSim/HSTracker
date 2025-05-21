//
//  EntityInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 15/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class EntityInfo {
    private unowned var _entity: Entity
    private var _latestCardId: String?
    var drawerId: Int?
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
    var revealedOnHistory = false
    var originalZone: Zone?
    var createdInDeck: Bool { return originalZone == .deck }
    var createdInHand: Bool { return originalZone == .hand }
    private(set) var originalCardId: String?
    var wasTransformed: Bool { return !originalCardId.isBlank }
    var originalEntityWasCreated: Bool?
    var guessedCardState: GuessedCardState = GuessedCardState.none
    var storedCardIds: [String] = []
    var copyOfCardId: String?
    var latestCardId: String {
        get { _latestCardId ?? _entity.cardId }
        set { _latestCardId = newValue }
    }
    var deckIndex = 0
    var inGraveyardAtStartOfGame = false
    var extraInfo: (any ICardExtraInfo)?
    var forged = false

    init(entity: Entity) {
        _entity = entity
    }

    var cardMark: CardMark {
        if hidden {
            if drawnByEntity {
                return .drawnByEntity
            }
            return mulliganed ? .mulliganed : .none
        }
        if forged {
            return .forged
        }
        if drawnByEntity {
            return .drawnByEntity
        }
        if _entity.isTheCoin {
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
    
    func getCreatorId() -> Int {
        if hidden {
            return 0
        }
        var creatorId = _entity[.displayed_creator]
        if creatorId == 0 {
            creatorId = _entity[.creator]
        }
        return creatorId
    }
    
    func getDrawerId() -> Int? {
        return drawerId
    }

    func set(originalCardId dbfId: Int) {
        if dbfId <= 0 { return }

        originalCardId = Cards.by(dbfId: dbfId)?.id
    }
    
    func clearCardId() {
        originalCardId = nil
        _latestCardId = nil
    }
    
    var drawnByEntity: Bool {
        return drawerId != nil
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
        if guessedCardState != .none {
            description += ", guessedCardState=\(guessedCardState)"
        }
        if _latestCardId != nil {
            description += ", latestCardId=\(latestCardId)"
        }
        if storedCardIds.count > 0 {
            description += ", storedCardIds=[\(storedCardIds.joined(separator: ", "))]"
        }
        if deckIndex > 0 {
            description += ", deckIndex=\(deckIndex)"
        }
        if forged {
            description += ", forged=true"
        }
        if let copyOfCardId {
            description += ", copyOf=\(copyOfCardId)"
        }
        if let extraInfo, let suffix = extraInfo.cardNameSuffix {
            description += ", extraInfo=\(suffix)"
        }
        description += ", inGraveyardAtStartOfGame=\(inGraveyardAtStartOfGame)"
        description += "]"

        return description
    }
}
