//
//  AppDelegate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import SwiftyBeaver
let logger = SwiftyBeaver.self
import MASPreferences
//import HearthAssets
import HockeySDK
import OAuthSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
    static var _instance: AppDelegate?
    static func instance() -> AppDelegate {
        return _instance!
    }
    
	let hockeyHelper = HockeyHelper()
	var appWillRestart = false
	var splashscreen: Splashscreen?
	var initalConfig: InitialConfiguration?
	var deckManager: DeckManager?
	@IBOutlet weak var sparkleUpdater: SUUpdater!
	var operationQueue: OperationQueue!
	
	var dockMenu = NSMenu(title: "DockMenu")
	var appHealth: AppHealth = AppHealth.instance
	
	var coreManager: CoreManager!
    var triggers: [NSObjectProtocol] = []
	
	var preferences: MASPreferencesWindowController = {
		var controllers = [
			GeneralPreferences(nibName: NSNib.Name(rawValue: "GeneralPreferences"), bundle: nil),
			GamePreferences(nibName: NSNib.Name(rawValue: "GamePreferences"), bundle: nil),
			TrackersPreferences(nibName: NSNib.Name(rawValue: "TrackersPreferences"), bundle: nil),
			PlayerTrackersPreferences(nibName: NSNib.Name(rawValue: "PlayerTrackersPreferences"), bundle: nil),
			OpponentTrackersPreferences(nibName: NSNib.Name(rawValue: "OpponentTrackersPreferences"), bundle: nil),
			HSReplayPreferences(nibName: NSNib.Name(rawValue: "HSReplayPreferences"), bundle: nil)
        ]
		
		let preferences = MASPreferencesWindowController(
			viewControllers: controllers,
			title: NSLocalizedString("Preferences", comment: ""))
		return preferences
	}()
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate._instance = self
        
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
			alert.addButton(withTitle: NSLocalizedString("I understand", comment: ""))
			// swiftlint:disable line_length
			alert.messageText = NSLocalizedString("HSTracker needs elevated privileges to read data from Hearthstone's memory. If macOS asks you for your system password, do not be alarmed, no changes to your computer will be performed.", comment: "")
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
		
		// init debug loggers
		#if DEBUG
            let console = ConsoleDestination()
            logger.addDestination(console)
		#endif
		
        // setup logger
		let path = Paths.logs
        let file = FileDestination()
        file.logFileURL = path.appendingPathComponent("hstracker.log")
		logger.addDestination(file)
		logger.info("*** Starting \(Version.buildName) ***")
		
        // check if we have valid settings
		if Settings.validated() {
			loadSplashscreen()
		} else {
			initalConfig = InitialConfiguration(windowNibName: NSNib.Name(rawValue: "InitialConfiguration"))
			initalConfig?.completionHandler = {
				self.loadSplashscreen()
			}
			initalConfig?.showWindow(nil)
			initalConfig?.window?.orderFrontRegardless()
		}
        
        hockeyHelper.logEvent(name: "app_start")
	}
	
	func applicationWillTerminate(_ notification: Notification) {
		coreManager.stopTracking()
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
		
		splashscreen = Splashscreen(windowNibName: NSNib.Name(rawValue: "Splashscreen"))
		let screenFrame = NSScreen.screens.first!.frame
		let splashscreenWidth: CGFloat = 350
		let splashscreenHeight: CGFloat = 250
		
		splashscreen?.window?.setFrame(NSRect(
			x: (screenFrame.width / 2) - (splashscreenWidth / 2),
			y: (screenFrame.height / 2) - (splashscreenHeight / 2),
			width: splashscreenWidth,
			height: splashscreenHeight),
		                               display: true)
		splashscreen?.showWindow(self)
		
		logger.info("Opening trackers")
		
		coreManager = CoreManager()
		
		DispatchQueue.global().async { [unowned(unsafe) self] in
            // load card tier via http request
            let cardTierOperation = BlockOperation {
                ArenaHelperSync.checkTierList(splashscreen: self.splashscreen!)
                if ArenaHelperSync.isOutdated() || !ArenaHelperSync.jsonFilesAreValid() {
                    ArenaHelperSync.downloadTierList(splashscreen: self.splashscreen!)
                }
            }
			
			// load and generate assets from hearthstone files
			/*let assetsOperation = BlockOperation {
				DispatchQueue.main.async { [weak self] in
					self?.splashscreen?.display(
						NSLocalizedString("Loading Hearthstone assets", comment: ""),
						indeterminate: true)
				}
			}*/
			
			// load and init local database
			let databaseOperation = BlockOperation {
				let database = Database()
                var langs: [Language.Hearthstone] = []
                if let language = Settings.hearthstoneLanguage, language != .enUS {
                    langs += [language]
                }
                langs += [.enUS]
				database.loadDatabase(splashscreen: self.splashscreen!, withLanguages: langs)
			}
			
			// build menu
			let menuOperation = BlockOperation {
				OperationQueue.main.addOperation {
					logger.info("Loading menu")
					self.buildMenu()
				}
			}
			
			/*if Settings.useHearthstoneAssets {
				databaseOperation.addDependency(assetsOperation)
				assetsOperation.addDependency(buildsOperation)
			}*/
			
			var operations = [Operation]()
            operations.append(cardTierOperation)
			/*if Settings.useHearthstoneAssets {
				operations.append(assetsOperation)
			}*/
			operations.append(databaseOperation)
			operations.append(menuOperation)
			
			self.operationQueue = OperationQueue()
			self.operationQueue.addOperations(operations, waitUntilFinished: true)
			
			DispatchQueue.main.async { [unowned(unsafe) self] in
				self.completeSetup()
			}
		}
	}
	
	/** Finished setup, should only be called once */
	private func completeSetup() {
		
		var message: String?
		var alertStyle = NSAlert.Style.critical
		do {
			let canStart = try coreManager.setup()
			
			if !canStart {
				message = NSLocalizedString("You must restart Hearthstone for logs to be used", comment: "")
				alertStyle = .informational
			}
		} catch HearthstoneLogError.canNotCreateDir {
			message = NSLocalizedString("Can not create Hearthstone config dir", comment: "")
		} catch HearthstoneLogError.canNotReadFile {
			message = NSLocalizedString("Can not read Hearthstone config file", comment: "")
		} catch HearthstoneLogError.canNotCreateFile {
			message = NSLocalizedString("Can not write Hearthstone config file", comment: "")
		} catch {
			message = NSLocalizedString("Unknown error", comment: "")
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
		
		coreManager.start()

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
			self.coreManager.game.set(activeDeckId: activeDeck, autoDetected: false)
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
		             message: NSLocalizedString("You must restart HSTracker for the language change to take effect", comment: ""))
		
		appWillRestart = true
		NSApplication.shared.terminate(nil)
		exit(0)
	}
	
	// MARK: - Menu
	
	/**
	Builds the menu and its items.
	*/
	func buildMenu() {		
		DispatchQueue.main.async { [unowned(unsafe) self] in
			guard let decks = RealmHelper.getActiveDecks() else {
				return
			}
			
			// build main menu
			// ---------------
			let mainMenu = NSApplication.shared.mainMenu
			let deckMenu = mainMenu?.item(withTitle: NSLocalizedString("Decks", comment: ""))
			deckMenu?.submenu?.removeAllItems()
			deckMenu?.submenu?.addItem(withTitle: NSLocalizedString("Deck Manager", comment: ""),
			                           action: #selector(AppDelegate.openDeckManager(_:)),
			                           keyEquivalent: "d")
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
            
            if self.dockMenu.item(withTag: 2) == nil {
                self.dockMenu.addItem(NSMenuItem.separator())
                let deckmanager = NSMenuItem(title: NSLocalizedString("Deck Manager", comment: ""),
                                           action: #selector(AppDelegate.openDeckManager(_:)), keyEquivalent: "d")
                deckmanager.tag = 2
                self.dockMenu.addItem(deckmanager)
            }
            
            if self.dockMenu.item(withTag: 3) == nil {
                self.dockMenu.addItem(NSMenuItem.separator())
                let preferences = NSMenuItem(title: NSLocalizedString("Preferences", comment: ""),
                                             action: #selector(AppDelegate.openPreferences(_:)), keyEquivalent: "")
                preferences.tag = 3
                self.dockMenu.addItem(preferences)
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
						name += " (\(NSLocalizedString(opponentClass.rawValue, comment: "")))"
					}
					
					if let item = replaysMenu?.submenu?
						.addItem(withTitle: name,
						         action: #selector(self.showReplay(_:)),
						         keyEquivalent: "") {
						item.representedObject = stat.hsReplayId
					}
				}
			}
			
			let windowMenu = mainMenu?.item(withTitle: NSLocalizedString("Window", comment: ""))
			let item = windowMenu?.submenu?.item(withTitle: NSLocalizedString("Lock windows",
			                                                                  comment: ""))
			item?.title = NSLocalizedString(Settings.windowsLocked ?  "Unlock windows" : "Lock windows",
			                                comment: "")
		}
	}
	
	@objc func showReplay(_ sender: NSMenuItem) {
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
			if returnCode.rawValue == NSFileHandlingPanelOKButton {
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
	
	@objc func playDeck(_ sender: NSMenuItem) {
		if let deck = sender.representedObject as? Deck {
			let deckId = deck.deckId
			self.coreManager.game.set(activeDeckId: deckId, autoDetected: false)
		}
	}
	
	@IBAction func openDeckManager(_ sender: AnyObject) {
		if deckManager == nil {
			deckManager = DeckManager(windowNibName: NSNib.Name(rawValue: "DeckManager"))
			deckManager?.game = coreManager.game
		}
		deckManager?.showWindow(self)
	}
	
	@IBAction func clearTrackers(_ sender: AnyObject) {
		coreManager.game.removeActiveDeck()
	}
	
	@IBAction func saveCurrentDeck(_ sender: AnyObject) {
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
		if let playerClass = player.playerClass {
			if deckManager == nil {
				deckManager = DeckManager(windowNibName: NSNib.Name(rawValue: "DeckManager"))
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
		preferences.showWindow(self)
	}
	
	@IBAction func lockWindows(_ sender: AnyObject) {
		let mainMenu = NSApplication.shared.mainMenu
		let windowMenu = mainMenu?.item(withTitle: NSLocalizedString("Window", comment: ""))
		let text = Settings.windowsLocked ? "Unlock windows" : "Lock windows"
		let item = windowMenu?.submenu?.item(withTitle: NSLocalizedString(text, comment: ""))
		Settings.windowsLocked = !Settings.windowsLocked
		item?.title = NSLocalizedString(Settings.windowsLocked ?  "Unlock windows" : "Lock windows",
		                                comment: "")
	}
	
	#if DEBUG
	var windowMove: WindowMove?
	@IBAction func openDebugPositions(_ sender: AnyObject) {
		if windowMove == nil {
			windowMove = WindowMove(windowNibName: "WindowMove", windowManager: coreManager.game.windowManager)
		}
		windowMove?.showWindow(self)
	}
	#endif
	
	@IBAction func closeWindow(_ sender: AnyObject) {
	}
	
	@IBAction func openReplayDirectory(_ sender: AnyObject) {
		NSWorkspace.shared.activateFileViewerSelecting([Paths.replays])
	}
}

extension AppDelegate: SUUpdaterDelegate {
	
	func feedParameters(for updater: SUUpdater,
	                    sendingSystemProfile sendingProfile: Bool) -> [[String: String]] {
		var parameters: [[String: String]] = []
		for data: Any in BITSystemProfile.shared().systemUsageData() {
			if let dict = data as? [String: String] {
				parameters.append(dict)
			}
		}
		return parameters
	}
}
