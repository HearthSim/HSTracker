//
//  AppDelegate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import CleanroomLogger
import MASPreferences
#if !DEBUG
import HockeySDK
#endif

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
        
        #if !DEBUG
        BITHockeyManager.sharedHockeyManager().configureWithIdentifier("2f0021b9bb1842829aa1cfbbd85d3bed")
        BITHockeyManager.sharedHockeyManager().crashManager.autoSubmitCrashReport = true
        BITHockeyManager.sharedHockeyManager().startManager()
        #endif

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
            let xcodeConfig = XcodeLogConfiguration(minimumSeverity: .Verbose,
                                                    logToASL: false,
                                                    colorTable: HSTrackerColorTable(),
                                                    formatters: [HSTrackerLogFormatter()])
            Log.enable(configuration: xcodeConfig)
        #else
            /*TODO 
             let rotatingConf = RotatingLogFileConfiguration(minimumSeverity: .Info,
                                                            daysToKeep: 7,
                                                            directoryPath: logDir)
            
            Log.enable(configuration: rotatingConf)*/
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
                NSThread.sleepForTimeInterval(0.5)
            }
            let game = Game.instance
            game.setPlayerTracker(self.playerTracker)
            game.setOpponentTracker(self.opponentTracker)
            game.setSecretTracker(self.secretTracker)
            game.setTimerHud(self.timerHud)
            game.setCardHuds(self.cardHuds)

            NSOperationQueue.mainQueue().addOperationWithBlock() {
                game.reset()
            }

            Hearthstone.instance.start()
        })
        let trackerOperation = NSBlockOperation(block: {
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                Log.info?.message("Opening trackers")
                self.openTrackers()
            }
        })
        let menuOperation = NSBlockOperation(block: {
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                Log.info?.message("Loading menu")
                self.buildMenu()
            }
        })

        startUpCompletionOperation.addDependency(loggingOperation)
        loggingOperation.addDependency(trackerOperation)
        loggingOperation.addDependency(menuOperation)
        trackerOperation.addDependency(databaseOperation)
        menuOperation.addDependency(databaseOperation)

        operationQueue.addOperation(startUpCompletionOperation)
        operationQueue.addOperation(trackerOperation)
        operationQueue.addOperation(databaseOperation)
        operationQueue.addOperation(loggingOperation)
        operationQueue.addOperation(menuOperation)
    }

    func hstrackerReady() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(AppDelegate.showPlayerTracker(_:)),
                                                         name: "show_player_tracker",
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(AppDelegate.showOpponentTracker(_:)),
                                                         name: "show_opponent_tracker",
                                                         object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(AppDelegate.reloadDecks(_:)),
                                                         name: "reload_decks",
                                                         object: nil)

        Log.info?.message("HSTracker is now ready !")
        
        if let activeDeck = Settings.instance.activeDeck, deck = Decks.byId(activeDeck) {
            Game.instance.setActiveDeck(deck)
        }
        
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
                Log.verbose?.value(deck)
            })
        } catch {
            Log.error?.value("error import")
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

    func reloadDecks(notification: NSNotification) {
        buildMenu()
    }
    
    // MARK: - Menu
    func buildMenu() {
        var decks = [String: [Deck]]()
        Decks.decks().filter({$0.isActive}).forEach({
            if decks[$0.playerClass] == nil {
                decks[$0.playerClass] = [Deck]()
            }
            decks[$0.playerClass]?.append($0)
        })
        
        let mainMenu = NSApplication.sharedApplication().mainMenu
        let deckMenu = mainMenu?.itemWithTitle("Decks")
        deckMenu?.submenu?.removeAllItems()
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Deck Manager", comment: ""),
                                            action: #selector(AppDelegate.openDeckManager(_:)),
                                            keyEquivalent: "d")
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Reset", comment: ""),
                                            action: #selector(AppDelegate.resetTrackers(_:)),
                                            keyEquivalent: "r")
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Clear", comment: ""),
                                            action: #selector(AppDelegate.clearTrackers(_:)),
                                            keyEquivalent: "")

        deckMenu?.submenu?.addItem(NSMenuItem.separatorItem())
        for (playerClass, _decks) in decks.sort({ NSLocalizedString($0.0, comment: "") < NSLocalizedString($1.0, comment: "") }) {
            if let menu = deckMenu?.submenu?.addItemWithTitle(NSLocalizedString(playerClass, comment: ""),
                                                              action: nil,
                                                              keyEquivalent: "") {
                let classMenu = NSMenu()
                _decks.sort({$0.name!.lowercaseString < $1.name!.lowercaseString }).forEach({
                    if let item = classMenu.addItemWithTitle($0.name!,
                        action: #selector(AppDelegate.playDeck(_:)),
                        keyEquivalent: "") {
                        item.representedObject = $0
                    }
                    
                })
                menu.submenu = classMenu
            }
        }
    }
    
    func playDeck(sender: NSMenuItem) {
        if let deck = sender.representedObject as? Deck {
            Settings.instance.activeDeck = deck.deckId
            Game.instance.setActiveDeck(deck)
        }
    }
    
    @IBAction func openDeckManager(sender: AnyObject) {
        deckManager = DeckManager()
        deckManager?.showWindow(self)
    }

    @IBAction func clearTrackers(sender: AnyObject) {
        Game.instance.removeActiveDeck()
        Settings.instance.activeDeck = nil
    }
    
    @IBAction func resetTrackers(sender: AnyObject) {
        Game.instance.opponent.reset()
        Game.instance.updateOpponentTracker()
    }

    @IBAction func openPreferences(sender: AnyObject) {
        preferences.showWindow(self)
    }

    @IBAction func lockWindows(sender: AnyObject) {
        let settings = Settings.instance
        settings.windowsLocked = !settings.windowsLocked
        // TODO menu
    }
    
    var windowMove: WindowMove?
    @IBAction func openDebugPositions(sender: AnyObject) {
        windowMove = WindowMove(windowNibName: "WindowMove")
        windowMove?.showWindow(self)
    }
}
