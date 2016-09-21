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
    case Player, Opponent, DeckManager, Secrets, CardList, Hero
}