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

        let preferences = MASPreferencesWindowController(
            viewControllers: controllers,
            title: NSLocalizedString("Preferences", comment: ""))
        return preferences
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Paths.initDirs()
        let destination = Paths.HSTracker

        let config = Realm.Configuration(
            fileURL: destination.appendingPathComponent("hstracker.realm"),
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                // version == 1 : add hearthstoneId in Deck,
                // automatically managed by realm, nothing to do here

                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType:
                    Deck.className()) { oldObject, newObject in
                        // version == 2 : hearthstoneId is now hsDeckId,
                        if let hearthstoneId = oldObject?["hearthstoneId"] as? Int {
                            newObject!["hsDeckId"] = Int64(hearthstoneId)
                        }
                    }
                }
                
                if oldSchemaVersion < 4 {
                    // deck.version changes from string to two ints (major, minor)
                    migration.enumerateObjects(ofType:
                    Deck.className()) { oldObject, newObject in
                        if let versionStr = oldObject?["version"] as? String {
                            if let ver = Double(versionStr) {
                                let majorVersion = Int(ver)
                                let minorVersion = Int((ver - Double(majorVersion)) * 10.0)
                                newObject!["deckMajorVersion"] = majorVersion
                                newObject!["deckMinorVersion"] = minorVersion
                            } else {
                                newObject!["deckMajorVersion"] = 1
                                newObject!["deckMinorVersion"] = 0
                            }
                        }
                    }
                }
        })
        Realm.Configuration.defaultConfiguration = config

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

        let path = Paths.logs.path
        let severity = Settings.instance.logSeverity
        let rotatingConf = RotatingLogFileConfiguration(minimumSeverity: severity,
                                                        daysToKeep: 7,
                                                        directoryPath: path,
                                                        formatters: [HSTrackerLogFormatter()])
        loggers.append(rotatingConf)
        Log.enable(configuration: loggers)

        Log.info?.message("*** Starting \(Version.buildName) ***")

        if settings.hearthstoneLogPath.hasSuffix("/Logs") {
            settings.hearthstoneLogPath = settings.hearthstoneLogPath.replace("/Logs", with: "")
        }

        // make sure we initialize Game in the main thread
        Game.shared.load()

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
        NSRunningApplication.current().activate(options: [
            .activateAllWindows,
            .activateIgnoringOtherApps
            ])
        NSApp.activate(ignoringOtherApps: true)

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
            if BuildDates.isOutdated() || !Database.jsonFilesAreValid() {
                BuildDates.downloadCards(splashscreen: self.splashscreen!)
            }
        }

        let databaseOperation = BlockOperation {
            let database = Database()
            database.loadDatabase(splashscreen: self.splashscreen!)
        }
        let loggingOperation = BlockOperation {
            while true {
                if WindowManager.default.isReady() {
                    break
                }
                Thread.sleep(forTimeInterval: 0.5)
            }

            WindowManager.default.hideGameTrackers()
        }

        let menuOperation = BlockOperation {
            OperationQueue.main.addOperation {
                Log.info?.message("Loading menu")
                self.buildMenu()
            }
        }

        databaseOperation.addDependency(buildsOperation)
        loggingOperation.addDependency(menuOperation)

        operationQueue = OperationQueue()
        operationQueue?.addOperation(buildsOperation)
        operationQueue?.addOperation(databaseOperation)
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

            NSAlert.show(style: alertStyle,
                         message: NSLocalizedString(message, comment: ""),
                         forceFront: true)
            return
        }

        Hearthstone.instance.start()

        let events = [
            "reload_decks": #selector(AppDelegate.reloadDecks(_:)),
            "hstracker_language": #selector(AppDelegate.languageChange(_:)),
            "theme": #selector(reloadTheme)
            ]

        for (event, selector) in events {
            NotificationCenter.default.addObserver(self,
                                                   selector: selector,
                                                   name: NSNotification.Name(rawValue: event),
                                                   object: nil)
        }

        if let activeDeck = Settings.instance.activeDeck {
            DispatchQueue.main.async {
                Game.shared.set(activeDeck: activeDeck)
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
        let msg = "You must restart HSTracker for the language change to take effect"
        NSAlert.show(style: .informational,
                     message: NSLocalizedString(msg, comment: ""))

        appWillRestart = true
        NSApplication.shared().terminate(nil)
        exit(0)
    }

    // MARK: - Menu
    func buildMenu() {
        guard let realm = try? Realm() else {
            Log.error?.message("Can not fetch decks")
            return
        }

        var decks: [CardClass: [Deck]] = [:]
        for deck in realm.objects(Deck.self).filter("isActive = true") {
            if decks[deck.playerClass] == nil {
                decks[deck.playerClass] = [Deck]()
            }
            decks[deck.playerClass]?.append(deck)
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
            let statistics = realm.objects(GameStats.self)
                .filter("hsReplayId != nil")
                .sorted(byKeyPath: "startTime", ascending: false)
            replaysMenu?.isEnabled = statistics.count > 0
            let max = min(statistics.count, 10)
            for i in 0..<max {
                let stat = statistics[i]
                var deckName = ""
                if let deck = stat.deck.first, !deck.name.isEmpty {
                    deckName = deck.name
                }
                let opponentName = stat.opponentName.isEmpty ? "unknow" : stat.opponentName
                let opponentClass = stat.opponentHero

                var name = ""
                if !deckName.isEmpty {
                    name = "\(deckName) vs"
                } else {
                    name = "Vs"
                }
                name += " \(opponentName)"
                if opponentClass != .neutral {
                    name += " (\(NSLocalizedString(opponentClass.rawValue, comment: "")))"
                }

                if let item = replaysMenu?.submenu?
                    .addItem(withTitle: name,
                             action: #selector(showReplay(_:)),
                             keyEquivalent: "") {
                    item.representedObject = stat.hsReplayId
                }
            }
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
        panel.directoryURL = Paths.replays
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
            let deckId = deck.deckId
            DispatchQueue.main.async {
                Game.shared.set(activeDeck: deckId)
            }
        }
    }

    @IBAction func openDeckManager(_ sender: AnyObject) {
        if deckManager == nil {
            deckManager = DeckManager(windowNibName: "DeckManager")
        }
        deckManager?.showWindow(self)
    }

    @IBAction func clearTrackers(_ sender: AnyObject) {
        Game.shared.removeActiveDeck()
        Settings.instance.activeDeck = nil
    }

    @IBAction func saveCurrentDeck(_ sender: AnyObject) {
        switch sender.tag {
        case 1: // Opponent
            saveDeck(Game.shared.opponent)
        case 2: // Self
            saveDeck(Game.shared.player)
        default:
            break
        }
    }

    func saveDeck(_ player: Player) {
        if let playerClass = player.playerClass {
            if deckManager == nil {
                deckManager = DeckManager(windowNibName: "DeckManager")
            }
            do {
                let realm = try Realm()
                try realm.write {
                    let deck = Deck()
                    deck.playerClass = playerClass
                    deck.name = player.name ?? "Custom \(playerClass)"
                    realm.add(deck)
                    player.playerCardList.filter({ $0.collectible == true }).forEach {
                        deck.add(card: $0)
                    }
                    deckManager?.currentDeck = deck
                }
            } catch {
                Log.error?.message("Can not create deck")
            }
            deckManager?.editDeck(self)
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
        NSWorkspace.shared().activateFileViewerSelecting([Paths.replays])
    }
}

extension AppDelegate: SUUpdaterDelegate {

    func feedParameters(for updater: SUUpdater,
                        sendingSystemProfile sendingProfile: Bool) -> [[String : String]] {
        var parameters: [[String : String]] = []
        for data: Any in BITSystemProfile.shared().systemUsageData() {
            if let dict = data as? [String: String] {
                parameters.append(dict)
            }
        }
        return parameters
    }
}

extension AppDelegate: BITHockeyManagerDelegate {
    func applicationLog(for crashManager: BITCrashManager!) -> String! {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'.log'"

        let file = Paths.logs.appendingPathComponent("\(fmt.string(from: Date()))")
        if FileManager.default.fileExists(atPath: file.path) {
            do {
                let content = try String(contentsOf: file)
                return Array(content
                    .components(separatedBy: CharacterSet.newlines)
                    .reversed() // reverse to keep 400 last lines
                    .prefix(400))
                    .reversed() // re-reverse them
                    .joined(separator: "\n")
            } catch {}
        }

        return ""
    }
}
