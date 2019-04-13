//
//  UploadCollectionData.swift
//  HSTracker
//
//  Created by Richard Lee on 2018/8/5.
//  Copyright © 2018 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

struct UploadCollectionData: Equatable {
    var collection: [MirrorCard]?
    var favoriteHeroes: [NSNumber: MirrorCard]?
    var cardbacks: [NSNumber]?
    var favoriteCardback: Int?
    var dust: Int?
    var gold: Int?
    
    /*
     * We should certainly remove the MirrorCard/NSObject dependency from this class so we can implement Equatable and wrap it automagically
     */
    static private func mirrorCardEquals(lhs: MirrorCard, rhs: MirrorCard) -> Bool {
        if lhs.cardId != rhs.cardId {
            return false
        }
        if lhs.count != rhs.count {
            return false
        }
        if lhs.premium != rhs.premium {
            return false
        }
        return true
    }
    
    static private func mirrorCardArrayEquals(lhs: [MirrorCard]?, rhs: [MirrorCard]?) -> Bool {
      
        if lhs == nil && rhs == nil {
            return true
        }
        
        guard let l = lhs, let r = rhs else {
            return false
        }
        
        return l.elementsEqual(r) {lcard, rcard in
            mirrorCardEquals(lhs: lcard, rhs: rcard)
        }
    }
    
    static private func mirrorCardDictEquals(lhs: [NSNumber: MirrorCard]?, rhs: [NSNumber: MirrorCard]?) -> Bool {
        
        if lhs == nil && rhs == nil {
            return true
        }
        
        guard let l = lhs, let r = rhs else {
            return false
        }
        
        return l.elementsEqual(r) {le, re in
            le.key == re.key
            && mirrorCardEquals(lhs: le.value, rhs: re.value)
        }
    }
    
    static func == (lhs: UploadCollectionData, rhs: UploadCollectionData) -> Bool {
        if !mirrorCardArrayEquals(lhs: lhs.collection, rhs: rhs.collection) {
            return false
        }
        
        if !mirrorCardDictEquals(lhs: lhs.favoriteHeroes, rhs: rhs.favoriteHeroes) {
            return false
        }

        return lhs.cardbacks == rhs.cardbacks
            && lhs.favoriteCardback == rhs.favoriteCardback
            && lhs.dust == rhs.dust
            && lhs.gold == rhs.gold       
    }
}

extension UploadCollectionData: WrapCustomizable {
    var wrapKeyStyle: WrapKeyStyle {
        return .convertToSnakeCase
    }

    public func wrap(propertyNamed propertyName: String, originalValue: Any, context: Any?, dateFormatter: DateFormatter?) throws -> Any? {
        if propertyName == "collection" {
            guard let collection = self.collection else {
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
        } else if propertyName == "favoriteHeroes" {
            guard let favoriteHeroes = self.favoriteHeroes else {
                return nil
            }
            var results = [:] as [String: Int]
            for (playerclassid, mirrorCard) in favoriteHeroes {
                if let card = Cards.by(cardId: mirrorCard.cardId) {
                    results[String(playerclassid.intValue)] = card.dbfId
                }
            }
            
            let json = try Wrap.wrap(results)
            return json
        } else if propertyName == "cardbacks" {
            guard let cardbacks = self.cardbacks else {
                return nil
            }
            let results = cardbacks.map {$0.intValue}
            
            let json = try Wrap.wrap(results)
            return json
        }

        return nil
    }
}
