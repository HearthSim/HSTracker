//
//  ShortIdHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/16/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation
import CryptoKit
import BigInt

func MD5(string: String) -> Insecure.MD5Digest {
    let messageData = string.data(using: .utf8)!
    return Insecure.MD5.hash(data: messageData)
}

struct ShortIdHelper {
    private static let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    private static let alphabetLength = alphabet.count

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
        let idString = ids.sorted(by: utf8Comparer).joined(separator: ",")
        let hash = MD5(string: idString)
        let hex = hash.map { String(format: "%02hhx", $0) }.joined()
        var v = BigInt()
        for c in hex {
            var value = 0
            if c >= "0" && c <= "9" {
                value = Int(c.asciiValue ?? 0) - 0x30
            } else {
                value = Int(c.asciiValue ?? 0) - 0x61 + 10
            }
            v = v * 16 + BigInt(value)
        }
        return intToString(number: v)
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
    
    static func intToString(number: BigInt) -> String {
        var sb = ""
        var num = number
        let len = BigInt(alphabetLength)
        while num > 0 {
            let mod = num % len
            sb.append(alphabet.char(at: Int(mod)))
            num /= len
        }
        return sb
    }
}
