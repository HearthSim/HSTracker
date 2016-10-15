//
//  KeyPointType.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

enum KeyPointType: String, WrappableEnum {
    case play,
        draw,
        mulligan,
        death,
        handDiscard,
        deckDiscard,
        secretPlayed,
        secretTriggered,
        turn,
        attack,
        playToHand,
        playToDeck,
        obtain,
        summon,
        handPos,
        boardPos,
        playSpell,
        weapon,
        weaponDestroyed,
        heroPower,
        victory,
        defeat,
        secretStolen,
        createToDeck
}
