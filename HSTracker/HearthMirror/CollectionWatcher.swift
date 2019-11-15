//
//  CollectionWatcher.swift
//  HSTracker
//
//  Created by Martin BONNIN on 15/11/2019.
//  Copyright © 2019 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

class CollectionWatcher: Watcher {
    private var sent: Bool = false
    private var lastMessage: String = ""
    private var mirrorCollection: MirrorCollection?
    private var lastWorkItem: DispatchWorkItem?

    private(set) static var lastUploadedCollection: MirrorCollection?
    internal var uploadingInterval: TimeInterval = 5

    private let windowManager: WindowManager
    private let game: Game
        
    static private var _instance: CollectionWatcher?

    static func start(game: Game) {
        if _instance == nil {
            _instance = CollectionWatcher(game: game)
        }
        
        guard let instance = _instance else {
            return
        }
        instance.startWatching()
    }
    
    init(game: Game) {
        self.game = game
        self.windowManager = game.windowManager
    }

    static func stop() {
        guard let instance = _instance else {
            return
        }
        instance.stopWatching()
    }

    func setFeedback(message: String, displayed: Bool, delay: Double = 0) {
        if let workItem = lastWorkItem {
            if (displayed) {
                workItem.cancel()
            }
        }
        self.lastMessage = message
        
        lastWorkItem = DispatchWorkItem(block: {
            let collectionFeedback = self.windowManager.collectionFeedBack
            let rect = SizeHelper.collectionFeedbackFrame()

            self.windowManager.show(controller: collectionFeedback, show: displayed, frame: rect, title: nil, overlay: true)
            collectionFeedback.setMessage(message: message)
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: lastWorkItem!)
    }
    
    override func run() {
        while isRunning {
            
            if self.mirrorCollection == nil {
                mirrorCollection = MirrorHelper.getCollection()
            } else if !sent, let collection = mirrorCollection {
                sent = true
                setFeedback(message: "Uploading collection...", displayed: true)

                // convert mirror data into collection
                let data = UploadCollectionData(collection: collection.cards, favoriteHeroes: collection.favoriteHeroes, cardbacks: collection.cardbacks, favoriteCardback: collection.favoriteCardback.intValue, dust: collection.dust.intValue, gold: collection.gold.intValue)

                CollectionUploader.upload(collectionData: data) { result in
                    switch result {
                    case .successful:
                        self.setFeedback(
                            message: NSLocalizedString("Your collection has been uploaded to HSReplay.net", comment: ""),
                            displayed: true)
                    case .failed(let error):
                        self.setFeedback(
                            message: NSLocalizedString("Failed to upload collection: \(error)", comment: ""),
                            displayed: true)
                    }
                    
                    self.setFeedback(
                        message: "",
                        displayed: false,
                        delay: 5)
                }
            }
            
            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
}
