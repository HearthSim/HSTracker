//
//  UploadCollectionData.swift
//  HSTracker
//
//  Created by Richard Lee on 2018/8/5.
//  Copyright © 2018 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

struct UploadCollectionData {
    var collection: [MirrorCard]?
    var favoriteHeroes: [String: Int]?
    var cardbacks: [String]?
    var favoriteCardback: Int?
    var dust: Int?
}

extension UploadCollectionData: WrapCustomizable {
    var wrapKeyStyle: WrapKeyStyle {
        return .convertToSnakeCase
    }

    public func wrap(propertyNamed propertyName: String, originalValue: Any, context: Any?, dateFormatter: DateFormatter?) throws -> Any? {
        guard propertyName == "collection", let collection = collection else {
            return nil
        }

        var results = [:] as [String: [Int]]
        for mirrorCard in collection {
           if let card = Cards.by(cardId: mirrorCard.cardId) {
               var counts = results[String(card.dbfId)] ?? [0, 0]
               if mirrorCard.premium {
                   counts[1] = Int(truncating: mirrorCard.count)
               } else {
                   counts[0] = Int(truncating: mirrorCard.count)
               }
               results[String(card.dbfId)] = counts
           }
        }

        let json = try Wrap.wrap(results)

        return json
    }
}
