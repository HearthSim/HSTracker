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
import HockeySDK

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    var appWillRestart = false
    var splashscreen: Splashscreen?
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var secretTracker: SecretTracker?
    var timerHud: TimerHud?
    var cardHuds = [CardHud]()
    var initalConfig: InitialConfiguration?
    var deckManager: DeckManager?
    var floatingCard: FloatingCard?
    @IBOutlet weak var sparkleUpdater: SUUpdater!
    var operationQueue: NSOperationQueue?
    var hstrackerIsStarted = false

    var preferences: MASPreferencesWindowController = {
        let preferences = MASPreferencesWindowController(viewControllers: [
            GeneralPreferences(nibName: "GeneralPreferences", bundle: nil)!,
            GamePreferences(nibName: "GamePreferences", bundle: nil)!,
            TrackersPreferences(nibName: "TrackersPreferences", bundle: nil)!,
            PlayerTrackersPreferences(nibName: "PlayerTrackersPreferences", bundle: nil)!,
            OpponentTrackersPreferences(nibName: "OpponentTrackersPreferences", bundle: nil)!,
            HearthstatsPreferences(nibName: "HearthstatsPreferences", bundle: nil)!
            ], title: NSLocalizedString("Preferences", comment: ""))
        return preferences
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        #if !DEBUG
        sparkleUpdater.sendsSystemProfile = true
        BITHockeyManager.sharedHockeyManager()
            .configureWithIdentifier("2f0021b9bb1842829aa1cfbbd85d3bed")
        BITHockeyManager.sharedHockeyManager().crashManager.autoSubmitCrashReport = true
        BITHockeyManager.sharedHockeyManager().debugLogEnabled = false
        BITHockeyManager.sharedHockeyManager().delegate = self
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

        let settings = Settings.instance

        // init logger
        var loggers = [LogConfiguration]()
        let xcodeConfig = XcodeLogConfiguration(minimumSeverity: .Verbose,
                                                logToASL: false,
                                                colorTable: HSTrackerColorTable(),
                                                formatters: [HSTrackerLogFormatter()])
        loggers.append(xcodeConfig)

        if let path = NSSearchPathForDirectoriesInDomains(.LibraryDirectory,
                                                          .UserDomainMask, true).first {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(
                    "\(path)/Logs/HSTracker",
                    withIntermediateDirectories: true,
                    attributes: nil)
                let severity: LogSeverity = Settings.instance.logSeverity
                // swiftlint:disable line_length
                let rotatingConf = RotatingLogFileConfiguration(minimumSeverity: severity,
                                                                daysToKeep: 7,
                                                                directoryPath: "\(path)/Logs/HSTracker",
                                                                formatters: [HSTrackerLogFormatter()])
                // swiftlint:enable line_length
                loggers.append(rotatingConf)
            } catch { }
        }
        Log.enable(configuration: loggers)

        // swiftlint:disable line_length
        var version = ""
        if let release = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String,
            build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
            version = "\(release).\(build) "
        }
        Log.info?.message("*** Starting HSTracker \(version)***")
        // swiftlint:enable line_length

        if settings.hearthstoneLogPath.endsWith("/Logs") {
           settings.hearthstoneLogPath = settings.hearthstoneLogPath.replace("/Logs", with: "")
        }

        if settings.validated() {
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

    func applicationWillTerminate(notification: NSNotification) {
        Hearthstone.instance.stopTracking()
        if appWillRestart {
            let appPath = NSBundle.mainBundle().bundlePath
            let task = NSTask()
            task.launchPath = "/usr/bin/open"
            task.arguments = [appPath]
            task.launch()
        }
    }

    // MARK: - Application init
    func loadSplashscreen() {
        splashscreen = Splashscreen(windowNibName: "Splashscreen")
        let screenFrame = NSScreen.mainScreen()!.frame
        let splashscreenWidth: CGFloat = 350
        let splashscreenHeight: CGFloat = 250

        splashscreen?.window?.setFrame(NSRect(
            x: (NSWidth(screenFrame) / 2) - (splashscreenWidth / 2),
            y: (NSHeight(screenFrame) / 2) - (splashscreenHeight / 2),
            width: splashscreenWidth,
            height: splashscreenHeight),
                                       display: true)
        splashscreen?.showWindow(self)

        let databaseOperation = NSBlockOperation {
            let database = Database()
            if let images = database.loadDatabase(self.splashscreen!) {
                let imageDownloader = ImageDownloader()
                imageDownloader.deleteImages()
                imageDownloader.downloadImagesIfNeeded(images, splashscreen: self.splashscreen!)
            }
        }
        let decksOperation = NSBlockOperation {
            Log.info?.message("Loading decks")
            dispatch_async(dispatch_get_main_queue()) {
                self.splashscreen?.display(NSLocalizedString("Loading decks", comment: ""),
                    indeterminate: true)
            }
            Decks.instance.loadDecks()
        }
        let loggingOperation = NSBlockOperation {
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
        }

        let trackerOperation = NSBlockOperation {
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                Log.info?.message("Opening trackers")
                self.openTrackers()
            }
        }
        let menuOperation = NSBlockOperation {
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                Log.info?.message("Loading menu")
                self.buildMenu()
            }
        }

        loggingOperation.addDependency(trackerOperation)
        loggingOperation.addDependency(menuOperation)
        decksOperation.addDependency(databaseOperation)
        trackerOperation.addDependency(decksOperation)
        menuOperation.addDependency(decksOperation)

        operationQueue = NSOperationQueue()
        operationQueue?.addOperation(trackerOperation)
        operationQueue?.addOperation(databaseOperation)
        operationQueue?.addOperation(decksOperation)
        operationQueue?.addOperation(loggingOperation)
        operationQueue?.addOperation(menuOperation)

        operationQueue?.addObserver(self,
                                   forKeyPath: "operations",
                                   options: NSKeyValueObservingOptions.New,
                                   context: nil)
    }

    override func observeValueForKeyPath(keyPath: String?,
                                         ofObject object: AnyObject?,
                                                  change: [String : AnyObject]?,
                                                  context: UnsafeMutablePointer<Void>) {
        if let keyPath = keyPath, operationQueue = operationQueue,
            object = object as? NSOperationQueue {

            if object == operationQueue && keyPath == "operations" {
                if operationQueue.operationCount == 0 {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.hstrackerReady()
                    }
                }
                return
            }
        }
        super.observeValueForKeyPath(keyPath,
                                     ofObject: object,
                                     change: change,
                                     context: context)
    }

    func hstrackerReady() {
        guard !hstrackerIsStarted else { return }
        hstrackerIsStarted = true

        operationQueue?.removeObserver(self, forKeyPath: "operations")
        operationQueue = nil

        var message: String?
        var alertStyle = NSAlertStyle.CriticalAlertStyle
        do {
            let canStart = try Hearthstone.instance.setup()

            if !canStart {
                message = "You must restart Hearthstone for logs to be used"
                alertStyle = .InformationalAlertStyle
            }
        } catch HearthstoneLogError.CanNotCreateDir {
            message = "Can not create Hearthstone config dir"
        } catch HearthstoneLogError.CanNotReadFile {
            message = "Can not read Hearthstone config file"
        } catch HearthstoneLogError.CanNotCreateFile {
            message = "Can not write Hearthstone config file"
        } catch {
            message = "Unknown error"
        }

        if let message = message {
            splashscreen?.close()
            splashscreen = nil

            if alertStyle == .CriticalAlertStyle {
                Log.error?.message(message)
            }

            let alert = NSAlert()
            alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
            alert.informativeText = NSLocalizedString(message, comment: "")
            alert.alertStyle = alertStyle
            NSRunningApplication.currentApplication().activateWithOptions([
                NSApplicationActivationOptions.ActivateAllWindows,
                NSApplicationActivationOptions.ActivateIgnoringOtherApps])
            NSApp.activateIgnoringOtherApps(true)
            alert.runModal()
            return
        }



        Hearthstone.instance.start()
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self

        let events = [
            "show_player_tracker": #selector(AppDelegate.showPlayerTracker(_:)),
            "show_opponent_tracker": #selector(AppDelegate.showOpponentTracker(_:)),
            "reload_decks": #selector(AppDelegate.reloadDecks(_:)),
            "hstracker_language": #selector(AppDelegate.languageChange(_:)),
            "show_floating_card": #selector(AppDelegate.showFloatingCard(_:)),
            "hide_floating_card": #selector(AppDelegate.hideFloatingCard(_:)),
            "theme": #selector(AppDelegate.reloadTheme(_:))
        ]

        for (event, selector) in events {
            NSNotificationCenter.defaultCenter().addObserver(self,
                                                             selector: selector,
                                                             name: event,
                                                             object: nil)
        }

        Log.info?.message("HSTracker is now ready !")

        if let activeDeck = Settings.instance.activeDeck, deck = Decks.instance.byId(activeDeck) {
            Game.instance.setActiveDeck(deck)
        }

        NSNotificationCenter.defaultCenter()
            .postNotification(NSNotification(name: "hstracker_is_ready", object: nil))

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
        } catch HearthstatsError.NotLogged {
            print("not logged")
        } catch {
            print("??? logged")
        }
    }

    private func testGetHearthstatsDecks() {
        do {
            try HearthstatsAPI.loadDecks(true) { (success, newDecks) in }
        } catch HearthstatsError.NotLogged {
            print("not logged")
        } catch {
            print("??? logged")
        }
    }

    private func testImportFromWeb() {
        // swiftlint:disable line_length
        /*let heartharena = "http://www.heartharena.com/arena-run/260979"
        let hearthnews = "http://www.hearthnews.fr/decks/7070"
        let hearthstoneDecks = "http://www.hearthstone-decks.com/deck/voir/reno-reincarnation-7844"
        let hearthpwn = "http://www.hearthpwn.com/decks/432773-ostkakas-standard-miracle-rogue"
        let hearthpwnDeckbuilder = "http://www.hearthpwn.com/deckbuilder/warrior#50:2;73:1;96:1;215:2;227:2;297:2;493:2;632:1;644:1;7734:2;7749:2;12215:2;14448:1;14464:2;22264:1;22276:1;22309:2;27210:1;27211:2"
        let hearthstats = "http://hearthstats.net/decks/mage-meca--1049/public_show?locale=en"*/
        let hearthhead = "http://www.hearthhead.com/deck=158864/fun-easy-win-dragon-warrior"
        // swiftlint:enable line_length

        let url = hearthhead
        do {
            try NetImporter.netImport(url, completion: { (deck) -> Void in
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
        Decks.instance.add(deck)
    }

    func openTrackers() {
        let settings = Settings.instance

        let screenFrame = NSScreen.mainScreen()!.frame
        let y = NSHeight(screenFrame) - 50
        let width: CGFloat
        switch settings.cardSize {
        case .Small:
            width = CGFloat(kSmallFrameWidth)

        case .Medium:
            width = CGFloat(kMediumFrameWidth)

        default:
            width = CGFloat(kFrameWidth)
        }

        playerTracker = Tracker(windowNibName: "Tracker")
        playerTracker?.playerType = .Player
        if let rect = settings.playerTrackerFrame {
            playerTracker?.window?.setFrame(rect, display: true)
        } else {
            let x = NSWidth(screenFrame) - width
            playerTracker?.window?.setFrame(NSRect(x: x, y: y, width: width, height: y),
                                            display: true)
        }
        showPlayerTracker(nil)

        opponentTracker = Tracker(windowNibName: "Tracker")
        opponentTracker?.playerType = .Opponent

        if let rect = settings.opponentTrackerFrame {
            opponentTracker?.window?.setFrame(rect, display: true)
        } else {
            opponentTracker?.window?.setFrame(NSRect(x: 50, y: y, width: width, height: y),
                                              display: true)
        }
        showOpponentTracker(nil)

        secretTracker = SecretTracker(windowNibName: "SecretTracker")
        secretTracker?.showWindow(self)

        timerHud = TimerHud(windowNibName: "TimerHud")
        timerHud?.showWindow(self)

        for _ in 0 ..< 10 {
            let cardHud = CardHud(windowNibName: "CardHud")
            cardHuds.append(cardHud)
        }

        floatingCard = FloatingCard(windowNibName: "FloatingCard")
        floatingCard?.showWindow(self)
        floatingCard?.window?.orderOut(self)
    }

    func showPlayerTracker(notification: NSNotification?) {
        showHideTracker(self.playerTracker,
                        show: Settings.instance.showPlayerTracker,
                        title: "Player tracker")
    }

    func showOpponentTracker(notification: NSNotification?) {
        showHideTracker(self.opponentTracker,
                        show: Settings.instance.showOpponentTracker,
                        title: "Opponent tracker")
    }

    func showHideTracker(tracker: Tracker?, show: Bool, title: String) {
        if show {
            tracker?.showWindow(self)
            if let window = tracker?.window {
                NSApp.addWindowsItem(window,
                                     title: NSLocalizedString(title, comment: ""),
                                     filename: false)
                window.title = NSLocalizedString(title, comment: "")
            }
        } else {
            if let window = tracker?.window {
                NSApp.removeWindowsItem(window)
            }
            tracker?.window?.orderOut(self)
        }
    }

    func reloadDecks(notification: NSNotification) {
        buildMenu()
    }

    func reloadTheme(notification: NSNotification) {
        Game.instance.updatePlayerTracker(true)
        Game.instance.updateOpponentTracker(true)
    }

    var closeFloatingCardRequest = 0
    var closeRequestTimer: NSTimer?
    func showFloatingCard(notification: NSNotification) {
        guard Settings.instance.showFloatingCard else {return}

        if let card = notification.userInfo?["card"] as? Card,
            arrayFrame = notification.userInfo?["frame"] as? [CGFloat] {
            if closeRequestTimer != nil {
                closeRequestTimer?.invalidate()
                closeRequestTimer = nil
            }

            closeFloatingCardRequest += 1
            floatingCard?.showWindow(self)
            let frame = NSRect(x: arrayFrame[0],
                               y: arrayFrame[1],
                               width: arrayFrame[2],
                               height: arrayFrame[3])
            floatingCard?.window?.setFrame(frame, display: true)
            floatingCard?.setCard(card)

            closeRequestTimer = NSTimer.scheduledTimerWithTimeInterval(
                3,
                target: self,
                selector: #selector(AppDelegate.forceHideFloatingCard),
                userInfo: nil,
                repeats: false)

        }
    }

    func forceHideFloatingCard() {
        closeFloatingCardRequest = 0
        floatingCard?.window?.orderOut(self)
        closeRequestTimer?.invalidate()
        closeRequestTimer = nil
    }

    func hideFloatingCard(notification: NSNotification) {
        guard Settings.instance.showFloatingCard else {return}

        self.closeFloatingCardRequest -= 1
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(100 * Double(NSEC_PER_MSEC)))
        let queue = dispatch_get_main_queue()
        dispatch_after(when, queue) {
            if self.closeFloatingCardRequest > 0 {
                return
            }
            self.closeFloatingCardRequest = 0
            self.floatingCard?.window?.orderOut(self)
            self.closeRequestTimer?.invalidate()
            self.closeRequestTimer = nil
        }
    }

    func showHideCardHuds(notification: NSNotification) {
        Game.instance.updateCardHuds(true)
    }

    func languageChange(notification: NSNotification) {
        let alert = NSAlert()
        alert.alertStyle = .InformationalAlertStyle
        // swiftlint:disable line_length
        alert.messageText = NSLocalizedString("You must restart HSTracker for the language change to take effect", comment: "")
        // swiftlint:enable line_length
        alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        alert.runModal()

        appWillRestart = true
        NSApplication.sharedApplication().terminate(nil)
        exit(0)
    }

    // MARK: - Menu
    func buildMenu() {
        var decks = [String: [Deck]]()
        Decks.instance.decks().filter({$0.isActive}).forEach({
            if decks[$0.playerClass] == nil {
                decks[$0.playerClass] = [Deck]()
            }
            decks[$0.playerClass]?.append($0)
        })

        let mainMenu = NSApplication.sharedApplication().mainMenu
        let deckMenu = mainMenu?.itemWithTitle(NSLocalizedString("Decks", comment: ""))
        deckMenu?.submenu?.removeAllItems()
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Deck Manager", comment: ""),
                                            action: #selector(AppDelegate.openDeckManager(_:)),
                                            keyEquivalent: "d")
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Reset", comment: ""),
                                            action: #selector(AppDelegate.resetTrackers(_:)),
                                            keyEquivalent: "r")
        let saveMenus = NSMenu()
        saveMenus.addItemWithTitle(NSLocalizedString("Save Current Deck", comment: ""),
                                   action: #selector(AppDelegate.saveCurrentDeck(_:)),
                                   keyEquivalent: "")?.tag = 2
        saveMenus.addItemWithTitle(NSLocalizedString("Save Opponent's Deck", comment: ""),
                                   action: #selector(AppDelegate.saveCurrentDeck(_:)),
                                   keyEquivalent: "")?.tag = 1
        saveMenus.addItemWithTitle(NSLocalizedString("Save Arena Deck", comment: ""),
                                   action: #selector(AppDelegate.saveArenaDeck(_:)),
                                   keyEquivalent: "")
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Save", comment: ""),
                                            action: nil,
                                            keyEquivalent: "")?.submenu = saveMenus
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Clear", comment: ""),
                                            action: #selector(AppDelegate.clearTrackers(_:)),
                                            keyEquivalent: "")

        deckMenu?.submenu?.addItem(NSMenuItem.separatorItem())
        for (playerClass, _decks) in decks
            .sort({ NSLocalizedString($0.0, comment: "") < NSLocalizedString($1.0, comment: "") }) {
                if let menu = deckMenu?.submenu?
                    .addItemWithTitle(NSLocalizedString(playerClass, comment: ""),
                                      action: nil,
                                      keyEquivalent: "") {
                let classMenu = NSMenu()
                _decks.filter({ $0.isActive == true })
                    .sort({$0.name!.lowercaseString < $1.name!.lowercaseString })
                    .forEach({
                    if let item = classMenu.addItemWithTitle($0.name!,
                        action: #selector(AppDelegate.playDeck(_:)),
                        keyEquivalent: "") {
                        item.representedObject = $0
                    }

                })
                menu.submenu = classMenu
            }
        }

        let settings = Settings.instance
        let windowMenu = mainMenu?.itemWithTitle(NSLocalizedString("Window", comment: ""))
        // swiftlint:disable line_length
        let item = windowMenu?.submenu?.itemWithTitle(NSLocalizedString("Lock windows", comment: ""))
        item?.title = NSLocalizedString(settings.windowsLocked ?  "Unlock windows" : "Lock windows", comment: "")
        // swiftlint:enable line_length
    }

    func playDeck(sender: NSMenuItem) {
        if let deck = sender.representedObject as? Deck {
            Settings.instance.activeDeck = deck.deckId
            Game.instance.setActiveDeck(deck)
        }
    }

    @IBAction func openDeckManager(sender: AnyObject) {
        if deckManager == nil {
            deckManager = DeckManager(windowNibName: "DeckManager")
        }
        deckManager?.showWindow(self)
    }

    @IBAction func clearTrackers(sender: AnyObject) {
        Game.instance.removeActiveDeck()
        Settings.instance.activeDeck = nil
    }

    @IBAction func saveCurrentDeck(sender: AnyObject) {
        switch sender.tag {
        case 1: // Opponent
            saveDeck(Game.instance.opponent)
        case 2: // Self
            saveDeck(Game.instance.player)
        default:
            break
        }
    }

    func saveDeck(player: Player) {
        if let playerClass = player.playerClass {
            let deck = Deck(playerClass: playerClass)
            player.playerCardList.filter({ $0.collectible == true }).forEach({ deck.addCard($0) })

            if deckManager == nil {
                deckManager = DeckManager(windowNibName: "DeckManager")
            }
            deckManager?.currentDeck = deck
            deckManager?.editDeck(self)
        }
    }
    
    @IBAction func saveArenaDeck(sender: AnyObject) {
        if let deck = Draft.instance.deck {
            if deckManager == nil {
                deckManager = DeckManager(windowNibName: "DeckManager")
            }
            deckManager?.currentDeck = deck
            deckManager?.editDeck(self)
        } else {
            Log.error?.message("Arena deck doesn't exist. How?")
        }
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
        let mainMenu = NSApplication.sharedApplication().mainMenu
        let windowMenu = mainMenu?.itemWithTitle(NSLocalizedString("Window", comment: ""))
        let text = settings.windowsLocked ? "Unlock windows" : "Lock windows"
        let item = windowMenu?.submenu?.itemWithTitle(NSLocalizedString(text, comment: ""))
        settings.windowsLocked = !settings.windowsLocked
        // swiftlint:disable line_length
        item?.title = NSLocalizedString(settings.windowsLocked ?  "Unlock windows" : "Lock windows", comment: "")
        // swiftlint:enable line_length
    }

    var windowMove: WindowMove?
    @IBAction func openDebugPositions(sender: AnyObject) {
        if windowMove == nil {
            windowMove = WindowMove(windowNibName: "WindowMove")
        }
        windowMove?.showWindow(self)
    }

    @IBAction func closeWindow(sender: AnyObject) {

    }

    // MARK: NSUserNotificationCenterDelegate
    func sendNotification(title: String, info: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = info
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }

    // swiftlint:disable line_length
    func userNotificationCenter(center: NSUserNotificationCenter,
                                shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    // swiftlint:enable line_length
}

extension AppDelegate: SUUpdaterDelegate {
    func feedParametersForUpdater(updater: SUUpdater!,
                                  sendingSystemProfile sendingProfile: Bool) -> [AnyObject]! {
        return BITSystemProfile.sharedSystemProfile().systemUsageData()
            as NSMutableArray as [AnyObject]
    }
}

extension AppDelegate: BITHockeyManagerDelegate {
    // swiftlint:disable line_length
    func applicationLogForCrashManager(crashManager: BITCrashManager!) -> String! {
        let fmt = NSDateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'.log'"

        if let path = NSSearchPathForDirectoriesInDomains(.LibraryDirectory,
                                                          .UserDomainMask, true).first {
            let file = "\(path)/Logs/HSTracker/\(fmt.stringFromDate(NSDate()))"

            if NSFileManager.defaultManager().fileExistsAtPath(file) {
                do {
                    let content = try String(contentsOfFile: file)
                    return Array(content
                        .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                        .reverse() // reverse to keep 400 last lines
                        .prefix(400))
                        .reverse() // re-reverse them
                        .joinWithSeparator("\n")
                } catch {}
            }
        }

        return ""
    }
    // swiftlint:enable line_length
}
