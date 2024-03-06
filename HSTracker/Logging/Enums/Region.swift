//
//  Region.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/20/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

enum Region: Int {
    case unknown = 0,
    us = 1,
    eu = 2,
    asia = 3,
    china = 5
    
    static func toBnetRegion(region: Region) -> String {
        switch region {
        case .unknown:
            return "REGION_UNKNOWN"
        case .us:
            return "REGION_US"
        case .eu:
            return "REGION_EU"
        case .asia:
            return "REGION_KR"
        case .china:
            return "REGION_CN"
        }
    }
}
