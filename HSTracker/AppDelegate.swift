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
class AppDelegate: NSObject, NSApplicationDelegate {

    var appWillRestart = false
    var splashscreen: Splashscreen?
    var playerTracker: Tracker?
    var opponentTracker: Tracker?
    var secretTracker: SecretTracker?
    var playerBoardDamage: BoardDamage?
    var opponentBoardDamage: BoardDamage?
    var timerHud: TimerHud?
    var cardHudContainer: CardHudContainer?
    var initalConfig: InitialConfiguration?
    var deckManager: DeckManager?
    var floatingCard: FloatingCard?
    @IBOutlet weak var sparkleUpdater: SUUpdater!
    var operationQueue: NSOperationQueue?
    var hstrackerIsStarted = false
    var dockMenu = NSMenu(title: "DockMenu")

    var preferences: MASPreferencesWindowController = {
        let preferences = MASPreferencesWindowController(viewControllers: [
            GeneralPreferences(nibName: "GeneralPreferences", bundle: nil)!,
            UpdatePreferences(nibName: "UpdatePreferences", bundle: nil)!,
            GamePreferences(nibName: "GamePreferences", bundle: nil)!,
            TrackersPreferences(nibName: "TrackersPreferences", bundle: nil)!,
            PlayerTrackersPreferences(nibName: "PlayerTrackersPreferences", bundle: nil)!,
            OpponentTrackersPreferences(nibName: "OpponentTrackersPreferences", bundle: nil)!,
            HSReplayPreferences(nibName: "HSReplayPreferences", bundle: nil)!,
            HearthstatsPreferences(nibName: "HearthstatsPreferences", bundle: nil)!,
            TrackOBotPreferences(nibName: "TrackOBotPreferences", bundle: nil)!
            ], title: NSLocalizedString("Preferences", comment: ""))
        return preferences
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let settings = Settings.instance
        
        let hockeyKey = "2f0021b9bb1842829aa1cfbbd85d3bed"
        /*if settings.releaseChannel == .beta {
            hockeyKey = "c8af7f051ae14d0eb67438f27c3d9dc1"
        }*/

        let url = "https://hsdecktracker.net/hstracker/appcast.xml"
        sparkleUpdater.feedURL = NSURL(string: url)
        sparkleUpdater.sendsSystemProfile = true
        sparkleUpdater.automaticallyDownloadsUpdates = settings.automaticallyDownloadsUpdates

        BITHockeyManager.sharedHockeyManager().configureWithIdentifier(hockeyKey)
        BITHockeyManager.sharedHockeyManager().crashManager.autoSubmitCrashReport = true
        BITHockeyManager.sharedHockeyManager().delegate = self
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
        var loggers = [LogConfiguration]()
        #if DEBUG
            let xcodeConfig = XcodeLogConfiguration(minimumSeverity: .verbose,
                                                    logToASL: false,
                                                    colorizer: nil,
                                                    formatter: HSTrackerLogFormatter())
        loggers.append(xcodeConfig)
        #endif

        if let path = NSSearchPathForDirectoriesInDomains(.LibraryDirectory,
                                                          .UserDomainMask, true).first {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(
                    "\(path)/Logs/HSTracker",
                    withIntermediateDirectories: true,
                    attributes: nil)
                let severity = Settings.instance.logSeverity
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

        Log.info?.message("*** Starting \(Version.buildName)***")

        if settings.hearthstoneLogPath.hasSuffix("/Logs") {
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
        let screenFrame = NSScreen.screens()!.first!.frame
        let splashscreenWidth: CGFloat = 350
        let splashscreenHeight: CGFloat = 250

        splashscreen?.window?.setFrame(NSRect(
            x: (screenFrame.width / 2) - (splashscreenWidth / 2),
            y: (screenFrame.height / 2) - (splashscreenHeight / 2),
            width: splashscreenWidth,
            height: splashscreenHeight),
                                       display: true)
        splashscreen?.showWindow(self)

        let buildsOperation = NSBlockOperation {
            BuildDates.loadBuilds(self.splashscreen!)
            if BuildDates.isOutdated() {
                BuildDates.downloadCards(self.splashscreen!)
            }
        }

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
            Decks.instance.loadDecks(self.splashscreen)
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
            game.secretTracker = self.secretTracker
            game.timerHud = self.timerHud
            game.cardHudContainer = self.cardHudContainer
            game.playerBoardDamage = self.playerBoardDamage
            game.opponentBoardDamage = self.opponentBoardDamage

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

        databaseOperation.addDependency(buildsOperation)
        loggingOperation.addDependency(trackerOperation)
        loggingOperation.addDependency(menuOperation)
        decksOperation.addDependency(databaseOperation)
        trackerOperation.addDependency(decksOperation)
        menuOperation.addDependency(decksOperation)

        operationQueue = NSOperationQueue()
        operationQueue?.addOperation(buildsOperation)
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

    // debug stuff 
    //var window: NSWindow?
    func hstrackerReady() {
        guard !hstrackerIsStarted else { return }
        hstrackerIsStarted = true

        operationQueue?.removeObserver(self, forKeyPath: "operations")
        operationQueue = nil

        var message: String?
        var alertStyle = NSAlertStyle.Critical
        do {
            let canStart = try Hearthstone.instance.setup()

            if !canStart {
                message = "You must restart Hearthstone for logs to be used"
                alertStyle = .Informational
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

            if alertStyle == .Critical {
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
        
        let events = [
            "show_player_tracker": #selector(AppDelegate.showPlayerTracker(_:)),
            "show_opponent_tracker": #selector(AppDelegate.showOpponentTracker(_:)),
            "reload_decks": #selector(AppDelegate.reloadDecks(_:)),
            "hstracker_language": #selector(AppDelegate.languageChange(_:)),
            "show_floating_card": #selector(AppDelegate.showFloatingCard(_:)),
            "hide_floating_card": #selector(AppDelegate.hideFloatingCard(_:)),
            "theme": #selector(AppDelegate.reloadTheme(_:)),
            "save_arena_deck": #selector(AppDelegate.saveArenaDeck(_:)),
        ]

        for (event, selector) in events {
            NSNotificationCenter.defaultCenter().addObserver(self,
                                                             selector: selector,
                                                             name: event,
                                                             object: nil)
        }

        if let activeDeck = Settings.instance.activeDeck, deck = Decks.instance.byId(activeDeck) {
            Game.instance.setActiveDeck(deck)
        }

        NSNotificationCenter.defaultCenter()
            .postNotification(NSNotification(name: "hstracker_is_ready", object: nil))

        splashscreen?.close()
        splashscreen = nil
    }

    func openTrackers() {
        let settings = Settings.instance

        let screenFrame = NSScreen.mainScreen()!.frame
        let y = screenFrame.height - 50
        let width: CGFloat
        switch settings.cardSize {
        case .Small: width = CGFloat(kSmallFrameWidth)
        case .Medium: width = CGFloat(kMediumFrameWidth)
        case .Big: width = CGFloat(kFrameWidth)
        case .VeryBig: width = CGFloat(kHighRowFrameWidth)
        }

        playerTracker = Tracker(windowNibName: "Tracker")
        playerTracker?.playerType = .Player
        if let rect = settings.playerTrackerFrame {
            playerTracker?.window?.setFrame(rect, display: true)
        } else {
            let x = screenFrame.width - width
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
        timerHud?.window?.orderOut(self)
        
        playerBoardDamage = BoardDamage(windowNibName: "BoardDamage")
        playerBoardDamage?.showWindow(self)
        playerBoardDamage?.window?.orderOut(self)
        
        opponentBoardDamage = BoardDamage(windowNibName: "BoardDamage")
        opponentBoardDamage?.showWindow(self)
        opponentBoardDamage?.window?.orderOut(self)

        cardHudContainer = CardHudContainer(windowNibName: "CardHudContainer")
        cardHudContainer?.showWindow(self)

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
        alert.alertStyle = .Informational
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
        var decks = [CardClass: [Deck]]()
        Decks.instance.decks().filter({$0.isActive}).forEach({
            if decks[$0.playerClass] == nil {
                decks[$0.playerClass] = [Deck]()
            }
            decks[$0.playerClass]?.append($0)
        })

        // build main menu
        // ---------------
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
                                   keyEquivalent: "").tag = 2
        saveMenus.addItemWithTitle(NSLocalizedString("Save Opponent's Deck", comment: ""),
                                   action: #selector(AppDelegate.saveCurrentDeck(_:)),
                                   keyEquivalent: "").tag = 1
        saveMenus.addItemWithTitle(NSLocalizedString("Save Arena Deck", comment: ""),
                                   action: #selector(AppDelegate.saveArenaDeck(_:)),
                                   keyEquivalent: "")
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Save", comment: ""),
                                            action: nil,
                                            keyEquivalent: "").submenu = saveMenus
        deckMenu?.submenu?.addItemWithTitle(NSLocalizedString("Clear", comment: ""),
                                            action: #selector(AppDelegate.clearTrackers(_:)),
                                            keyEquivalent: "R")
        
        // build dock menu
        // ---------------
        if let decksmenu = self.dockMenu.itemWithTag(1) {
            decksmenu.submenu?.removeAllItems()
        } else {
            let decksmenu = NSMenuItem(title: NSLocalizedString("Decks", comment: ""),
                                       action: nil, keyEquivalent: "")
            decksmenu.tag = 1
            decksmenu.submenu = NSMenu()
            self.dockMenu.addItem(decksmenu)
        }
        
        let dockdeckMenu = self.dockMenu.itemWithTag(1)

        // add deck items to main and dock menu
        // ------------------------------------
        deckMenu?.submenu?.addItem(NSMenuItem.separatorItem())
        for (playerClass, _decks) in decks
            .sort({ NSLocalizedString($0.0.rawValue.lowercaseString, comment: "")
                < NSLocalizedString($1.0.rawValue.lowercaseString, comment: "") }) {
                    // create menu item for all decks in this class
                    let classmenuitem = NSMenuItem(title: NSLocalizedString(
                        playerClass.rawValue.lowercaseString,
                        comment: ""), action: nil, keyEquivalent: "")
                    let classsubMenu = NSMenu()
                    _decks.filter({ $0.isActive == true })
                        .sort({$0.name!.lowercaseString < $1.name!.lowercaseString }).forEach({
                            let item = classsubMenu.addItemWithTitle($0.name!,
                                action: #selector(AppDelegate.playDeck(_:)),
                                keyEquivalent: "")
                            item.representedObject = $0
                        })
                    classmenuitem.submenu = classsubMenu
                    deckMenu?.submenu?.addItem(classmenuitem)
                    if let menuitemcopy = classmenuitem.copy() as? NSMenuItem {
                        dockdeckMenu?.submenu?.addItem(menuitemcopy)
                    }
        }
        
        let replayMenu = mainMenu?.itemWithTitle(NSLocalizedString("Replays", comment: ""))
        let replaysMenu = replayMenu?.submenu?.itemWithTitle(NSLocalizedString("Last replays",
            comment: ""))
        replaysMenu?.submenu?.removeAllItems()
        replaysMenu?.enabled = false
        if let _ = Settings.instance.hsReplayUploadToken {
            replaysMenu?.enabled = HSReplayManager.instance.replays.count > 0
            
            HSReplayManager.instance.replays.sort({
                $0.0.date.compare($0.1.date) == .OrderedDescending
            }).take(10).forEach({
                let name: String
                if $0.deck.isEmpty {
                    name = String(format: "Vs %@", $0.against)
                } else {
                    name = String(format: "%@ vs %@", $0.deck, $0.against)
                }
                if let item = replaysMenu?.submenu?.addItemWithTitle(name,
                    action: #selector(AppDelegate.showReplay(_:)),
                    keyEquivalent: "") {
                    item.representedObject = $0.replayId
                }
            })
            
        }
        
        let settings = Settings.instance
        let windowMenu = mainMenu?.itemWithTitle(NSLocalizedString("Window", comment: ""))
        let item = windowMenu?.submenu?.itemWithTitle(NSLocalizedString("Lock windows",
            comment: ""))
        item?.title = NSLocalizedString(settings.windowsLocked ?  "Unlock windows" : "Lock windows",
                                        comment: "")
    }
    
    func showReplay(sender: NSMenuItem) {
        if let replayId = sender.representedObject as? String {
            HSReplayManager.showReplay(replayId)
        }
    }
    
    @IBAction func importReplay(sender: NSMenuItem) {
        let panel = NSOpenPanel()
        if let path = ReplayMaker.replayDir() {
            panel.directoryURL = NSURL(fileURLWithPath: path)
        }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["hdtreplay"]
        panel.beginWithCompletionHandler { (returnCode) in
            if returnCode == NSFileHandlingPanelOKButton {
                for filename in panel.URLs {
                    if let path = filename.path {
                        LogUploader.upload(path, completion: { (result) in
                            if case UploadResult.successful(let replayId) = result {
                                HSReplayManager.showReplay(replayId)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func applicationDockMenu(sender: NSApplication) -> NSMenu? {
        return self.dockMenu
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
            let alert = NSAlert()
            alert.alertStyle = .Informational
            // swiftlint:disable line_length
            alert.messageText = NSLocalizedString("There was an issue saving your arena deck. Try relaunching Hearthstone and clicking on 'Arena', and then try to save again.", comment: "")
            // swiftlint:enable line_length
            alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
            NSRunningApplication.currentApplication().activateWithOptions([
                NSApplicationActivationOptions.ActivateAllWindows,
                NSApplicationActivationOptions.ActivateIgnoringOtherApps])
            NSApp.activateIgnoringOtherApps(true)
            alert.runModal()
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
        item?.title = NSLocalizedString(settings.windowsLocked ?  "Unlock windows" : "Lock windows",
                                        comment: "")
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
    
    @IBAction func openReplayDirectory(sender: AnyObject) {
        if let path = ReplayMaker.replayDir() {
            NSWorkspace.sharedWorkspace()
                .activateFileViewerSelectingURLs([NSURL(fileURLWithPath: path)])
        }
    }
}

extension AppDelegate: SUUpdaterDelegate {
    func feedParametersForUpdater(updater: SUUpdater!,
                                  sendingSystemProfile sendingProfile: Bool) -> [AnyObject]! {
        return BITSystemProfile.sharedSystemProfile().systemUsageData()
            as NSMutableArray as [AnyObject]
    }
}

extension AppDelegate: BITHockeyManagerDelegate {
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
}
