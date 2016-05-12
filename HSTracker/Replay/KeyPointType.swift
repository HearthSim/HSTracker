//
//  KeyPointType.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum KeyPointType: String {
    case Play,
        Draw,
        Mulligan,
        Death,
        HandDiscard,
        DeckDiscard,
        SecretPlayed,
        SecretTriggered,
        Turn,
        Attack,
        PlayToHand,
        PlayToDeck,
        Obtain,
        Summon,
        HandPos,
        BoardPos,
        PlaySpell,
        Weapon,
        WeaponDestroyed,
        HeroPower,
        Victory,
        Defeat,
        SecretStolen,
        CreateToDeck
}
