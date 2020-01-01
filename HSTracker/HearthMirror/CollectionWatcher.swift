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

    private let windowManager: WindowManager
    
    var started: Bool = false
    static private var _instance: CollectionWatcher?

    static func start(windowManager: WindowManager) {
        if _instance == nil {
            _instance = CollectionWatcher(windowManager: windowManager)
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

    init(windowManager: WindowManager) {
        self.windowManager = windowManager

        let queue = DispatchQueue(label: "net.hearthsim.hstracker.watchers.\(type(of: self))",
            attributes: [])
        queue.async { [weak self] in
            self?.run()
        }
    }

    func setFeedback(message: String, loading: Bool, displayed: Bool) {
        if let workItem = lastWorkItem {
            workItem.cancel()
        }
        
        let collectionFeedback = self.windowManager.collectionFeedBack
        let rect = SizeHelper.collectionFeedbackFrame()

        self.windowManager.show(controller: collectionFeedback, show: displayed, frame: rect, title: nil, overlay: true)
        collectionFeedback.setMessage(message: message, loading: loading)
    }
    
    private func mirrorCollectionToCollectionUploadData(mirrorCollection: MirrorCollection) -> Kotlin_hsreplay_apiCollectionUploadData {
        
        let cardJson = AppDelegate.instance().coreManager.cardJson!

        var c = [:] as [String: [KotlinInt]]
        for mirrorCard in mirrorCollection.cards {
            let card = cardJson.getCard(id: mirrorCard.cardId)
            var counts = c[String(card.dbfId)] ?? [0, 0]
            if mirrorCard.premium {
                counts[1] = KotlinInt(value: mirrorCard.count.int32Value)
            } else {
                counts[0] = KotlinInt(value: mirrorCard.count.int32Value)
            }
            c[String(card.dbfId)] = counts
        }

        var h = [:] as [String: KotlinInt]
        for (playerclassid, mirrorCard) in mirrorCollection.favoriteHeroes {
            let card = cardJson.getCard(id: mirrorCard.cardId)
            h[String(playerclassid.intValue)] = KotlinInt(value: Int32(card.dbfId))
        }
        
        return Kotlin_hsreplay_apiCollectionUploadData(
            collection: c,
            favoriteHeroes: h,
            cardbacks: mirrorCollection.cardbacks.map {KotlinInt(value: $0.int32Value)},
            favoriteCardback: KotlinInt(value: mirrorCollection.favoriteCardback.int32Value),
            dust: KotlinInt(value: mirrorCollection.dust.int32Value),
            gold: KotlinInt(value: mirrorCollection.gold.int32Value)
        )
    }
    private func uploadCollectionFromMainThread(
        collectionUploadData: Kotlin_hsreplay_apiCollectionUploadData,
        accountId: MirrorAccountId?
    ) {
        setFeedback(message: "Uploading collection...", loading: true, displayed: true)

        AppDelegate.instance().coreManager.exposedHsReplay.uploadCollectionWithCallback(
            collectionUploadData: collectionUploadData,
            account_hi: "\(accountId?.hi ?? 0)",
            account_lo: "\(accountId?.lo ?? 0)",
            callback: {
                if $0 is ExposedHsReplay.ResultFailure {
                    // swiftlint:disable force_cast
                    let failure = ($0 as! ExposedHsReplay.ResultFailure)
                    // swiftlint:enable force_cast
                    
                    self.setFeedback(
                        message: NSLocalizedString("Failed to upload collection: \(failure.code)", comment: ""),
                        loading: false,
                        displayed: true)
                    
                    failure.throwable.printStackTrace()
                } else {
                    self.setFeedback(
                        message: NSLocalizedString("Your collection has been uploaded to HSReplay.net", comment: ""),
                        loading: false,
                        displayed: true)
                }
                self.lastWorkItem = DispatchWorkItem(block: {
                    self.setFeedback(message: "", loading: false, displayed: false)
                })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: self.lastWorkItem!)
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
                
                if !sent, let collection = mirrorCollection {
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
