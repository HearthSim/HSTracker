//
//  CardLegalityChecker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardLegalityChecker {
    private static var legalCardsByFormat: [FormatKey: Set<String>] = [:]
    private static let url = "https://hsreplay.net/api/v1/live/legal_cards/"

    struct FormatKey: Hashable {
        let gameType: GameType
        let format: FormatType
    }

    // MARK: - Load legal cards
    static func loadCardsByFormat(gameType: GameType, format: FormatType) {
        makeRequest(gameType: gameType, format: format) { legalCards in
            if legalCards.isEmpty { return }
            legalCardsByFormat[FormatKey(gameType: gameType, format: format)] = Set(legalCards)
        }
    }

    // MARK: - HTTP request
    private static func makeRequest(gameType: GameType, format: FormatType, handle: @escaping (([String]) -> Void)) {
        let http = Http(url: url)
        http.json(method: .get, parameters: [ "game_type": String(gameType.rawValue), "format_type": String(format.rawValue)]) { json in
            
            if let json = json as? [String] {
                handle(json)
            } else {
                handle([String]())
            }
        }
    }

    // MARK: - Card legality checks
    fileprivate static func isCardLegal(cardId: String, gameType: GameType, format: FormatType) -> Bool {
        let key = FormatKey(gameType: gameType, format: format)
        if let legalCards = legalCardsByFormat[key] {
            return legalCards.contains(cardId)
        }
        return isCardFromFormatFallback(card: Card(id: cardId), format: format)
    }

    // MARK: - Fallback
    private static func isCardFromFormatFallback(card: Card, format: FormatType?) -> Bool {
        guard let cardSet = card.set else {
            return false
        }
        switch format {
        case .ft_classic:
            return CardSet.classicSets().contains(cardSet)
        case .ft_wild:
            return !CardSet.classicSets().contains(cardSet)
        case .ft_standard:
            return !CardSet.wildSets().contains(cardSet) && !CardSet.classicSets().contains(cardSet)
        case .ft_twist:
            return CardSet.twistSets().contains(cardSet)
        default:
            return true
        }
    }
}

extension Card {
    func isCardLegal(gameType: GameType, format: FormatType) -> Bool {
        return CardLegalityChecker.isCardLegal(cardId: id, gameType: gameType, format: format)
    }
}

extension ICardWithRelatedCards {
    func isCardLegal(gameType: GameType, format: FormatType) -> Bool {
        return CardLegalityChecker.isCardLegal(cardId: getCardId(), gameType: gameType, format: format)
    }
}
