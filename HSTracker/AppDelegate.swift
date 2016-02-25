//
//  AppDelegate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import CocoaLumberjack
import MagicalRecord

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var splashscreen: Splashscreen?
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var initalConfig: InitialConfiguration?
    var deckManager: DeckManager?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        /*for (key,_) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
        }
        NSUserDefaults.standardUserDefaults().synchronize()*/
        
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey("hstracker_v2") {
            // welcome to HSTracker v2
        } else {
            for (key,_) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
            }
            NSUserDefaults.standardUserDefaults().synchronize()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hstracker_v2")
        }
        
        // init core data stuff
        MagicalRecord.setupAutoMigratingCoreDataStack()
        
        // init logger
        #if DEBUG
            DDTTYLogger.sharedInstance().colorsEnabled = true
            DDLog.addLogger(DDTTYLogger.sharedInstance())
        #else
            var fileLogger: DDFileLogger = DDFileLogger()
            fileLogger.rollingFrequency = 60 * 60 * 24
            fileLogger.logFileManager.maximumNumberOfLogFiles = 7
            DDLog.addLogger(fileLogger)
        #endif
        
        let hearthpwn = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        let hearthpwnDeckbuilder = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        let hearthstats = "http://hearthstats.net/decks/mage-meca--1049/public_show?locale=en"
        
        let url = hearthstats
        do {
            try NetImporter.netImport(url, { (deck) -> Void in
                DDLogVerbose("\(deck)")
            })
        } catch {
            DDLogVerbose("error")
        }
        
        /*MagicalRecord.saveWithBlockAndWait({ (localContext) -> Void in
            if let deck = Deck.MR_createEntityInContext(localContext) {
                deck.hearthstatsId = 6994742
                deck.hearthstatsVersionId = 7852777
                deck.isActive = true
                deck.isArena = false
                deck.name = "Control Shaman"
                deck.playerClass = "shaman"
                deck.version = "1.0"
                
                let cards = [
                    "EX1_259": 2,
                    "GVG_074": 1,
                    "AT_047": 2,
                    "EX1_575": 1,
                    "NEW1_010": 1,
                    "CS2_045": 1,
                    "CS2_042": 2,
                    "GVG_038": 1,
                    "FP1_001": 1,
                    "EX1_565": 1,
                    "LOE_029": 2,
                    "AT_090": 1,
                    "EX1_093": 1,
                    "AT_054": 1,
                    "AT_046": 2,
                    "EX1_016": 1,
                    "CS2_203": 1,
                    "GVG_110": 1,
                    "GVG_096": 2,
                    "EX1_246": 1,
                    "EX1_248": 2,
                    "EX1_245": 1,
                    "EX1_250": 1
                ]
                for (id, count) in cards {
                    if let deckCard = DeckCard.MR_createEntityInContext(localContext) {
                        deckCard.count = count
                        deckCard.cardId = id
                        deck.deckCards.insert(deckCard)
                    }
                }
            }
        })*/
        
        if Settings.instance.hearthstoneLanguage != nil && Settings.instance.hsTrackerLanguage != nil {
            loadSplashscreen()
        } else {
            initalConfig = InitialConfiguration(windowNibName: "InitialConfiguration")
            initalConfig!.completionHandler = {
                self.loadSplashscreen()
            }
            initalConfig!.showWindow(nil)
            initalConfig!.window?.orderFrontRegardless()
        }
    }
    
    func loadSplashscreen() {
        splashscreen = Splashscreen(windowNibName: "Splashscreen")
        splashscreen!.showWindow(self)
        let operationQueue = NSOperationQueue()
        
        let startUpCompletionOperation = NSBlockOperation(block: {
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                self.hstrackerReady()
            }
        })
        
        let databaseOperation = NSBlockOperation(block: {
            let database = Database()
            if let images = database.loadDatabaseIfNeeded(self.splashscreen!) {
                DDLogVerbose("need to download \(images)")
                let imageDownloader = ImageDownloader()
                imageDownloader.downloadImagesIfNeeded(images, splashscreen: self.splashscreen!)
            }
        })
        let loggingOperation = NSBlockOperation(block: {
            while true {
                if self.playerTracker != nil && self.opponentTracker != nil {
                    break
                }
                NSThread.sleepForTimeInterval(0.2)
            }
            DDLogInfo("Starting logging \(self.playerTracker) vs \(self.opponentTracker)")
            Game.instance.setPlayerTracker(self.playerTracker)
            Game.instance.setOpponentTracker(self.opponentTracker)
            Hearthstone.instance.start()
        })
        let trackerOperation = NSBlockOperation(block: {
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                DDLogInfo("Opening trackers")
                self.openTrackers()
            }
        })
        
        startUpCompletionOperation.addDependency(loggingOperation)
        loggingOperation.addDependency(trackerOperation)
        trackerOperation.addDependency(databaseOperation)
        
        operationQueue.addOperation(startUpCompletionOperation)
        operationQueue.addOperation(trackerOperation)
        operationQueue.addOperation(databaseOperation)
        operationQueue.addOperation(loggingOperation)
    }
    
    func hstrackerReady() {
        DDLogInfo("HSTracker is now ready !")
        if let splashscreen = splashscreen {
            splashscreen.close()
            self.splashscreen = nil
        }
    }
    
    func openTrackers() {
        self.playerTracker = Tracker(windowNibName: "Tracker")
        if let tracker = self.playerTracker {
            tracker.playerType = .Player
            tracker.showWindow(self)
        }
        
        self.opponentTracker = Tracker(windowNibName: "Tracker")
        if let tracker = self.opponentTracker {
            tracker.playerType = .Opponent
            tracker.showWindow(self)
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        
    }
    
    // MARK: - Menu
    @IBAction func openDeckManager(sender: AnyObject) {
        deckManager = DeckManager()
        deckManager?.showWindow(self)
        
    }
    
}

