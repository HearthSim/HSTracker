//
//  HSReplayManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class HSReplayManager {

    class func showReplay(replayId: String) {
        let url = URL(string: "\(HSReplay.baseUrl)/uploads/upload/\(replayId)")
        NSWorkspace.shared().open(url!)
    }
}
