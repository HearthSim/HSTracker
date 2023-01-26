//
//  Account.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/18/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class Account: Codable {
    struct SyncState: Codable {
        var date: Date
        var hash: String
    }

    private static let cacheFilePath = Paths.HSTracker.appendingPathComponent("hsreplay.cache")
    
    private static var _instance: Account?
    
    var collectionState = [String: SyncState]()
    var mercenariesCollectionState = [String: SyncState]()
    
    static var instance: Account {
        if let inst = _instance {
            return inst
        }
        let inst = Account.load()
        _instance = inst
        return inst
    }
    
    private init() {
        
    }
    
    static func save() -> Bool {
        do {
            let enc = JSONEncoder()
            enc.dateEncodingStrategy = .iso8601
            let json = try enc.encode(Account.instance)
            try json.write(to: Account.cacheFilePath)
            return true
        } catch {
            logger.error("Error while saving account data: \(error)")
            return false
        }
    }
    
    private static func load() -> Account {
        if !FileManager.default.fileExists(atPath: Account.cacheFilePath.path) {
            return Account()
        }
        do {
            let data = try Data(contentsOf: Account.cacheFilePath)
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            let account = try dec.decode(Account.self, from: data)
            return account
        } catch {
            logger.error("Error loading HSReplay cache: \(error)")
        }
        return Account()
    }
}
