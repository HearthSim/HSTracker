//
//  IHsChoice.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/6/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public protocol IHsChoice {
    var id: Int { get }
    var choiceType: ChoiceType { get }
    var sourceEntityId: Int { get }
    var offeredEntityIds: [Int] { get }
}

public protocol IHsCompletedChoice: IHsChoice {
    var chosenEntityIds: [Int]? { get }
}
