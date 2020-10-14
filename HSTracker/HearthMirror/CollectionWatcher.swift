//
//  CollectionWatcher.swift
//  HSTracker
//
//  Created by Martin BONNIN on 15/11/2019.
//  Copyright © 2019 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror
import kotlin_hslog

class CollectionWatcher {
    private var lastWorkItem: DispatchWorkItem?

    private let toaster: Toaster
    
    var started: Bool = false
    static private var _instance: CollectionWatcher?

    static func start(toaster: Toaster) {
        if _instance == nil {
            _instance = CollectionWatcher(toaster: toaster)
        }
        
        guard let instance = _instance else {
            return
        }
        instance.started = true
    }
    
    static func stop() {
        guard let instance = _instance else {
            return
        }
        instance.started = false
    }

    init(toaster: Toaster) {
        self.toaster = toaster

        let queue = DispatchQueue(label: "net.hearthsim.hstracker.watchers.\(type(of: self))",
            attributes: [])
        queue.async { [weak self] in
            self?.run()
        }
    }

    func setFeedback(message: String, loading: Bool, timeoutMillis: Int) {
        let toastViewController = CollectionToastViewController(
            nibName: NSNib.Name(rawValue: "CollectionToastViewController"),
            bundle: nil)
        toastViewController.message = message
        toastViewController.loading = loading
        
        toaster.displayToast(viewController: toastViewController, timeoutMillis: 5000)
    }

    private func mirrorCollectionToCollectionUploadData(mirrorCollection: MirrorCollection) -> CollectionUploadData {
                
        var c: [String: [KotlinInt]] = [:]
        for mirrorCard in mirrorCollection.cards {
            if let card = Cards.by(cardId: mirrorCard.cardId) {
                var counts = c[String(card.dbfId)] ?? [0, 0]
                if mirrorCard.premium {
                    counts[1] = KotlinInt(value: mirrorCard.count.int32Value)
                } else {
                    counts[0] = KotlinInt(value: mirrorCard.count.int32Value)
                }
                c[String(card.dbfId)] = counts
            }
        }

        var h = [:] as [String: KotlinInt]
        for (playerclassid, mirrorCard) in mirrorCollection.favoriteHeroes {
            if let card = Cards.by(cardId: mirrorCard.cardId) {
                h[String(playerclassid.intValue)] = KotlinInt(value: Int32(card.dbfId))
            }
        }
        
        return CollectionUploadData(
            collection: c,
            favoriteHeroes: h,
            cardbacks: mirrorCollection.cardbacks.map {KotlinInt(value: $0.int32Value)},
            favoriteCardback: KotlinInt(value: mirrorCollection.favoriteCardback.int32Value),
            dust: KotlinInt(value: mirrorCollection.dust.int32Value),
            gold: KotlinInt(value: mirrorCollection.gold.int32Value)
        )
    }
    private func uploadCollectionFromMainThread(
        collectionUploadData: CollectionUploadData,
        accountId: MirrorAccountId?
    ) {
        setFeedback(message: NSLocalizedString("Uploading collection...", comment: ""), loading: true, timeoutMillis: -1)

        AppDelegate.instance().coreManager.hsReplay.uploadCollectionWithCallback(
            collectionUploadData: collectionUploadData,
            account_hi: "\(accountId?.hi ?? 0)",
            account_lo: "\(accountId?.lo ?? 0)",
            callback: {
                if $0 is HsReplay.CollectionUploadResultFailure {
                    // swiftlint:disable force_cast
                    let failure = ($0 as! HsReplay.CollectionUploadResultFailure)
                    // swiftlint:enable force_cast
                    
                    self.setFeedback(
                        message: NSLocalizedString("Failed to upload collection: \(failure.code)", comment: ""),
                        loading: false,
                        timeoutMillis: 5000)
                    
                    failure.throwable.printStackTrace()
                } else {
                    self.setFeedback(
                        message: NSLocalizedString("Your collection has been uploaded to HSReplay.net", comment: ""),
                        loading: false,
                        timeoutMillis: 5000)
                }
        })
    }
    
    func run() {
        var sent: Bool = false
        var mirrorCollection: MirrorCollection?

        while true {
            if started {
                if mirrorCollection == nil {
                    logger.debug("getting mirrorCollection")
                    mirrorCollection = MirrorHelper.getCollection()
                    logger.debug("got mirrorCollection")
                }
                
                if !sent, let collection = mirrorCollection, Settings.hsReplayOAuthRefreshToken != nil {
                    sent = true

                    let accountId = MirrorHelper.getAccountId()
                    
                    let collectionUploadData = self.mirrorCollectionToCollectionUploadData(mirrorCollection: collection)
                    FreezeHelperKt.freeze(collectionUploadData)

                    DispatchQueue.main.async {
                        self.uploadCollectionFromMainThread(collectionUploadData: collectionUploadData, accountId: accountId)
                    }
                }
            } else {
                sent = false
                mirrorCollection = nil
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}
