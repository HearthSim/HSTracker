//
//  PlayerType.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 16/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

enum PlayerType: Int, WrappableEnum {
    case player, opponent, deckManager, secrets, cardList, hero
}
