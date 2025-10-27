//
//  ICardGenerator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/26/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol ICardGenerator: ICard {
    init()
    func isInGeneratorPool(_ card: Card, _ gameMode: GameType, _ format: FormatType) -> Bool
}
