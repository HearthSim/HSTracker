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
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var appWillRestart = false
    var splashscreen: Splashscreen?
    var initalConfig: InitialConfiguration?
    var deckManager: DeckManager?
    @IBOutlet weak var sparkleUpdater: SUUpdater!
    var operationQueue: OperationQueue?
    var hstrackerIsStarted = false
    var dockMenu = NSMenu(title: "DockMenu")
    var appHealth: AppHealth = AppHealth.instance

    var preferences: MASPreferencesWindowController = {
        var controllers = [
            GeneralPreferences(nibName: "GeneralPreferences", bundle: nil)!,
            UpdatePreferences(nibName: "UpdatePreferences", bundle: nil)!,
            GamePreferences(nibName: "GamePreferences", bundle: nil)!,
            TrackersPreferences(nibName: "TrackersPreferences", bundle: nil)!,
            PlayerTrackersPreferences(nibName: "PlayerTrackersPreferences", bundle: nil)!,
            OpponentTrackersPreferences(nibName: "OpponentTrackersPreferences", bundle: nil)!,
            HSReplayPreferences(nibName: "HSReplayPreferences", bundle: nil)!,
            TrackOBotPreferences(nibName: "TrackOBotPreferences", bundle: nil)!
        ]

        if HearthstatsAPI.isLogged() {
            controllers.append(HearthstatsPreferences(nibName: "HearthstatsPreferences",
                                                      bundle: nil)!)
        }

        let preferences = MASPreferencesWindowController(
            viewControllers: controllers,
            title: NSLocalizedString("Preferences", comment: ""))
        return preferences
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let destination = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory,
                                                                    .userDomainMask, true).first {
            var config = Realm.Configuration()
            config.fileURL = URL(fileURLWithPath: "\(destination)/HSTracker/hstracker.realm")
            Realm.Configuration.defaultConfiguration = config
        }

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

        Log.info?.message("*** Starting \(Version.buildName) ***")

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

        Log.info?.message("Opening trackers")
        WindowManager.default.startManager()
        
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
                if WindowManager.default.isReady() {
                    break
                }
                Thread.sleep(forTimeInterval: 0.5)
            }

            OperationQueue.main.addOperation() {
                Game.instance.reset()
            }
        }

        let menuOperation = BlockOperation {
            OperationQueue.main.addOperation() {
                Log.info?.message("Loading menu")
                self.buildMenu()
            }
        }

        databaseOperation.addDependency(buildsOperation)
        loggingOperation.addDependency(menuOperation)
        decksOperation.addDependency(databaseOperation)
        menuOperation.addDependency(decksOperation)

        operationQueue = OperationQueue()
        operationQueue?.addOperation(buildsOperation)
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
            "reload_decks": #selector(AppDelegate.reloadDecks(_:)),
            "hstracker_language": #selector(AppDelegate.languageChange(_:)),
            "theme": #selector(reloadTheme),
            "save_arena_deck": #selector(AppDelegate.saveArenaDeck(_:)),
            ]

        for (event, selector) in events {
            NotificationCenter.default.addObserver(self,
                                                   selector: selector,
                                                   name: NSNotification.Name(rawValue: event),
                                                   object: nil)
        }

        if let activeDeck = Settings.instance.activeDeck {
            do {
                let realm = try Realm()
                if let deck = realm.objects(Deck.self).filter("deckId = '\(activeDeck)'").first {
                    Game.instance.set(activeDeck: deck)
                }
            } catch {
                Log.error?.message("Can not fetch deck : \(error)")
            }
        }

        NotificationCenter.default
            .post(Notification(name: Notification.Name(rawValue: "hstracker_is_ready"),
                               object: nil))

        splashscreen?.close()
        splashscreen = nil

        let time = DispatchTime.now() + DispatchTimeInterval.milliseconds(500)
        DispatchQueue.main.asyncAfter(deadline: time) {
            WindowManager.default.updateTrackers()
        }
    }

    func reloadDecks(_ notification: Notification) {
        buildMenu()
    }

    func reloadTheme() {
        WindowManager.default.updateTrackers(reset: true)
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
        var decks: [CardClass: [Deck]] = [:]
        do {
            let realm = try Realm()
            for deck in realm.objects(Deck.self).filter("isActive = true") {
                if decks[deck.playerClass] == nil {
                    decks[deck.playerClass] = [Deck]()
                }
                decks[deck.playerClass]?.append(deck)
            }
        } catch {
            Log.error?.message("Can not load decks : \(error)")
        }

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
                        .sorted(by: {$0.name.lowercased() < $1.name.lowercased() }).forEach({
                            let item = classsubMenu
                                .addItem(withTitle: $0.name,
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
            let deck = Deck()
            deck.playerClass = playerClass
            deck.name = player.name ?? "Custom \(playerClass)"
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
        WindowManager.default.updateTrackers()
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
