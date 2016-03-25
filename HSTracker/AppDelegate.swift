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
import HockeySDK

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
    var preferences: MASPreferencesWindowController = {
        let preferences = MASPreferencesWindowController(viewControllers: [
            GeneralPreferences(nibName: "GeneralPreferences", bundle: nil)!,
            GamePreferences(nibName: "GamePreferences", bundle: nil)!,
            TrackersPreferences(nibName: "TrackersPreferences", bundle: nil)!,
            HearthstatsPreferences(nibName: "HearthstatsPreferences", bundle: nil)!
            ], title: NSLocalizedString("Preferences", comment: ""))
        return preferences
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        /*for (key,_) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
         NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
         }
         NSUserDefaults.standardUserDefaults().synchronize()*/
        
        BITHockeyManager.sharedHockeyManager().configureWithIdentifier("2f0021b9bb1842829aa1cfbbd85d3bed")
        BITHockeyManager.sharedHockeyManager().crashManager.autoSubmitCrashReport = true
        BITHockeyManager.sharedHockeyManager().startManager()

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
            let fileLogger: DDFileLogger = DDFileLogger()
            fileLogger.rollingFrequency = 60 * 60 * 24
            fileLogger.logFileManager.maximumNumberOfLogFiles = 7
            DDLog.addLogger(fileLogger)
        #endif

        if Settings.instance.hearthstoneLanguage != nil && Settings.instance.hsTrackerLanguage != nil {
            loadSplashscreen()
        } else {
            initalConfig = InitialConfiguration(windowNibName: "InitialConfiguration")
            initalConfig?.completionHandler = {
                self.loadSplashscreen()
            }
            initalConfig?.showWindow(nil)
            initalConfig?.window?.orderFrontRegardless()
        }
    }

    func loadSplashscreen() {
        splashscreen = Splashscreen(windowNibName: "Splashscreen")
        splashscreen?.showWindow(self)
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.showPlayerTracker(_:)), name: "show_player_tracker", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.showOpponentTracker(_:)), name: "show_opponent_tracker", object: nil)

        DDLogInfo("HSTracker is now ready !")
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "hstracker_is_ready", object: nil))

        // testImportDeck()
        // testImportFromWeb()
        // testGetHearthstatsDecks()
        //testGetHearthstatsMatches()
        
        splashscreen?.close()
        splashscreen = nil
    }
    
    private func testGetHearthstatsMatches() {
        do {
            try HearthstatsAPI.getGames(Settings.instance.hearthstatsLastMatchesSync) {_ in }
        }
        catch HearthstatsError.NOT_LOGGED {
            print("not logged")
        }
        catch {
            print("??? logged")
        }
    }
    
    private func testGetHearthstatsDecks() {
        do {
            try HearthstatsAPI.getDecks(Settings.instance.hearthstatsLastDecksSync) { (success, newDecks) in
            }
        }
        catch HearthstatsError.NOT_LOGGED {
            print("not logged")
        }
        catch {
            print("??? logged")
        }
    }
    
    private func testImportFromWeb() {
        /*let heartharena = "http://www.heartharena.com/arena-run/260979"
        let hearthnews = "http://www.hearthnews.fr/decks/7070"
        let hearthstoneDecks = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        let hearthpwn = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        let hearthpwnDeckbuilder = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        let hearthstats = "http://hearthstats.net/decks/mage-meca--1049/public_show?locale=en"*/
        let hearthhead = "http://www.hearthhead.com/deck=158864/fun-easy-win-dragon-warrior"
        
        let url = hearthhead
        do {
            try NetImporter.netImport(url, { (deck) -> Void in
                DDLogVerbose("\(deck)")
            })
        } catch {
            DDLogVerbose("error")
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
        let settings = Settings.instance
        
        self.playerTracker = Tracker(windowNibName: "Tracker")
        self.playerTracker?.playerType = .Player
        self.playerTracker?.window?.setFrameAutosaveName("player_tracker")
        if settings.showPlayerTracker {
            self.playerTracker?.showWindow(self)
        }
        
        self.opponentTracker = Tracker(windowNibName: "Tracker")
        self.opponentTracker?.playerType = .Opponent
        self.opponentTracker?.window?.setFrameAutosaveName("opponent_tracker")
        if settings.showOpponentTracker {
            self.opponentTracker?.showWindow(self)
        }
        
        self.secretTracker = SecretTracker(windowNibName: "SecretTracker")
        self.secretTracker?.showWindow(self)
        
        self.timerHud = TimerHud(windowNibName: "TimerHud")
        self.timerHud?.showWindow(self)
        
        for _ in 0 ..< 10 {
            let cardHud = CardHud(windowNibName: "CardHud")
            cardHuds.append(cardHud)
        }
    }
    
    func showPlayerTracker(notification: NSNotification) {
        showHideTracker(self.playerTracker, show: Settings.instance.showPlayerTracker)
    }
    
    func showOpponentTracker(notification: NSNotification) {
        showHideTracker(self.opponentTracker, show: Settings.instance.showOpponentTracker)
    }
    
    func showHideTracker(tracker: Tracker?, show: Bool) {
        if show {
            tracker?.showWindow(self)
        } else {
            tracker?.close()
        }
    }

    // MARK: - Menu
    @IBAction func openDeckManager(sender: AnyObject) {
        deckManager = DeckManager()
        deckManager?.showWindow(self)
    }

    @IBAction func clearTrackers(sender: AnyObject) {
        Game.instance.removeActiveDeck()
        Settings.instance.activeDeck = nil
    }

    @IBAction func openPreferences(sender: AnyObject) {
        preferences.showWindow(nil)
    }

    @IBAction func lockWindows(sender: AnyObject) {
        let settings = Settings.instance
        settings.windowsLocked = !settings.windowsLocked
        // TODO menu
    }
}
