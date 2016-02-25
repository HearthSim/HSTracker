//
//  Hearthnews.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RegExCategories
import Kanna

class Hearthnews: BaseNetImporter, NetImporterAware {
    
    var siteName:String {
        return "HearthNews"
    }
    
    func handleUrl(url: String) -> Bool {
        return url.isMatch(NSRegularExpression.rx("hearthnews\\.fr"))
    }
    
    func loadDeck(url: String, _ completion: Deck? -> Void) throws {
        
    }
    
}