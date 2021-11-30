//
//  HSReplayNetHelper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/18/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class HSReplayNetHelper {
    static private let collectionSyncLimiter = RateLimiter(maxCount: 6, timeSpan: 2.0)
    static private let mercenariesCollectionSyncLimiter = RateLimiter(maxCount: 6, timeSpan: 2.0)
    static func initialize() {
        CollectionHelpers.hearthstone.onCollectionChanged = {
            /*Task.init {*/ DispatchQueue.global().async {
                /*await*/ syncCollection()
            }
        }
        CollectionHelpers.mercenaries.onCollectionChanged = {
            /*Task.init*/ DispatchQueue.global().async {
                /*await*/ syncMercenariesCollection()
            }
        }
    }
    
    static func syncCollection() /*async*/ {
        guard let collection = /*await*/ CollectionHelpers.hearthstone.getCollection() else {
            return
        }
        let hash = collection.hash()
        let hi = collection.accountHi
        let lo = collection.accountLo
        let account = "\(hi)-\(lo)"
        
        if var state = Account.instance.collectionState[account], state.hash == hash {
            logger.debug("Collection already up-to-date")
            state.date = Date()
            _ = Account.save()
            return
        }
        /*await*/ HSReplayNetHelper.collectionSyncLimiter.run(task: {
            do {
                if !(HSReplayAPI.accountData?.blizzard_accounts.any { x in x.account_hi == hi && x.account_lo == lo } ?? false) {
                    let response = /*await*/ try HSReplayAPI.claimBattleTag(account_hi: hi, account_lo: lo, battleTag: collection.battleTag).wait()
                    if response == .success {
                        // update account data
                    } else if response == .tokenAlreadyClaimed {
                        let message = "Your blizzard account (\(collection.battleTag), \(hi)-\(lo)) is already attached to another HSReplay.net Account. You are currently logged in as \(HSReplayAPI.accountData?.username ?? ""). Please contact us at contact@hsreplay.net if this is not correct."
                        NotificationManager.showNotification(type: .hsReplayCollectionUploadFailed(error: message))
                        return
                    } else {
                        let message = "Could not attach your Blizzard account (\(collection.battleTag), \(hi)-\(lo)) to HSReplay.net Account (\(HSReplayAPI.accountData?.username ?? "")). Please try again later or contact us at contact@hsreplay.net if this persists."
                        NotificationManager.showNotification(type: .hsReplayCollectionUploadFailed(error: message))
                        return
                    }
                }
                
                if /*await*/ try HSReplayAPI.uploadCollection(collection: collection, collectionType: .constructed).wait() {
                    Account.instance.collectionState[account] = Account.SyncState(date: Date(), hash: hash)
                    _ = Account.save()
                    logger.debug("Collection synced")
                    NotificationManager.showNotification(type: .hsReplayCollectionUploaded)
                } else {
                    let message = "Could not update your collection. Please try again later. If this problem persists please try logging out and back in under 'Preferences > HSReplay > Collection Uploads'"
                    NotificationManager.showNotification(type: .hsReplayCollectionUploadFailed(error: message))
                }
            } catch {
                logger.error(error)
                NotificationManager.showNotification(type: .hsReplayCollectionUploadFailed(error: "\(error.localizedDescription)"))
            }
        }, onThrottled: {
            logger.debug("Waiting for rate limit...")
        })
    }

    static func syncMercenariesCollection() /*async*/ {
        guard let collection = /*await*/ CollectionHelpers.mercenaries.getCollection() else {
            return
        }
        let hash = collection.hash()
        let hi = collection.accountHi
        let lo = collection.accountLo
        let account = "\(hi)-\(lo)"
        
        if var state = Account.instance.mercenariesCollectionState[account], state.hash == hash {
            logger.debug("Mercenaries collection already up-to-date")
            state.date = Date()
            _ = Account.save()
            return
        }
        /*await*/ HSReplayNetHelper.mercenariesCollectionSyncLimiter.run(task: {
            do {
                if !(HSReplayAPI.accountData?.blizzard_accounts.any { x in x.account_hi == hi && x.account_lo == lo } ?? false) {
                    let response = /*await*/ try HSReplayAPI.claimBattleTag(account_hi: hi, account_lo: lo, battleTag: collection.battleTag).wait()
                    if response == .success {
                        // update account data
                    } else if response == .tokenAlreadyClaimed {
                        let message = "Your blizzard account (\(collection.battleTag), \(hi)-\(lo)) is already attached to another HSReplay.net Account. You are currently logged in as \(HSReplayAPI.accountData?.username ?? ""). Please contact us at contact@hsreplay.net if this is not correct."
                        NotificationManager.showNotification(type: .hsReplayCollectionUploadFailed(error: message))
                        return
                    } else {
                        let message = "Could not attach your Blizzard account (\(collection.battleTag), \(hi)-\(lo)) to HSReplay.net Account (\(HSReplayAPI.accountData?.username ?? "")). Please try again later or contact us at contact@hsreplay.net if this persists."
                        NotificationManager.showNotification(type: .hsReplayMercenariesCollectionUploadFailed(error: message))
                        return
                    }
                }
                
                if /*await*/ try HSReplayAPI.uploadCollection(collection: collection, collectionType: .mercenaries).wait() {
                    Account.instance.mercenariesCollectionState[account] = Account.SyncState(date: Date(), hash: hash)
                    _ = Account.save()
                    logger.debug("Mercenaries collection synced")
                    NotificationManager.showNotification(type: .hsReplayMercenariesCollectionUploaded)
                } else {
                    let message = "Could not update your Mercenaries collection. Please try again later. If this problem persists please try logging out and back in under 'Preferences > HSReplay > Collection Uploads'"
                    NotificationManager.showNotification(type: .hsReplayMercenariesCollectionUploadFailed(error: message))
                }
            } catch {
                logger.error(error)
                NotificationManager.showNotification(type: .hsReplayMercenariesCollectionUploadFailed(error: "\(error.localizedDescription)"))
            }
        }, onThrottled: {
            logger.debug("Waiting for rate limit...")
        })
    }}
