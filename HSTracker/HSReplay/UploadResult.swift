//
//  UploadResult.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

enum UploadResult {
    case failed(error: String)
    case successful(replayId: String)
}
