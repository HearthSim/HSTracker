//
//  SecretHelper.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class SecretHelper: Equatable, CustomStringConvertible {
    private(set) var id: Int
    private(set) var turnPlayed: Int
    private(set) var heroClass: CardClass
    lazy var possibleSecrets = [String: Bool]()

    init(heroClass: CardClass, id: Int, turnPlayed: Int) {
        self.id = id
        self.turnPlayed = turnPlayed
        self.heroClass = heroClass

        SecretHelper.getSecretIds(heroClass).forEach({
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

    static func getMaxSecretCount(heroClass: CardClass) -> Int {
        return getSecretIds(heroClass).count
    }

    static func getSecretIds(heroClass: CardClass) -> [String] {
        let standardOnly = Game.instance.currentFormat == .standard
        switch heroClass {
        case .hunter: return CardIds.Secrets.Hunter.getCards(standardOnly)
        case .mage: return CardIds.Secrets.Mage.getCards(standardOnly)
        case .paladin: return CardIds.Secrets.Paladin.getCards(standardOnly)
        default: return []
        }
    }

    var description: String {
        return "<SecretHelper: "
            + "id=\(id)"
            + ", turnPlayed=\(turnPlayed)"
            + ", heroClass=\(heroClass)"
            + ", possibleSecrets=\(possibleSecrets)>"
    }
}
func == (lhs: SecretHelper, rhs: SecretHelper) -> Bool {
    return lhs.id == rhs.id
}
