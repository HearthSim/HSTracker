//
//  ShortIdHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/16/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation
import CryptoKit
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

func MD5(data: Data) -> Data {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    var digestData = Data(count: length)

    _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
        data.withUnsafeBytes { messageBytes -> UInt8 in
            if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                let messageLength = CC_LONG(data.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
            return 0
        }
    }
    return digestData
}

func MD5(string: String) -> Data {
    let messageData = string.data(using: .utf8)!
    return MD5(data: messageData)
}

struct ShortIdHelper {
    private static let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    private static let alphabetLength = alphabet.count

    private static func mapSideboardCardToId(_ card: Card) -> String {
        // We always consider Zilliax Deluxe 3000 with his default cosmetic
        if card.zilliaxCustomizableCosmeticModule {
            return "TOY_330t5"
        }

        return card.id
    }
    
    static func getShortId(deck: PlayingDeck) -> String {
        if deck.cards.count == 0 {
            return ""
        }
        var ids = [String]()
        for c in deck.cards {
            for _ in 0 ..< c.count {
                ids.append(c.id)
            }
        }
        var idString = ids.sorted(by: utf8Comparer).joined(separator: ",")
        for sideboard in deck.sideboards.sorted(by: { (a, b) -> Bool in
            return a.ownerCardId < b.ownerCardId
        }) {
            let sideboardIds = sideboard.cards.flatMap { c in repeatElement(mapSideboardCardToId(c), count: c.count) }
            let sideboardCardsIdString = sideboardIds.sorted(by: utf8Comparer).joined(separator: ",")
            idString += "/\(sideboard.ownerCardId):\(sideboardCardsIdString)"
        }

        return intToString(bigEndian: [UInt8](MD5(string: idString)))
    }
    
    static let chars = "_0123456789aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ"
    
    static func utf8Comparer(a: String, b: String) -> Bool {
        if a == b {
            return false
        }
        for el in zip(a, b) {
            let v = chars.distance(from: chars.firstIndex(of: el.0)!, to: chars.firstIndex(of: el.1)!)
            if v < 0 {
                return false
            } else if v > 0 {
                return true
            }
        }
        return a.count < b.count
    }
    
    /// Writes the unsigned big-endian integer in `bytes` in base `alphabetLength`, least
    /// significant digit first, by repeated long division of the byte array.
    static func intToString(bigEndian bytes: [UInt8]) -> String {
        var sb = ""
        var digits = bytes
        let base = UInt32(alphabetLength)
        while digits.contains(where: { $0 != 0 }) {
            var remainder: UInt32 = 0
            for i in digits.indices {
                let value = remainder << 8 | UInt32(digits[i])
                digits[i] = UInt8(value / base)
                remainder = value % base
            }
            sb.append(alphabet.char(at: Int(remainder)))
        }
        return sb
    }
}
