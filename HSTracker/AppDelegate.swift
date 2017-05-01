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
import HearthAssets
import HockeySDK

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
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
	
	var preferences: MASPreferencesWindowController = {
		var controllers = [
			GeneralPreferences(nibName: "GeneralPreferences", bundle: nil)!,
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
		
		// init debug loggers
		var loggers = [LogConfiguration]()
		#if DEBUG
            let xcodeConfig = ConsoleLogConfiguration(minimumSeverity: .verbose,
                                                      stdStreamsMode: .useExclusively,
                                                      formatters: [HSTrackerLogFormatter()])
			loggers.append(xcodeConfig)
		#endif
		
		let path = Paths.logs.path
		let severity = Settings.logSeverity
		let rotatingConf = RotatingLogFileConfiguration(minimumSeverity: severity,
		                                                daysToKeep: 7,
		                                                directoryPath: path,
		                                                formatters: [HSTrackerLogFormatter()])
		loggers.append(rotatingConf)
		Log.enable(configuration: loggers)
		
		Log.info?.message("*** Starting \(Version.buildName) ***")
		
		// fix hearthstone log folder path
		if Settings.hearthstonePath.hasSuffix("/Logs") {
			Settings.hearthstonePath = Settings.hearthstonePath.replace("/Logs", with: "")
		}
		
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
		
		coreManager = CoreManager()
		
		DispatchQueue.global().async { [unowned(unsafe) self] in
			// load build dates via http request
			let buildsOperation = BlockOperation {
				BuildDates.loadBuilds(splashscreen: self.splashscreen!)
				/*if BuildDates.isOutdated() || !Database.jsonFilesAreValid() {
					BuildDates.downloadCards(splashscreen: self.splashscreen!)
				}*/
			}

            // load card tier via http request
            let cardTierOperation = BlockOperation {
                ArenaHelperSync.checkTierList(splashscreen: self.splashscreen!)
                if ArenaHelperSync.isOutdated() || !ArenaHelperSync.jsonFilesAreValid() {
                    ArenaHelperSync.downloadTierList(splashscreen: self.splashscreen!)
                }
            }
			
			// load and generate assets from hearthstone files
			let assetsOperation = BlockOperation {
				DispatchQueue.main.async { [weak self] in
					self?.splashscreen?.display(
						NSLocalizedString("Loading Hearthstone assets", comment: ""),
						indeterminate: true)
				}
			}
			
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
					Log.info?.message("Loading menu")
					self.buildMenu()
				}
			}
			
			databaseOperation.addDependency(buildsOperation)
			if Settings.useHearthstoneAssets {
				databaseOperation.addDependency(assetsOperation)
				assetsOperation.addDependency(buildsOperation)
			}
			
			var operations = [Operation]()
			operations.append(buildsOperation)
            operations.append(cardTierOperation)
			if Settings.useHearthstoneAssets {
				operations.append(assetsOperation)
			}
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
		var alertStyle = NSAlertStyle.critical
		do {
			let canStart = try coreManager.setup()
			
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
		
		coreManager.start()
		
		let events = [
			"reload_decks": #selector(AppDelegate.reloadDecks(_:)),
			"hstracker_language": #selector(AppDelegate.languageChange(_:))
		]
		
		for (event, selector) in events {
			NotificationCenter.default.addObserver(self,
			                                       selector: selector,
			                                       name: NSNotification.Name(rawValue: event),
			                                       object: nil)
		}
		
		if let activeDeck = Settings.activeDeck {
			self.coreManager.game.set(activeDeckId: activeDeck)
		}
		
		splashscreen?.close()
		splashscreen = nil
	}
	
	func reloadDecks(_ notification: Notification) {
		buildMenu()
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
			let mainMenu = NSApplication.shared().mainMenu
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
			self.coreManager.game.set(activeDeckId: deckId)
		}
	}
	
	@IBAction func openDeckManager(_ sender: AnyObject) {
		if deckManager == nil {
			deckManager = DeckManager(windowNibName: "DeckManager")
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
				deckManager = DeckManager(windowNibName: "DeckManager")
			}
			let deck = Deck()
			deck.playerClass = playerClass
            deck.name = player.name ?? "Custom \(playerClass)"
            player.playerCardList.filter({ $0.collectible == true }).forEach {
                deck.add(card: $0)
            }
            
            RealmHelper.add(deck: deck)
            deckManager?.currentDeck = deck
            deckManager?.editDeck(self)
		}
	}
	
	@IBAction func openPreferences(_ sender: AnyObject) {
		preferences.showWindow(self)
	}
	
	@IBAction func lockWindows(_ sender: AnyObject) {
		let mainMenu = NSApplication.shared().mainMenu
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
