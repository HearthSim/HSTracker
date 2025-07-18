//
//  AppDelegate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import AppKit
import SwiftyBeaver
let logger = SwiftyBeaver.self
import Preferences
import Sparkle
import Sentry
import AppMover

import OAuthSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SPUStandardUserDriverDelegate, NSUserNotificationCenterDelegate {
    
    static var _instance: AppDelegate?
    static func instance() -> AppDelegate {
        if let instance = _instance {
            return instance
        }
        fatalError("Unexpected nil for AppDelegate._instance")
    }
    
    var appWillRestart = false
    var splashscreen: Splashscreen?
    var initalConfig: InitialConfiguration?
    var deckManager: DeckManager?
    @IBOutlet var sparkleUpdater: SPUStandardUpdaterController!
    var operationQueue: OperationQueue!
    
    var dockMenu = NSMenu(title: "DockMenu")
    var appHealth: AppHealth = AppHealth.instance
    
    var coreManager: CoreManager!
    var triggers: [NSObjectProtocol] = []
    
    lazy var preferences: PreferencesWindowController = {
        let panes: [PreferencePane] = [
            GeneralPreferences(nibName: "GeneralPreferences", bundle: nil),
            GamePreferences(nibName: "GamePreferences", bundle: nil),
            TrackersPreferences(nibName: "TrackersPreferences", bundle: nil),
            HSReplayPreferences(nibName: "HSReplayPreferences", bundle: nil),
            PlayerTrackersPreferences(nibName: "PlayerTrackersPreferences", bundle: nil),
            OpponentTrackersPreferences(nibName: "OpponentTrackersPreferences", bundle: nil),
            BattlegroundsPreferences(nibName: "BattlegroundsPreferences", bundle: nil),
            MercenariesPreferences(nibName: "MercenariesPreferences", bundle: nil),
            ImportingPreferences(nibName: "ImportingPreferences", bundle: nil)
        ]
        return PreferencesWindowController(preferencePanes: panes, style: .toolbarItems, animated: false)
    }()
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        do {
            try AppMover.moveApp()
        } catch {
            NSLog("Moving app failed: \(error)")
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate._instance = self
        GameTag.initialize()
        Race.initialize()
        //setenv("CFNETWORK_DIAGNOSTICS", "3", 1)
        
        SentrySDK.start { options in
            options.dsn = "https://254d50452b94680e7ac7968694d1de3a@o35918.ingest.us.sentry.io/92505"
            options.debug = false // Enabled debug when first installing is always helpful
            options.appHangTimeoutInterval = 60.0

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 0.0

            // Sample rate for profiling, applied on top of TracesSampleRate.
            // We recommend adjusting this value in production.
            options.profilesSampleRate = 0.0
        }
        
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true as CFBoolean
        ]
        if !AXIsProcessTrustedWithOptions(options as CFDictionary) {
            logger.debug("Accessibility permission not granted")
        }
        // Migrate preferences from old bundle ID
        let oldPrefs = UserDefaults.standard.persistentDomain(forName: "be.michotte.hstracker")
        if let oldPrefs = oldPrefs, let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.setPersistentDomain(oldPrefs, forName: bundleId)
            UserDefaults.standard.removePersistentDomain(forName: "be.michotte.hstracker")
            UserDefaults.standard.synchronize()
        }
        
        // warn user about memory reading
        if Settings.showMemoryReadingWarning {
            let alert = NSAlert()
            alert.addButton(withTitle: String.localizedString("I understand", comment: ""))
            // swiftlint:disable line_length
            alert.messageText = String.localizedString("HSTracker needs elevated privileges to read data from Hearthstone's memory. If macOS asks you for your system password, do not be alarmed, no changes to your computer will be performed.", comment: "")
            // swiftlint:enable line_length
            alert.runModal()
            Settings.showMemoryReadingWarning = false
        }
        
        // create folders in file system
        Paths.initDirs()
        
        // initialize realm's database
        RealmHelper.initRealm(destination: Paths.HSTracker)
        
        // OAuth callback
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURL(event:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        // Restore OAuth credentials
        let credential = HSReplayAPI.oauthswift.client.credential
        if let refreshToken = Settings.hsReplayOAuthRefreshToken {
            credential.oauthRefreshToken = refreshToken
        }
        if let oauthToken = Settings.hsReplayOAuthToken {
            credential.oauthToken = oauthToken
        }
        if let expiration = Settings.hsReplayOAuthTokenExpiration {
            credential.oauthTokenExpiresAt = expiration
        }
        
        var refresh = false
        if let expiration = Settings.hsReplayOAuthTokenExpiration {
            if expiration.timeIntervalSince(Date()) <= 0 {
                refresh = true
            }
        } else {
            refresh = true
        }
        
        if refresh {
            logger.debug("OAuth token is expired, renewing")
            
            HSReplayAPI.oauthswift.renewAccessToken(withRefreshToken: credential.oauthRefreshToken, completionHandler: { result in
                switch result {
                case .success(let (credential, _, parameters)):
                    logger.debug("HSReplay: Refreshed OAuthToken")
                    Settings.hsReplayOAuthToken =  credential.oauthToken
                    Settings.hsReplayOAuthRefreshToken = credential.oauthRefreshToken
                    Settings.hsReplayOAuthTokenExpiration = credential.oauthTokenExpiresAt
                    Settings.hsReplayOAuthScope = parameters["scope"] as? String
                    HSReplayAPI.updateOAuthCredential()
                    HSReplayAPI.getAccount().done { result in
                        switch result {
                        case .failed:
                            logger.error("Failed to retrieve account data")
                        case .success(account: let data):
                            logger.info("Successfully retrieved account data: Username: \(data.username), battletag: \(data.battletag)")
                        }
                    }.catch { error in
                        logger.error(error)
                    }
                case .failure(let error):
                    logger.error(error)
                }
            })
        } else {
            _ = HSReplayAPI.getAccount().done { result in
                switch result {
                case .failed:
                    logger.error("Failed to retrieve account data")
                case .success(account: let data):
                    logger.info("Successfully retrieved account data: Username: \(data.username), battletag: \(data.battletag)")
                }
            }
        }
        
        // init debug loggers
        #if DEBUG
        let console = ConsoleDestination()
        logger.addDestination(console)
        #endif
        
        let bobsBuddy = BobsBuddyDestination()
        logger.addDestination(bobsBuddy)
        
        // setup logger
        let path = Paths.logs
        let file = FileDestination()
        file.logFileURL = path.appendingPathComponent("hstracker.log")
        file.logFileMaxSize = (2 * 1024 * 1024) // 2MB
        file.logFileAmount = 2
        logger.addDestination(file)
        logger.info("*** Starting \(Version.buildName) ***")
        
        HSReplayNetHelper.initialize()
        
        // check if we have valid settings
        if Settings.validated() {
            loadSplashscreen()
        } else {
            initalConfig = InitialConfiguration(windowNibName: "InitialConfiguration")
            initalConfig?.completionHandler = {
                self.loadSplashscreen()
            }
            initalConfig?.showWindow(nil)
            initalConfig?.window?.orderFrontRegardless()
        }
        
        if let rp = Bundle.main.resourcePath {
            logger.info("Resource path: \(rp)")
        } else {
            logger.warning("Failed to obtain bundle resource path")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        coreManager?.stopTracking()
        if appWillRestart {
            let appPath = Bundle.main.bundlePath
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [appPath]
            task.launch()
        }
    }
    
    @objc func handleGetURL(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue, let url = URL(string: urlString) {
            OAuthSwift.handle(url: url)
        }
    }
    
    // MARK: - Application init
    func loadSplashscreen() {
        NSRunningApplication.current.activate(options: [
            NSApplication.ActivationOptions.activateAllWindows,
            NSApplication.ActivationOptions.activateIgnoringOtherApps
        ])
        NSApp.activate(ignoringOtherApps: true)
        
        let splashscreen = Splashscreen(windowNibName: "Splashscreen")
        self.splashscreen = splashscreen
        let screenFrame = NSScreen.screens.first!.frame
        let splashscreenWidth: CGFloat = 350
        let splashscreenHeight: CGFloat = 250
        
        if let window = splashscreen.window {
            window.setFrame(NSRect(x: (screenFrame.width / 2) - (splashscreenWidth / 2),
                                   y: (screenFrame.height / 2) - (splashscreenHeight / 2),
                                   width: splashscreenWidth,
                                   height: splashscreenHeight),
                            display: true)
        }
        splashscreen.showWindow(self)
        
        logger.info("Opening trackers")

        DispatchQueue.global().async {
            let classesOperation = BlockOperation {
                ReflectionHelper.initialize()
            }

            let remoteConfigOperation = BlockOperation {
                RemoteConfig.checkRemoteConfig(splashscreen: splashscreen)
            }
            
            // load and init local database
            let databaseOperation = BlockOperation {
                let database = Database()
                var langs: [Language.Hearthstone] = []
                if let language = Settings.hearthstoneLanguage, language != .enUS {
                    langs += [language]
                }
                langs += [.enUS]
                database.loadDatabase(splashscreen: splashscreen, withLanguages: langs)
            }
            
            // build menu
            let menuOperation = BlockOperation {
                OperationQueue.main.addOperation {
                    logger.info("Loading menu")
                    self.buildMenu()
                }
            }
            
            menuOperation.addDependency(databaseOperation)
            remoteConfigOperation.addDependency(menuOperation)
            
            var operations = [Operation]()
            operations.append(classesOperation)
            operations.append(remoteConfigOperation)
            operations.append(databaseOperation)
            operations.append(menuOperation)
            
            self.operationQueue = OperationQueue()
            self.operationQueue.addOperations(operations, waitUntilFinished: true)
                        // remove any old feed URL to fix users not getting notified of updates
            UserDefaults.standard.removeObject(forKey: "SUFeedURL")
            
#if !HSTTEST
            if MonoHelper.load() {
                MonoHelper.initialize()
                DispatchQueue.global().async(qos: .userInitiated) {
                    MonoHelper.testSimulation()
                }
            } else {
                logger.error("Failed to load BobsBuddy")
            }
#endif

            DispatchQueue.main.async {
                self.completeSetup()
            }
        }
    }
    
    private func computeTitlebarHeight() -> CGFloat {
        let win = NSWindow()
        win.styleMask = [.titled, .miniaturizable, .resizable, .borderless, .nonactivatingPanel]
        let frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        win.setFrame(frame, display: false)
        return win.frame.height - win.contentRect(forFrameRect: win.frame).height
    }
    
    /** Finished setup, should only be called once */
    private func completeSetup() {
        SizeHelper.HearthstoneWindow.titlebarHeight = computeTitlebarHeight()
        var message: String?
        var alertStyle = NSAlert.Style.critical
        coreManager = CoreManager()
        do {
            let canStart = try coreManager?.setup() ?? false
            
            if !canStart {
                message = String.localizedString("You must restart Hearthstone for logs to be used", comment: "")
                alertStyle = .informational
            }
        } catch HearthstoneLogError.canNotCreateDir {
            message = String.localizedString("Can not create Hearthstone config dir", comment: "")
        } catch HearthstoneLogError.canNotReadFile {
            message = String.localizedString("Can not read Hearthstone config file", comment: "")
        } catch HearthstoneLogError.canNotCreateFile {
            message = String.localizedString("Can not write Hearthstone config file", comment: "")
        } catch {
            message = String.localizedString("Unknown error", comment: "")
        }
                
        if let message = message {
            splashscreen?.close()
            splashscreen = nil
            
            if alertStyle == .critical {
                logger.error(message)
            }
            
            NSAlert.show(style: alertStyle,
                         message: message,
                         forceFront: true)
            return
        }
                
        coreManager?.start()
        
        if triggers.count == 0 {
            let events = [
                Events.reload_decks: self.reloadDecks,
                Settings.hstracker_language: self.languageChange
            ]
            
            for (event, trigger) in events {
                let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: event), object: nil, queue: OperationQueue.main) { _ in
                    trigger()
                }
                triggers.append(observer)
            }
        }
        if let activeDeck = Settings.activeDeck {
            coreManager?.game.set(activeDeckId: activeDeck, autoDetected: false)
        }
        
        splashscreen?.close()
        splashscreen = nil
    }
    
    deinit {
        for observer in triggers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func reloadDecks() {
        buildMenu()
    }
    
    func languageChange() {
        NSAlert.show(style: .informational,
                     message: String.localizedString("You must restart HSTracker for the language change to take effect", comment: ""))
        
        appWillRestart = true
        NSApplication.shared.terminate(nil)
        exit(0)
    }
    
    // MARK: - Menu
    
    /**
     Builds the menu and its items.
     */
    func buildMenu() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let decks = RealmHelper.getActiveDecks() else {
                return
            }
            
            // build main menu
            // ---------------
            let mainMenu = NSApplication.shared.mainMenu
            let deckMenu = mainMenu?.item(withTitle: String.localizedString("Decks", comment: ""))
            deckMenu?.submenu?.removeAllItems()
            deckMenu?.submenu?.addItem(withTitle: String.localizedString("Deck Manager", comment: ""),
                                       action: #selector(AppDelegate.openDeckManager(_:)),
                                       keyEquivalent: "d")
            let saveMenus = NSMenu()
            saveMenus.addItem(withTitle: String.localizedString("Save Current Deck", comment: ""),
                              action: #selector(AppDelegate.saveCurrentDeck(_:)),
                              keyEquivalent: "").tag = 2
            saveMenus.addItem(withTitle: String.localizedString("Save Opponent's Deck", comment: ""),
                              action: #selector(AppDelegate.saveCurrentDeck(_:)),
                              keyEquivalent: "").tag = 1
            deckMenu?.submenu?.addItem(withTitle: String.localizedString("Save", comment: ""),
                                       action: nil,
                                       keyEquivalent: "").submenu = saveMenus
            deckMenu?.submenu?.addItem(withTitle: String.localizedString("Clear", comment: ""),
                                       action: #selector(AppDelegate.clearTrackers(_:)),
                                       keyEquivalent: "R")
            
            // build dock menu
            // ---------------
            if let decksmenu = self.dockMenu.item(withTag: 1) {
                decksmenu.submenu?.removeAllItems()
            } else {
                let decksmenu = NSMenuItem(title: String.localizedString("Decks", comment: ""),
                                           action: nil, keyEquivalent: "")
                decksmenu.tag = 1
                decksmenu.submenu = NSMenu()
                self.dockMenu.addItem(decksmenu)
            }
            
            if self.dockMenu.item(withTag: 2) == nil {
                self.dockMenu.addItem(NSMenuItem.separator())
                let deckmanager = NSMenuItem(title: String.localizedString("Deck Manager", comment: ""),
                                             action: #selector(AppDelegate.openDeckManager(_:)), keyEquivalent: "d")
                deckmanager.tag = 2
                self.dockMenu.addItem(deckmanager)
            }
            
            if self.dockMenu.item(withTag: 3) == nil {
                self.dockMenu.addItem(NSMenuItem.separator())
                let preferences = NSMenuItem(title: String.localizedString("Preferences", comment: ""),
                                             action: #selector(AppDelegate.openPreferences(_:)), keyEquivalent: "")
                preferences.tag = 3
                self.dockMenu.addItem(preferences)
            }
            
            let dockdeckMenu = self.dockMenu.item(withTag: 1)
            
            // add deck items to main and dock menu
            // ------------------------------------
            deckMenu?.submenu?.addItem(NSMenuItem.separator())
            for (playerClass, _decks) in decks
                .sorted(by: { String.localizedString($0.0.rawValue.lowercased(), comment: "")
                            < String.localizedString($1.0.rawValue.lowercased(), comment: "") }) {
                // create menu item for all decks in this class
                let classmenuitem = NSMenuItem(title: String.localizedString(
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
            
            let replayMenu = mainMenu?.item(withTitle: String.localizedString("Replays", comment: ""))
            let replaysMenu = replayMenu?.submenu?.item(withTitle: String.localizedString("Last replays",
                                                                                     comment: ""))
            replaysMenu?.submenu?.removeAllItems()
            replaysMenu?.isEnabled = false
            if Settings.hsReplayUploadToken != nil,
               let statistics = RealmHelper.getValidStatistics() {
                
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
                        name += " (\(String.localizedString(opponentClass.rawValue, comment: "")))"
                    }
                    
                    if let item = replaysMenu?.submenu?
                        .addItem(withTitle: name,
                                 action: #selector(self.showReplay(_:)),
                                 keyEquivalent: "") {
                        item.representedObject = stat.hsReplayId
                    }
                }
            }
            
            let windowMenu = mainMenu?.item(withTitle: String.localizedString("Window", comment: ""))
            let item = windowMenu?.submenu?.item(withTitle: String.localizedString("Lock windows",
                                                                              comment: ""))
            item?.title = String.localizedString(Settings.windowsLocked ?  "Unlock windows" : "Lock windows",
                                            comment: "")
        }
    }
    
    @objc func showReplay(_ sender: NSMenuItem) {
        if let replayId = sender.representedObject as? String {
            HSReplayManager.showReplay(replayId: replayId)
        }
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return self.dockMenu
    }
    
    @objc func playDeck(_ sender: NSMenuItem) {
        if let deck = sender.representedObject as? Deck {
            let deckId = deck.deckId
            self.coreManager?.game.set(activeDeckId: deckId, autoDetected: false)
        }
    }
    
    @IBAction func openDeckManager(_ sender: AnyObject) {
        guard let coreManager = coreManager else {
            return
        }
        if deckManager == nil {
            deckManager = DeckManager(windowNibName: "DeckManager")
            deckManager?.game = coreManager.game
        }
        deckManager?.showWindow(self)
    }
    
    @IBAction func clearTrackers(_ sender: AnyObject) {
        coreManager?.game.removeActiveDeck()
    }
    
    @IBAction func saveCurrentDeck(_ sender: AnyObject) {
        guard let sender = sender as? NSMenuItem, let coreManager else {
            return
        }
        switch sender.tag {
        case 1: // Opponent
            saveDeck(coreManager.game.opponent)
        case 2: // Self
            saveDeck(coreManager.game.player)
        default:
            break
        }
    }
    
    private func saveDeck(_ player: Player) {
        if let playerClass = player.originalClass {
            if deckManager == nil {
                deckManager = DeckManager(windowNibName: "DeckManager")
            }
            let deck = Deck()
            deck.playerClass = playerClass
            deck.name = player.name ?? "Custom \(playerClass)"
            let playerCardlist = player.playerCardList.filter({ $0.collectible == true })
            
            RealmHelper.add(deck: deck, with: playerCardlist)
            deckManager?.currentDeck = deck
            deckManager?.editDeck(self)
        }
    }
    
    @IBAction func openPreferences(_ sender: AnyObject) {
        preferences.show()
    }
    
    func openPreferences(pane: Preferences.PaneIdentifier) {
        preferences.show(preferencePane: pane)
    }
    
    @IBAction func lockWindows(_ sender: AnyObject) {
        let mainMenu = NSApplication.shared.mainMenu
        let windowMenu = mainMenu?.item(withTitle: String.localizedString("Window", comment: ""))
        let text = Settings.windowsLocked ? "Unlock windows" : "Lock windows"
        let item = windowMenu?.submenu?.item(withTitle: String.localizedString(text, comment: ""))
        Settings.windowsLocked = !Settings.windowsLocked
        item?.title = String.localizedString(Settings.windowsLocked ?  "Unlock windows" : "Lock windows",
                                        comment: "")
        if let game = coreManager?.game {
            if Settings.windowsLocked {
                game.windowManager.playerActiveEffectsOverlay.forceHideExampleEffects()
                game.windowManager.playerActiveEffectsOverlay.updateGrid()
                
                game.windowManager.playerCountersOverlay.forceHideExampleCounters()
            } else {
                game.windowManager.playerActiveEffectsOverlay.forceShowExampleEffects(true)
                game.windowManager.playerActiveEffectsOverlay.updateGrid()
                
                game.windowManager.playerCountersOverlay.forceShowExampleCounters()
            }
        }
    }
    
    #if DEBUG
    var windowMove: WindowMove?
    @IBAction func openDebugPositions(_ sender: AnyObject) {
        if windowMove == nil, let coreManager {
            windowMove = WindowMove(windowNibName: "WindowMove", windowManager: coreManager.game.windowManager)
        }
        windowMove?.showWindow(self)
    }
    #endif
    
    @IBAction func closeWindow(_ sender: AnyObject) {
    }
    
    @IBAction func openLogDirectory(_ sender: AnyObject) {
        NSWorkspace.shared.activateFileViewerSelecting([Paths.logs])
    }
    
    @IBAction func bugReport(_ sender: AnyObject) {
        if let url = URL(string: "https://github.com/HearthSim/HSTracker/issues") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func deleteCachedImages(_ sender: AnyObject) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = String.localizedString("Delete cached images", comment: "")
        alert.informativeText = String.localizedString("By clicking 'Delete' all locally cached images will be deleted. This may take a while", comment: "")
        alert.addButton(withTitle: String.localizedString("Delete", comment: ""))
        alert.addButton(withTitle: String.localizedString("Cancel", comment: ""))
        
        if alert.runModal() != NSApplication.ModalResponse.alertFirstButtonReturn {
            return
        }
        
        ImageUtils.clearCache()
    }
    
    // MARK: - Sparkle
    
    // Declares that we support gentle scheduled update reminders to Sparkle's standard user driver
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }
        
    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        // If the standard user driver will show the update in immediate focus (e.g. near app launch),
        // then let Sparkle take care of showing the update.
        // Otherwise we will handle showing any other scheduled updates
        return immediateFocus
    }
    
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        // We will ignore updates that the user driver will handle showing
        // This includes user initiated (non-scheduled) updates
        guard !handleShowingUpdate else {
            return
        }
        
        if !state.userInitiated {
            // And add a badge to the app's dock icon indicating one alert occurred
            NSApp.dockTile.badgeLabel = "1"
            NotificationManager.showNotification(type: .updateAvailable(version: update.displayVersionString))
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        // Clear the dock badge indicator for the update
        NSApp.dockTile.badgeLabel = ""
    }
    
    func standardUserDriverWillFinishUpdateSession() {
    }
}
