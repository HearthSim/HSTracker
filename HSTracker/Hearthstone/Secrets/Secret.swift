//
//  Secret.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift

enum SecretError: Error {
    case entityIsNotSecret(entity: Entity)
    case entityHasNoClass(entity: Entity)
    case entityHasInvalidClass(entity: Entity)
}

class Secret {

    private(set) var entity: Entity
    var excluded: [String: Bool] = [:]

    init(entity: Entity) throws {
        guard entity.isSecret else { throw SecretError.entityIsNotSecret(entity: entity) }
        guard entity.has(tag: .class) else { throw SecretError.entityHasNoClass(entity: entity) }
        guard let tagClass = TagClass(rawValue: entity[.class]) else {
            throw SecretError.entityHasInvalidClass(entity: entity)
        }
        self.entity = entity
        self.excluded = Secret.getAllSecrets(for: tagClass)
            .reduce([String: Bool]()) { dict, act in
                var ret = dict
                ret[act] = false
                return ret
        }
    }

    func exclude(cardId: String) {
        if excluded.keys.contains(cardId) {
            excluded[cardId] = true
        }
    }

    func isExcluded(cardId: String) -> Bool {
        return excluded.keys.contains(cardId) && excluded[cardId]!
    }

    func include(cardId: String) {
        if excluded.keys.contains(cardId) {
            excluded[cardId] = false
        }
    }

    private static func getAllSecrets(for heroClass: TagClass) -> [String] {
        switch heroClass {
        case .hunter: return CardIds.Secrets.Hunter.All
        case .mage: return CardIds.Secrets.Mage.All
        case .paladin: return CardIds.Secrets.Paladin.All
        default: return []
        }
    }
}

extension Secret: Equatable {
    static func == (lhs: Secret, rhs: Secret) -> Bool {
        return lhs.entity.id == rhs.entity.id
    }
}
