//
//  AppDelegate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import CocoaLumberjack
import MASPreferences

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var splashscreen: Splashscreen?
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var secretTracker: SecretTracker?
    var timerHud: TimerHud?
    var cardHuds = [CardHud]()
    var initalConfig: InitialConfiguration?
    var deckManager: DeckManager?
    var preferences: MASPreferencesWindowController?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let app = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as! String
        print("\(app)")
        /*for (key,_) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
         NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
         }
         NSUserDefaults.standardUserDefaults().synchronize()*/

        if let _ = NSUserDefaults.standardUserDefaults().objectForKey("hstracker_v2") {
            // welcome to HSTracker v2
        } else {
            for (key, _) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
            }
            NSUserDefaults.standardUserDefaults().synchronize()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hstracker_v2")
        }

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
            if let images = database.loadDatabase(self.splashscreen!) {
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
            let game = Game.instance
            game.setPlayerTracker(self.playerTracker)
            game.setOpponentTracker(self.opponentTracker)
            game.setSecretTracker(self.secretTracker)
            game.setTimerHud(self.timerHud)
            game.setCardHuds(self.cardHuds)

            if let activeDeck = Settings.instance.activeDeck {
                if let deck = Decks.byId(activeDeck) {
                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        game.setActiveDeck(deck)
                        self.playerTracker?.update()
                    }
                }
            }
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                game.reset()
            }

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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showPlayerTracker:", name: "show_player_tracker", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showOpponentTracker:", name: "show_opponent_tracker", object: nil)

        DDLogInfo("HSTracker is now ready !")
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "hstracker_is_ready", object: nil))

        // let heartharena = "http://www.heartharena.com/arena-run/260979"
        // let hearthnews = "http://www.hearthnews.fr/decks/7070"
        // let hearthstoneDecks = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        // let hearthpwn = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        // let hearthpwnDeckbuilder = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        // let hearthstats = "http://hearthstats.net/decks/mage-meca--1049/public_show?locale=en"
        // let hearthhead = "http://www.hearthhead.com/deck=158864/fun-easy-win-dragon-warrior"

        /*let url = hearthhead
         do {
         try NetImporter.netImport(url, { (deck) -> Void in
         DDLogVerbose("\(deck)")
         })
         } catch {
         DDLogVerbose("error")
         }*/

        // testImportDeck()

        SizeHelper.hearthstoneFrame()
        if let splashscreen = splashscreen {
            splashscreen.close()
            self.splashscreen = nil
        }
    }

    private func testImportDeck() {
        let deck = Deck(playerClass: "shaman", name: "Control Shaman")
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
            for _ in 0 ..< count {
                if let card = Cards.byId(id) {
                    deck.addCard(card)
                }
            }
        }
        deck.save()
    }

    func openTrackers() {
        self.playerTracker = Tracker(windowNibName: "Tracker")
        if let tracker = self.playerTracker {
            tracker.playerType = .Player
            tracker.window?.setFrameAutosaveName("player_tracker")
            if Settings.instance.showPlayerTracker {
                tracker.showWindow(self)
            }
        }

        self.opponentTracker = Tracker(windowNibName: "Tracker")
        if let tracker = self.opponentTracker {
            tracker.playerType = .Opponent
            tracker.window?.setFrameAutosaveName("opponent_tracker")
            if Settings.instance.showOpponentTracker {
                tracker.showWindow(self)
            }
        }

        self.secretTracker = SecretTracker(windowNibName: "SecretTracker")
        if let tracker = self.secretTracker {
            tracker.showWindow(self)
        }

        self.timerHud = TimerHud(windowNibName: "TimerHud")
        if let tracker = self.timerHud {
            tracker.showWindow(self)
        }

        for _ in 0 ... 10 {
            let cardHud = CardHud(windowNibName: "CardHud")
            cardHuds.append(cardHud)
        }
    }

    func showPlayerTracker(notification: NSNotification) {
        if let tracker = self.playerTracker {
            showHideTracker(tracker, show: Settings.instance.showPlayerTracker)
        }
    }

    func showOpponentTracker(notification: NSNotification) {
        if let tracker = self.opponentTracker {
            showHideTracker(tracker, show: Settings.instance.showOpponentTracker)
        }
    }

    func showHideTracker(tracker: Tracker, show: Bool) {
        if show {
            tracker.showWindow(self)
        } else {
            tracker.close()
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }

    // MARK: - Menu
    @IBAction func openDeckManager(sender: AnyObject) {
        deckManager = DeckManager()
        deckManager?.showWindow(self)
    }

    @IBAction func clearTrackers(sender: AnyObject) {
        Game.instance.removeActiveDeck()
    }

    @IBAction func openPreferences(sender: AnyObject) {
        if preferences == nil {
            preferences = MASPreferencesWindowController(viewControllers: [
                GeneralPreferences(nibName: "GeneralPreferences", bundle: nil)!,
                GamePreferences(nibName: "GamePreferences", bundle: nil)!,
                TrackersPreferences(nibName: "TrackersPreferences", bundle: nil)!
                ], title: NSLocalizedString("Preferences", comment: ""))
        }
        if let preferences = preferences {
            preferences.showWindow(nil)
        }
    }

    @IBAction func lockWindows(sender: AnyObject) {
        let settings = Settings.instance
        settings.windowsLocked = !settings.windowsLocked
        // TODO menu
    }
}
