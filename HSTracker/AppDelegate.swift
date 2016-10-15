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
    var operationQueue: OperationQueue?
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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let settings = Settings.instance

        let hockeyKey = "2f0021b9bb1842829aa1cfbbd85d3bed"
        /*if settings.releaseChannel == .beta {
         hockeyKey = "c8af7f051ae14d0eb67438f27c3d9dc1"
         }*/

        let url = "https://hsdecktracker.net/hstracker/appcast.xml"
        sparkleUpdater.feedURL = URL(string: url)
        sparkleUpdater.sendsSystemProfile = true
        sparkleUpdater.automaticallyDownloadsUpdates = settings.automaticallyDownloadsUpdates

        BITHockeyManager.shared().configure(withIdentifier: hockeyKey)
        BITHockeyManager.shared().crashManager.isAutoSubmitCrashReport = true
        BITHockeyManager.shared().delegate = self
        BITHockeyManager.shared().start()

        if let _ = UserDefaults.standard.object(forKey: "hstracker_v2") {
            // welcome to HSTracker v2
        } else {
            for (key, _) in UserDefaults.standard.dictionaryRepresentation() {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
            UserDefaults.standard.set(true, forKey: "hstracker_v2")
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

        if let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory,
                                                          .userDomainMask, true).first {
            do {
                try FileManager.default.createDirectory(
                    atPath: "\(path)/Logs/HSTracker",
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

    func applicationWillTerminate(_ notification: Notification) {
        Hearthstone.instance.stopTracking()
        if appWillRestart {
            let appPath = Bundle.main.bundlePath
            let task = Process()
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

        let buildsOperation = BlockOperation {
            BuildDates.loadBuilds(splashscreen: self.splashscreen!)
            if BuildDates.isOutdated() {
                BuildDates.downloadCards(splashscreen: self.splashscreen!)
            }
        }

        let databaseOperation = BlockOperation {
            let database = Database()
            if let images = database.loadDatabase(splashscreen: self.splashscreen!) {
                let imageDownloader = ImageDownloader()
                imageDownloader.deleteImages()
                imageDownloader.downloadImagesIfNeeded(splashscreen: self.splashscreen!,
                                                       images: images)
            }
        }
        let decksOperation = BlockOperation {
            Log.info?.message("Loading decks")
            Decks.instance.loadDecks(splashscreen: self.splashscreen)
        }
        let loggingOperation = BlockOperation {
            while true {
                if self.playerTracker != nil && self.opponentTracker != nil {
                    break
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            let game = Game.instance
            game.set(playerTracker: self.playerTracker)
            game.set(opponentTracker: self.opponentTracker)
            game.secretTracker = self.secretTracker
            game.timerHud = self.timerHud
            game.cardHudContainer = self.cardHudContainer
            game.playerBoardDamage = self.playerBoardDamage
            game.opponentBoardDamage = self.opponentBoardDamage

            OperationQueue.main.addOperation() {
                game.reset()
            }
        }

        let trackerOperation = BlockOperation {
            OperationQueue.main.addOperation() {
                Log.info?.message("Opening trackers")
                self.openTrackers()
            }
        }
        let menuOperation = BlockOperation {
            OperationQueue.main.addOperation() {
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

        operationQueue = OperationQueue()
        operationQueue?.addOperation(buildsOperation)
        operationQueue?.addOperation(trackerOperation)
        operationQueue?.addOperation(databaseOperation)
        operationQueue?.addOperation(decksOperation)
        operationQueue?.addOperation(loggingOperation)
        operationQueue?.addOperation(menuOperation)

        operationQueue?.addObserver(self,
                                    forKeyPath: "operations",
                                    options: NSKeyValueObservingOptions.new,
                                    context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath, let operationQueue = operationQueue,
            let object = object as? OperationQueue {

            if object == operationQueue && keyPath == "operations" {
                if operationQueue.operationCount == 0 {
                    DispatchQueue.main.async {
                        self.hstrackerReady()
                    }
                }
                return
            }
        }
        super.observeValue(forKeyPath: keyPath,
                           of: object,
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
        var alertStyle = NSAlertStyle.critical
        do {
            let canStart = try Hearthstone.instance.setup()

            if !canStart {
                message = "You must restart Hearthstone for logs to be used"
                alertStyle = .informational
            }
        } catch HearthstoneLogError.canNotCreateDir {
            message = "Can not create Hearthstone config dir"
        } catch HearthstoneLogError.canNotReadFile {
            message = "Can not read Hearthstone config file"
        } catch HearthstoneLogError.canNotCreateFile {
            message = "Can not write Hearthstone config file"
        } catch {
            message = "Unknown error"
        }

        if let message = message {
            splashscreen?.close()
            splashscreen = nil

            if alertStyle == .critical {
                Log.error?.message(message)
            }

            let alert = NSAlert()
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.informativeText = NSLocalizedString(message, comment: "")
            alert.alertStyle = alertStyle
            NSRunningApplication.current().activate(options: [
                NSApplicationActivationOptions.activateAllWindows,
                NSApplicationActivationOptions.activateIgnoringOtherApps])
            NSApp.activate(ignoringOtherApps: true)
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
            NotificationCenter.default.addObserver(self,
                                                   selector: selector,
                                                   name: NSNotification.Name(rawValue: event),
                                                   object: nil)
        }

        if let activeDeck = Settings.instance.activeDeck,
            let deck = Decks.instance.byId(activeDeck) {
            Game.instance.set(activeDeck: deck)
        }

        NotificationCenter.default
            .post(Notification(name: Notification.Name(rawValue: "hstracker_is_ready"),
                               object: nil))

        splashscreen?.close()
        splashscreen = nil
    }

    func openTrackers() {
        let settings = Settings.instance

        let screenFrame = NSScreen.main()!.frame
        let y = screenFrame.height - 50
        let width: CGFloat
        switch settings.cardSize {
        case .tiny: width = CGFloat(kTinyFrameWidth)
        case .small: width = CGFloat(kSmallFrameWidth)
        case .medium: width = CGFloat(kMediumFrameWidth)
        case .big: width = CGFloat(kFrameWidth)
        case .huge: width = CGFloat(kHighRowFrameWidth)
        }

        playerTracker = Tracker(windowNibName: "Tracker")
        playerTracker?.playerType = .player
        if let rect = settings.playerTrackerFrame {
            playerTracker?.window?.setFrame(rect, display: true)
        } else {
            let x = screenFrame.width - width + screenFrame.origin.x
            playerTracker?.window?.setFrame(NSRect(x: x,
                                                   y: y + screenFrame.origin.y,
                                                   width: width, height: y),
                                            display: true)
        }
        showPlayerTracker(nil)

        opponentTracker = Tracker(windowNibName: "Tracker")
        opponentTracker?.playerType = .opponent

        if let rect = settings.opponentTrackerFrame {
            opponentTracker?.window?.setFrame(rect, display: true)
        } else {
            let x = screenFrame.origin.x + 50
            opponentTracker?.window?.setFrame(NSRect(x: x,
                                                     y: y + screenFrame.origin.y,
                                                     width: width, height: y),
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

    func showPlayerTracker(_ notification: Notification?) {
        showHideTracker(self.playerTracker,
                        show: Settings.instance.showPlayerTracker,
                        title: "Player tracker")
    }

    func showOpponentTracker(_ notification: Notification?) {
        showHideTracker(self.opponentTracker,
                        show: Settings.instance.showOpponentTracker,
                        title: "Opponent tracker")
    }

    func showHideTracker(_ tracker: Tracker?, show: Bool, title: String) {
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

    func reloadDecks(_ notification: Notification) {
        buildMenu()
    }

    func reloadTheme(_ notification: Notification) {
        Game.instance.updatePlayerTracker(reset: true)
        Game.instance.updateOpponentTracker(reset: true)
    }

    var closeFloatingCardRequest = 0
    var closeRequestTimer: Timer?
    func showFloatingCard(_ notification: Notification) {
        guard Settings.instance.showFloatingCard else {return}

        if let card = (notification as NSNotification).userInfo?["card"] as? Card,
            let arrayFrame = (notification as NSNotification).userInfo?["frame"] as? [CGFloat] {
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
            floatingCard?.set(card: card)

            closeRequestTimer = Timer.scheduledTimer(
                timeInterval: 3,
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

    func hideFloatingCard(_ notification: Notification) {
        guard Settings.instance.showFloatingCard else {return}

        self.closeFloatingCardRequest -= 1
        let when = DispatchTime.now()
            + Double(Int64(100 * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: when) {
            if self.closeFloatingCardRequest > 0 {
                return
            }
            self.closeFloatingCardRequest = 0
            self.floatingCard?.window?.orderOut(self)
            self.closeRequestTimer?.invalidate()
            self.closeRequestTimer = nil
        }
    }

    func showHideCardHuds(_ notification: Notification) {
        Game.instance.updateCardHuds(force: true)
    }

    func languageChange(_ notification: Notification) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        // swiftlint:disable line_length
        alert.messageText = NSLocalizedString("You must restart HSTracker for the language change to take effect", comment: "")
        // swiftlint:enable line_length
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()

        appWillRestart = true
        NSApplication.shared().terminate(nil)
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
        let mainMenu = NSApplication.shared().mainMenu
        let deckMenu = mainMenu?.item(withTitle: NSLocalizedString("Decks", comment: ""))
        deckMenu?.submenu?.removeAllItems()
        deckMenu?.submenu?.addItem(withTitle: NSLocalizedString("Deck Manager", comment: ""),
                                   action: #selector(AppDelegate.openDeckManager(_:)),
                                   keyEquivalent: "d")
        deckMenu?.submenu?.addItem(withTitle: NSLocalizedString("Reset", comment: ""),
                                   action: #selector(AppDelegate.resetTrackers(_:)),
                                   keyEquivalent: "r")
        let saveMenus = NSMenu()
        saveMenus.addItem(withTitle: NSLocalizedString("Save Current Deck", comment: ""),
                          action: #selector(AppDelegate.saveCurrentDeck(_:)),
                          keyEquivalent: "").tag = 2
        saveMenus.addItem(withTitle: NSLocalizedString("Save Opponent's Deck", comment: ""),
                          action: #selector(AppDelegate.saveCurrentDeck(_:)),
                          keyEquivalent: "").tag = 1
        saveMenus.addItem(withTitle: NSLocalizedString("Save Arena Deck", comment: ""),
                          action: #selector(AppDelegate.saveArenaDeck(_:)),
                          keyEquivalent: "")
        deckMenu?.submenu?.addItem(withTitle: NSLocalizedString("Save", comment: ""),
                                   action: nil,
                                   keyEquivalent: "").submenu = saveMenus
        deckMenu?.submenu?.addItem(withTitle: NSLocalizedString("Clear", comment: ""),
                                   action: #selector(AppDelegate.clearTrackers(_:)),
                                   keyEquivalent: "R")

        // build dock menu
        // ---------------
        if let decksmenu = self.dockMenu.item(withTag: 1) {
            decksmenu.submenu?.removeAllItems()
        } else {
            let decksmenu = NSMenuItem(title: NSLocalizedString("Decks", comment: ""),
                                       action: nil, keyEquivalent: "")
            decksmenu.tag = 1
            decksmenu.submenu = NSMenu()
            self.dockMenu.addItem(decksmenu)
        }

        let dockdeckMenu = self.dockMenu.item(withTag: 1)

        // add deck items to main and dock menu
        // ------------------------------------
        deckMenu?.submenu?.addItem(NSMenuItem.separator())
        for (playerClass, _decks) in decks
            .sorted(by: { NSLocalizedString($0.0.rawValue.lowercased(), comment: "")
                < NSLocalizedString($1.0.rawValue.lowercased(), comment: "") }) {
                    // create menu item for all decks in this class
                    let classmenuitem = NSMenuItem(title: NSLocalizedString(
                        playerClass.rawValue.lowercased(),
                        comment: ""), action: nil, keyEquivalent: "")
                    let classsubMenu = NSMenu()
                    _decks.filter({ $0.isActive == true })
                        .sorted(by: {$0.name!.lowercased() < $1.name!.lowercased() }).forEach({
                            let item = classsubMenu
                                .addItem(withTitle: $0.name!,
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

        let replayMenu = mainMenu?.item(withTitle: NSLocalizedString("Replays", comment: ""))
        let replaysMenu = replayMenu?.submenu?.item(withTitle: NSLocalizedString("Last replays",
                                                                                 comment: ""))
        replaysMenu?.submenu?.removeAllItems()
        replaysMenu?.isEnabled = false
        if let _ = Settings.instance.hsReplayUploadToken {
            replaysMenu?.isEnabled = HSReplayManager.instance.replays.count > 0

            HSReplayManager.instance.replays.sorted(by: {
                $0.0.date.compare($0.1.date as Date) == .orderedDescending
            }).take(10).forEach({
                let name: String
                if $0.deck.isEmpty {
                    name = String(format: "Vs %@", $0.against)
                } else {
                    name = String(format: "%@ vs %@", $0.deck, $0.against)
                }
                if let item = replaysMenu?.submenu?
                    .addItem(withTitle: name,
                             action: #selector(AppDelegate.showReplay(_:)),
                             keyEquivalent: "") {
                    item.representedObject = $0.replayId
                }
            })

        }

        let settings = Settings.instance
        let windowMenu = mainMenu?.item(withTitle: NSLocalizedString("Window", comment: ""))
        let item = windowMenu?.submenu?.item(withTitle: NSLocalizedString("Lock windows",
                                                                          comment: ""))
        item?.title = NSLocalizedString(settings.windowsLocked ?  "Unlock windows" : "Lock windows",
                                        comment: "")
    }

    func showReplay(_ sender: NSMenuItem) {
        if let replayId = sender.representedObject as? String {
            HSReplayManager.showReplay(replayId: replayId)
        }
    }

    @IBAction func importReplay(_ sender: NSMenuItem) {
        let panel = NSOpenPanel()
        if let path = ReplayMaker.replayDir() {
            panel.directoryURL = URL(fileURLWithPath: path)
        }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["hdtreplay"]
        panel.begin { (returnCode) in
            if returnCode == NSFileHandlingPanelOKButton {
                for filename in panel.urls {
                    let path = filename.path
                    LogUploader.upload(filename: path, completion: { (result) in
                        if case UploadResult.successful(let replayId) = result {
                            HSReplayManager.showReplay(replayId: replayId)
                        }
                    })
                }
            }
        }
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return self.dockMenu
    }

    func playDeck(_ sender: NSMenuItem) {
        if let deck = sender.representedObject as? Deck {
            Settings.instance.activeDeck = deck.deckId
            Game.instance.set(activeDeck: deck)
        }
    }

    @IBAction func openDeckManager(_ sender: AnyObject) {
        if deckManager == nil {
            deckManager = DeckManager(windowNibName: "DeckManager")
        }
        deckManager?.showWindow(self)
    }

    @IBAction func clearTrackers(_ sender: AnyObject) {
        Game.instance.removeActiveDeck()
        Settings.instance.activeDeck = nil
    }

    @IBAction func saveCurrentDeck(_ sender: AnyObject) {
        switch sender.tag {
        case 1: // Opponent
            saveDeck(Game.instance.opponent)
        case 2: // Self
            saveDeck(Game.instance.player)
        default:
            break
        }
    }

    func saveDeck(_ player: Player) {
        if let playerClass = player.playerClass {
            let deck = Deck(playerClass: playerClass)
            player.playerCardList.filter({ $0.collectible == true }).forEach({ deck.add(card: $0) })

            if deckManager == nil {
                deckManager = DeckManager(windowNibName: "DeckManager")
            }
            deckManager?.currentDeck = deck
            deckManager?.editDeck(self)
        }
    }

    @IBAction func saveArenaDeck(_ sender: AnyObject) {
        if let deck = Draft.instance.deck {
            if deckManager == nil {
                deckManager = DeckManager(windowNibName: "DeckManager")
            }
            deckManager?.currentDeck = deck
            deckManager?.editDeck(self)
        } else {
            Log.error?.message("Arena deck doesn't exist. How?")
            let alert = NSAlert()
            alert.alertStyle = .informational
            // swiftlint:disable line_length
            alert.messageText = NSLocalizedString("There was an issue saving your arena deck. Try relaunching Hearthstone and clicking on 'Arena', and then try to save again.", comment: "")
            // swiftlint:enable line_length
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            NSRunningApplication.current().activate(options: [
                NSApplicationActivationOptions.activateAllWindows,
                NSApplicationActivationOptions.activateIgnoringOtherApps])
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    @IBAction func resetTrackers(_ sender: AnyObject) {
        Game.instance.opponent.reset()
        Game.instance.updateOpponentTracker()
    }

    @IBAction func openPreferences(_ sender: AnyObject) {
        preferences.showWindow(self)
    }

    @IBAction func lockWindows(_ sender: AnyObject) {
        let settings = Settings.instance
        let mainMenu = NSApplication.shared().mainMenu
        let windowMenu = mainMenu?.item(withTitle: NSLocalizedString("Window", comment: ""))
        let text = settings.windowsLocked ? "Unlock windows" : "Lock windows"
        let item = windowMenu?.submenu?.item(withTitle: NSLocalizedString(text, comment: ""))
        settings.windowsLocked = !settings.windowsLocked
        item?.title = NSLocalizedString(settings.windowsLocked ?  "Unlock windows" : "Lock windows",
                                        comment: "")
    }

    var windowMove: WindowMove?
    @IBAction func openDebugPositions(_ sender: AnyObject) {
        if windowMove == nil {
            windowMove = WindowMove(windowNibName: "WindowMove")
        }
        windowMove?.showWindow(self)
    }

    @IBAction func closeWindow(_ sender: AnyObject) {
    }

    @IBAction func openReplayDirectory(_ sender: AnyObject) {
        if let path = ReplayMaker.replayDir() {
            NSWorkspace.shared()
                .activateFileViewerSelecting([URL(fileURLWithPath: path)])
        }
    }
}

extension AppDelegate: SUUpdaterDelegate {
    func feedParameters(for updater: SUUpdater!,
                        sendingSystemProfile sendingProfile: Bool) -> [Any]! {
        return BITSystemProfile.shared().systemUsageData().map { $0 }
    }
}

extension AppDelegate: BITHockeyManagerDelegate {
    func applicationLog(for crashManager: BITCrashManager!) -> String! {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'.log'"

        if let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory,
                                                          .userDomainMask, true).first {
            let file = "\(path)/Logs/HSTracker/\(fmt.string(from: Date()))"
            
            if FileManager.default.fileExists(atPath: file) {
                do {
                    let content = try String(contentsOfFile: file)
                    return Array(content
                        .components(separatedBy: CharacterSet.newlines)
                        .reversed() // reverse to keep 400 last lines
                        .prefix(400))
                        .reversed() // re-reverse them
                        .joined(separator: "\n")
                } catch {}
            }
        }
        
        return ""
    }
}
