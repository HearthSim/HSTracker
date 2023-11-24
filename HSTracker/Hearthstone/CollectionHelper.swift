//
//  CollectionHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/16/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class CollectionHelpers {
    static var hearthstone = CollectionHelper<Collection>(loadCollection: loadCollection)
    static var mercenaries = CollectionHelper<MercenariesCollection>(loadCollection: loadMercenariesCollection)
    
    static private func loadCollection(key: String) -> Collection? {
        let data = (collection: MirrorHelper.getCollection(), battletag: MirrorHelper.getBattleTag())

        let parts = key.split(separator: "-")

        if let collection = data.collection, collection.cards.count > 0, let battleTag = data.battletag, parts.count == 2 {
            let hi = Int64(parts[0]) ?? 0
            let lo = Int64(parts[1]) ?? 0

            return Collection(accountHi: hi, accountLo: lo, battleTag: battleTag, collection: collection)
        }
        return nil
    }

    static private func loadMercenariesCollection(key: String) -> MercenariesCollection? {
        let data = (collection: MirrorHelper.getMercenariesCollection(), battletag: MirrorHelper.getBattleTag())
        
        let parts = key.split(separator: "-")

        if let collection = data.collection, collection.count > 0, let battleTag = data.battletag, parts.count == 2 {
            let hi = Int64(parts[0]) ?? 0
            let lo = Int64(parts[1]) ?? 0

            return MercenariesCollection(accountHi: hi, accountLo: lo, battleTag: battleTag, collection: collection)
        }
        return nil
    }
}

class CollectionHelper<T> {
    private var _lastUpdate: TimeInterval = 0.0
    private var _lastUsedKey: String?
    private var collections = SynchronizedDictionary<String, T>()
    private let _loadCollection: (String) -> T?
    var onCollectionChanged: (() -> Void)?
    
    init(loadCollection: @escaping (String) -> T?) {
        _loadCollection = loadCollection
    }
    
    func getCollection() -> T? {
        let key = /*await*/ getCurrentKey()
        var collection: T?
        if let key = key {
            if let collection = collections[key] {
                return collection
            }

            /*await*/ updateCollection()
            collection = collections[key]
        }
        return collection
    }
    
    func updateCollection() {
        let key = /*await*/ getCurrentKey()
        _ = /*await*/ updateCollection(key: key, retry: false)
    }
    
    private func updateCollection(key: String?, retry: Bool = false) -> Bool {
        guard let key = key else {
            return false
        }
        
        let now = Date().timeIntervalSinceReferenceDate
        
        if now - _lastUpdate < 2.0 {
            return false
        }
        logger.info("Updating collection...")
        _lastUpdate = now
        
        let data = /*await*/ _loadCollection(key)
        
        if let collection = data {
            collections[key] = collection
            onCollectionChanged?()
            logger.info("Updated collection!")
            return true
        }
        if retry {
            logger.warning("No collection found, retrying...")
            Thread.sleep(forTimeInterval: 3)
            return /*await*/ updateCollection(key: key, retry: false)
        }
        logger.warning("No collection found")
        return false
    }
    
    private func getCurrentKey(retry: Bool = true) -> String? {
        if !AppDelegate.instance().coreManager.game
            .isRunning {
            return nil
        }
        if let user = MirrorHelper.getAccountId() {
            _lastUsedKey = "\(user.hi.int64Value)-\(user.lo.int64Value)"
            return _lastUsedKey
        } else {
            logger.info("User not found, retrying...")
            Thread.sleep(forTimeInterval: 3.0)
            return /*await*/ getCurrentKey(retry: false)
        }
    }
}
