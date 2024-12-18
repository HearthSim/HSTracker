//
//  ICardExtraInfo.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol ICardExtraInfo: NSCopying, Equatable {
    var cardNameSuffix: String? { get }
}
