//
//  NotificationType.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 16/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum NotificationType {
    case gameStart, turnStart, opponentConcede, hsReplayPush(replayId: String)
}
