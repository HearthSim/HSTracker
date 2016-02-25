//
//  Hearthhead.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RegExCategories
import Kanna

class Hearthhead: BaseNetImporter, NetImporterAware {
    
    var siteName:String {
        return "Hearthhead"
    }
    
    func handleUrl(url: String) -> Bool {
        return url.isMatch(NSRegularExpression.rx("hearthhead\\.com\\/deck="))
    }
    
    func loadDeck(url: String, _ completion: Deck? -> Void) throws {
        
    }
    
}