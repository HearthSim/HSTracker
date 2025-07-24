//
//  BattlegroundsCompGuideViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/9/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

enum CardAssetType: Int {
    case hero,
         fullImage
}

class Run {
    var string: String
    
    init(_ str: String) {
        string = str
    }
}

class ReferencedCardRun: Run {
    var card: Card?
    var assetType = CardAssetType.fullImage
    
    static var cardsByDbfId = [Int: Card]()
    
    static func initialize() {
        let heroes = Cards.cards.filter({ x in x.type == .battleground_spell || (x.type == .hero && x.baconHeroCanBeDrafted)})
        cardsByDbfId = Dictionary(uniqueKeysWithValues: (Cards.battlegroundsMinions.array() + heroes).compactMap({ ($0.dbfId, $0) }))
    }
    
    static func resolveCardNameOrFallback(_ dbfId: Int?, _ fallback: String) -> String {
        if cardsByDbfId.count == 0 {
            initialize()
        }
        if let theDbfId = dbfId, let card = cardsByDbfId[theDbfId] {
            return card.name
        }
        
        return fallback
    }
    
    init(_ dbfId: Int?, _ fallback: String) {
        super.init(ReferencedCardRun.resolveCardNameOrFallback(dbfId, fallback))
        
        if let theDbfId = dbfId, let card = ReferencedCardRun.cardsByDbfId[theDbfId] {
            self.card = card.copy()
            self.card?.baconCard = true
            assetType = card.type == .hero ? .hero : .fullImage
        }
    }
}

class BattlegroundsCompGuideViewModel: ViewModel {
    
    let compGuide: BattlegroundsCompGuide
    
    private static func createLinearGradient(_ color1: NSColor, _ color2: NSColor) -> CALayer {
        let brush = CAGradientLayer()
        brush.startPoint = CGPoint(x: 0.0, y: 0.0)
        brush.endPoint = CGPoint(x: 1.0, y: 1.0)
        brush.colors = [ color1.cgColor, color2.cgColor ]
        brush.locations = [ 0.0, 1.0 ]
        return brush
    }
    
    private static func parseCardsFromText(_ text: String) -> [Run] {
        var result = [Run]()
        if text.count == 0 {
            return result
        }
        
        var index = text.startIndex
        
        while index < text.endIndex {
            guard let nextIndex = text.range(of: "[[", range: index ..< text.endIndex) else {
                result.append(Run(String(text[index ..< text.endIndex])))
                return result
            }

            // If there is text before the next tag, return it
            if nextIndex.lowerBound > index {
                result.append(Run(String(text[index ..< nextIndex.lowerBound])))
            }
            
            index = text.index(nextIndex.lowerBound, offsetBy: 2)
            
            guard let endIndex = text.range(of: "]]", range: index ..< text.endIndex) else {
                // Edge case: if there is no closing tag, just return the remaining text
                result.append(Run(String(text[nextIndex.lowerBound ..< text.endIndex])))
                return result
            }
            
            // Check if there's a dbf id before the end
            var separatorIndex = text.range(of: "||", range: index ..< endIndex.lowerBound)?.lowerBound ?? text.endIndex

            // Discard any separators past the end of this card
            if separatorIndex > endIndex.lowerBound {
                separatorIndex = text.endIndex
            }
            
            // Parse the dbf id
            let loaded = separatorIndex != text.endIndex ? String(text[text.index(separatorIndex, offsetBy: 2) ..< endIndex.lowerBound]) : ""
            let dbfId = separatorIndex != text.endIndex ? Int(loaded) : nil
            
            let cardNameTerminator = separatorIndex != text.endIndex ? separatorIndex : endIndex.lowerBound
            // FIXME
            result.append(ReferencedCardRun(dbfId, String(text[index ..< cardNameTerminator])))

            index = text.index(endIndex.lowerBound, offsetBy: 2)
        }
        return result
    }
    
    init(_ comp: BattlegroundsCompGuide) {
        compGuide = comp
        
        coreCardId = compGuide.core_cards.first ?? 0
        cardToShowInUi = Cards.by(dbfId: coreCardId, collectible: false)
        difficultyText = switch compGuide.difficulty {
        case 1: "Easy"
        case 2: "Medium"
        case 3: "Hard"
        default: "Unknown"
        }
        difficultyColor = switch compGuide.difficulty {
        case 1: "#49634b"
        case 2: "#917b43"
        case 3: "#7f303e"
        default: "#404040"
        }
        tierText = switch compGuide.tier {
        case 1: "S"
        case 2: "A"
        case 3: "B"
        case 4: "C"
        case 5: "D"
        default: "?"
        }
        tierColor = switch compGuide.tier {
        case 1: BattlegroundsCompGuideViewModel.createLinearGradient(NSColor.fromRgb(64, 138, 191), NSColor.fromRgb(56, 95, 122))
        case 2: BattlegroundsCompGuideViewModel.createLinearGradient(NSColor.fromRgb(107, 160, 54), NSColor.fromRgb(88, 121, 55))
        case 3: BattlegroundsCompGuideViewModel.createLinearGradient(NSColor.fromRgb(146, 160, 54), NSColor.fromRgb(104, 121, 55))
        case 4: BattlegroundsCompGuideViewModel.createLinearGradient(NSColor.fromRgb(160, 124, 54), NSColor.fromRgb(121, 95, 55))
        case 5: BattlegroundsCompGuideViewModel.createLinearGradient(NSColor.fromRgb(160, 72, 54), NSColor.fromRgb(121, 66, 55))
        default: BattlegroundsCompGuideViewModel.createLinearGradient(NSColor.fromRgb(112, 112, 112), NSColor.fromRgb(64, 64, 64))
        }
        
        commonEnablerTags = compGuide.common_enablers.replace("\\r\\n", with: "\n").replace("\\r", with: "\n").components(separatedBy: "\\n").flatMap({ BattlegroundsCompGuideViewModel.parseCardsFromText($0)})
        whenToCommitTags = compGuide.when_to_commit.replace("\\r\\n", with: "\n").replace("\\r", with: "\n").components(separatedBy: "\\n").flatMap({ BattlegroundsCompGuideViewModel.parseCardsFromText($0)})
        howToPlay = BattlegroundsCompGuideViewModel.parseCardsFromText(compGuide.how_to_play)
        
        cardAsset = cardToShowInUi?.id ?? ""
       
        super.init()
    }
    
    var lastUpdatedFormatted: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: compGuide.last_updated)
        return Helper.getAge(date ?? Date())
    }
    
    let coreCardId: Int
    
    let commonEnablerTags: [Run]
    let whenToCommitTags: [Run]
    
    let tierText: String
    let tierColor: CALayer
    let cardToShowInUi: Card?
    
    let difficultyText: String
    let difficultyColor: String
    
    var cardAsset: String
    
    var _coreCards: [Card]?
    var coreCards: [Card] {
        if let _coreCards {
            return _coreCards
        }
        let cards = compGuide.core_cards.compactMap { cardId in
            let card = Cards.by(dbfId: cardId, collectible: false)
            card?.baconCard = true
            return card
        }
        _coreCards = cards
        return cards
    }
    var _addonCards: [Card]?
    var addonCards: [Card] {
        if let _addonCards {
            return _addonCards
        }
        let cards = compGuide.addon_cards.compactMap { cardId in
            let card = Cards.by(dbfId: cardId, collectible: false)
            card?.baconCard = true
            return card
        }
        _addonCards = cards
        return cards
    }
    
    var howToPlay: [Run]
}
