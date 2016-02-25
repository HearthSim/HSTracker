//
//  HearthstoneDecks.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RegExCategories
import Kanna

class HearthstoneDecks: BaseNetImporter, NetImporterAware {
    
    var siteName:String {
        return "Hearthstone-Decks"
    }
    
    func handleUrl(url: String) -> Bool {
        return url.isMatch(NSRegularExpression.rx("hearthstone-decks\\.com"))
    }
    
    func loadDeck(url: String, _ completion: Deck? -> Void) throws {

    }
    
}