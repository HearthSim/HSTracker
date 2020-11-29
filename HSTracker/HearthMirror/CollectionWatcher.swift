//
//  CollectionWatcher.swift
//  HSTracker
//
//  Created by Martin BONNIN on 15/11/2019.
//  Copyright © 2019 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

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
            nibName: "CollectionToastViewController",
            bundle: nil)
        toastViewController.message = message
        toastViewController.loading = loading
        
        toaster.displayToast(viewController: toastViewController, timeoutMillis: timeoutMillis)
    }

    private func mirrorCollectionToCollectionUploadData(mirrorCollection: MirrorCollection) -> UploadCollectionData {
                
        var c: [Int: [Int]] = [:]
        for mirrorCard in mirrorCollection.cards {
            if let card = Cards.any(byId: mirrorCard.cardId) {
                var counts = c[card.dbfId] ?? [0, 0]
                if mirrorCard.premium {
                    counts[1] = mirrorCard.count.intValue
                } else {
                    counts[0] = mirrorCard.count.intValue
                }
                c[card.dbfId] = counts
            }
        }

        var h = [:] as [Int: Int]
        for (playerclassid, mirrorCard) in mirrorCollection.favoriteHeroes {
            if let card = Cards.any(byId: mirrorCard.cardId) {
                h[playerclassid.intValue] = card.dbfId
            }
        }
        
        return UploadCollectionData(
            collection: c,
            favoriteHeroes: h,
            cardbacks: mirrorCollection.cardbacks.map { $0.intValue },
            favoriteCardback: mirrorCollection.favoriteCardback.intValue,
            dust: mirrorCollection.dust.intValue,
            gold: mirrorCollection.gold.intValue
        )
    }
    
    private func uploadCollectionFromMainThread(
        collectionUploadData: UploadCollectionData,
        accountId: MirrorAccountId?) {
        setFeedback(message: NSLocalizedString("Uploading collection...", comment: ""), loading: true, timeoutMillis: -1)

        HSReplayAPI.uploadCollection(collectionData: collectionUploadData).done { result in
            switch result {
            case .successful:
                self.setFeedback(
                    message: NSLocalizedString("Your collection has been uploaded to HSReplay.net", comment: ""),
                    loading: false,
                    timeoutMillis: 5000)
            case .failed(let error):
                self.setFeedback(
                    message: NSLocalizedString("Failed to upload collection: \(error)", comment: ""),
                    loading: false,
                    timeoutMillis: 5000)
            }
        }.catch { error in
            logger.error("HSReplay: unexpected error: \(error)")
            self.setFeedback(
                message: NSLocalizedString("Failed to upload collection: \(error.localizedDescription)", comment: ""),
                loading: false,
                timeoutMillis: 5000)
        }
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
                    
                    logger.debug("Converting collection for upload")
                    let collectionUploadData = self.mirrorCollectionToCollectionUploadData(mirrorCollection: collection)
                    logger.debug("Done converting")
                    DispatchQueue.main.async {
                        logger.debug("Starting upload of collection")
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

