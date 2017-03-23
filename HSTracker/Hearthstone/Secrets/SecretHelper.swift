//
//  SecretHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class SecretHelper {
    private(set) var id: Int
    private(set) var turnPlayed: Int
    private(set) var heroClass: CardClass
    var possibleSecrets: [String: Bool] = [:]

	init(heroClass: CardClass, id: Int, turnPlayed: Int, gameFormat: Format) {
        self.id = id
        self.turnPlayed = turnPlayed
        self.heroClass = heroClass

		SecretHelper.getSecretIds(heroClass: heroClass, gameFormat: gameFormat).forEach({
            possibleSecrets[$0] = true
        })
    }
    
    func trySetSecret(cardId: String, active: Bool) {
        if let _ = possibleSecrets[cardId] {
            possibleSecrets[cardId] = active
        }
    }
    
    func tryGetSecret(cardId: String) -> Bool {
        guard let active = possibleSecrets[cardId] else { return false }
        
        return active
    }

    static func getMaxSecretCount(heroClass: CardClass, gameFormat: Format) -> Int {
		return getSecretIds(heroClass: heroClass, gameFormat: gameFormat).count
    }

	static func getSecretIds(heroClass: CardClass, gameFormat: Format) -> [String] {

        let standardOnly = gameFormat == .standard
        switch heroClass {
        case .hunter: return CardIds.Secrets.Hunter.getCards(standardOnly: standardOnly)
        case .mage: return CardIds.Secrets.Mage.getCards(standardOnly: standardOnly)
        case .paladin: return CardIds.Secrets.Paladin.getCards(standardOnly: standardOnly)
        default: return []
        }
    }
}

extension SecretHelper: CustomStringConvertible {
    var description: String {
        return "<SecretHelper: "
            + "id=\(id)"
            + ", turnPlayed=\(turnPlayed)"
            + ", heroClass=\(heroClass)"
            + ", possibleSecrets=\(possibleSecrets)>"
    }
}

extension SecretHelper: Equatable {
    static func == (lhs: SecretHelper, rhs: SecretHelper) -> Bool {
        return lhs.id == rhs.id
    }
}
