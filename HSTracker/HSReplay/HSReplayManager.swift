//
//  HSReplayManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class HSReplayManager {

    class func showReplay(replayId: String) {
        let url = URL(string: "\(HSReplay.hsreplayUrl)/uploads/upload/\(replayId)"
            + "?utm_source=hstracker&utm_medium=client&utm_campaign=replay")
        NSWorkspace.shared.open(url!)
    }
}
