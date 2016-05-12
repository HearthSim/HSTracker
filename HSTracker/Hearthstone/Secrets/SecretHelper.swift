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
    private(set) var heroClass: HeroClass
    lazy var possibleSecrets = [String: Bool]()

    init(heroClass: HeroClass, id: Int, turnPlayed: Int) {
        self.id = id
        self.turnPlayed = turnPlayed
        self.heroClass = heroClass

        SecretHelper.getSecretIds(heroClass).forEach({
            possibleSecrets[$0] = true
        })
    }

    static func getMaxSecretCount(heroClass: HeroClass) -> Int {
        return getSecretIds(heroClass).count
    }

    static func getSecretIds(heroClass: HeroClass) -> [String] {
        let standardOnly = Game.instance.currentFormat == .Standard
        switch heroClass {
        case .Hunter: return CardIds.Secrets.Hunter.getCards(standardOnly)
        case .Mage: return CardIds.Secrets.Mage.getCards(standardOnly)
        case .Paladin: return CardIds.Secrets.Paladin.getCards(standardOnly)
        default: return [String]()
        }
    }

    var description: String {
        return "<\(NSStringFromClass(self.dynamicType)): "
            + "id=\(id)"
            + ", turnPlayed=\(turnPlayed)"
            + ", heroClass=\(heroClass)"
            + ", possibleSecrets=\(possibleSecrets)>"
    }
}
func == (lhs: SecretHelper, rhs: SecretHelper) -> Bool {
    return lhs.id == rhs.id
}
