//
//  UploadCollectionData.swift
//  HSTracker
//
//  Created by Richard Lee on 2018/8/5.
//  Copyright © 2018 Benjamin Michotte. All rights reserved.
//

import Foundation

struct UploadCollectionData: Equatable, Codable {
    var collection: [Int: [Int]]?
    var favoriteHeroes: [Int: Int]?
    var cardbacks: [Int]?
    var favoriteCardback: Int?
    var dust: Int?
    var gold: Int?
}
