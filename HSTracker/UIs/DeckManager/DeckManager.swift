//
//  DeckManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 23/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import CleanroomLogger

class DeckManager: NSWindowController {

    @IBOutlet weak var decksTable: NSTableView!
    @IBOutlet weak var deckListTable: NSTableView!
    @IBOutlet weak var curveView: CurveView!
    @IBOutlet weak var statsLabel: NSTextField!
    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var archiveToolBarItem: NSToolbarItem!
    @IBOutlet weak var sortPopUp: NSPopUpButton!

    @IBOutlet weak var druidButton: NSButton!
    @IBOutlet weak var hunterButton: NSButton!
    @IBOutlet weak var mageButton: NSButton!
    @IBOutlet weak var paladinButton: NSButton!
    @IBOutlet weak var priestButton: NSButton!
    @IBOutlet weak var rogueButton: NSButton!
    @IBOutlet weak var shamanButton: NSButton!
    @IBOutlet weak var warlockButton: NSButton!
    @IBOutlet weak var warriorButton: NSButton!
    @IBOutlet weak var archiveButton: NSButton!
    @IBOutlet weak var toolbar: NSToolbar!

    @IBOutlet weak var hearthstatsButton: NSToolbarItem!

    var editDeck: EditDeck?
    var newDeck: NewDeck?
    var hearthstatsLogin: HearthstatsLogin?
    var trackobotLogin: TrackOBotLogin?

    var decks = [Deck]()
    var currentClass: CardClass?
    var currentDeck: Deck?
    var currentCell: DeckCellView?
    var statistics: Statistics?
    var showArchivedDecks = false
    
    let criterias = ["name", "creation date", "win percentage", "wins", "losses", "games played"]
    let orders = ["ascending", "descending"]
    var sortCriteria = Settings.instance.deckSortCriteria
    var sortOrder = Settings.instance.deckSortOrder

    override func windowDidLoad() {
        super.windowDidLoad()

        let nib = NSNib(nibNamed: "DeckCellView", bundle: nil)
        decksTable.register(nib, forIdentifier: "DeckCellView")

        decksTable.backgroundColor = NSColor.clear
        decksTable.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable,
                                       NSAutoresizingMaskOptions.viewHeightSizable]

        decksTable.tableColumns.first?.width = decksTable.bounds.width
        decksTable.tableColumns.first?.resizingMask = NSTableColumnResizingOptions.autoresizingMask

        decksTable.target = self

        refreshDecks()

        deckListTable.tableColumns.first?.width = deckListTable.bounds.width
        deckListTable.tableColumns.first?.resizingMask = .autoresizingMask
        
        loadSortPopUp()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (e) -> NSEvent? in
            let isCmd = e.modifierFlags.contains(.command)
            // let isShift = e.modifierFlags.contains(.ShiftKey)

            guard isCmd else { return e }

            switch e.keyCode {
            case 45:
                self.addDeck(self)
                return nil

            default:
                Log.verbose?.message("unsupported keycode \(e.keyCode)")
                break
            }

            return e
        }

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(DeckManager.updateStatsLabel),
                         name: NSNotification.Name(rawValue: "reload_decks"),
                         object: nil)

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(DeckManager.updateTheme(_:)),
                         name: NSNotification.Name(rawValue: "theme"),
                         object: nil)

        if let index = toolbar.items.index(of: hearthstatsButton), !HearthstatsAPI.isLogged() {
            toolbar.removeItem(at: index)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func sortedFilteredDecks() -> [Deck] {
        let filteredDeck = unsortedFilteredDecks()
        var sortedDeck: [Deck]
        let ascend = sortOrder == "ascending"
        
        switch self.sortCriteria {
        case "name":
            sortedDeck = filteredDeck.sorted(by: { $0.name < $1.name })
        case "creation date":
            sortedDeck = filteredDeck.sorted(by: { $0.creationDate < $1.creationDate })
        case "win percentage":
            sortedDeck = filteredDeck.sorted(by: {
                  StatsHelper.getDeckWinRate(record: StatsHelper.getDeckRecord(deck: $0)) <
                  StatsHelper.getDeckWinRate(record: StatsHelper.getDeckRecord(deck: $1)) })
        case "wins":
            sortedDeck = filteredDeck.sorted(by: {
                  StatsHelper.getDeckRecord(deck: $0).wins <
                  StatsHelper.getDeckRecord(deck: $1).wins })
        case "losses":
            sortedDeck = filteredDeck.sorted(by: {
                  StatsHelper.getDeckRecord(deck: $0).losses <
                  StatsHelper.getDeckRecord(deck: $1).losses })
        case "games played":
            sortedDeck = filteredDeck.sorted(by: {
                  StatsHelper.getDeckRecord(deck: $0).total <
                  StatsHelper.getDeckRecord(deck: $1).total })
        default:
            sortedDeck = filteredDeck
        }
        
        return ascend ? sortedDeck : sortedDeck.reversed()
    }
    
    func unsortedFilteredDecks() -> [Deck] {
        if let currentClass = currentClass {
            return decks.filter({ $0.playerClass == currentClass && $0.isActive == true })
                .sorted { $0.name < $1.name }
        } else if showArchivedDecks {
            return decks.filter({ $0.isActive != true }).sorted { $0.name < $1.name }
        } else {
            return decks.filter({ $0.isActive == true }).sorted { $0.name < $1.name }
        }
    }

    @IBAction func filterClassesAction(_ sender: NSButton) {
        let buttons = [druidButton, hunterButton, mageButton,
            paladinButton, priestButton, rogueButton,
            shamanButton, warlockButton, warriorButton,
            archiveButton
        ]
        for button in buttons {
            if sender != button {
                button?.state = NSOffState
            }
        }

        let oldCurrentClass = currentClass
        switch sender {
        case druidButton:
            currentClass = .druid
        case hunterButton:
            currentClass = .hunter
        case mageButton:
            currentClass = .mage
        case paladinButton:
            currentClass = .paladin
        case priestButton:
            currentClass = .priest
        case rogueButton:
            currentClass = .rogue
        case shamanButton:
            currentClass = .shaman
        case warlockButton:
            currentClass = .warlock
        case warriorButton:
            currentClass = .warrior
        default:
            currentClass = nil
        }

        showArchivedDecks = sender == archiveButton

        if currentClass == oldCurrentClass && currentDeck == nil {
            currentClass = nil
        }

        refreshDecks()
    }
    
    func updateStatsLabel() {
        if let currentDeck = self.currentDeck {
            DispatchQueue.main.async {
                self.statsLabel.stringValue = StatsHelper
                    .getDeckManagerRecordLabel(deck: currentDeck, mode: .all)
                self.curveView.reload()
            }
        }
    }

    func updateTheme(_ notification: Notification) {
        deckListTable.reloadData()
    }

    // MARK: - Toolbar actions
    override func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier {
        case "add", "donate", "twitter", "hearthstats", "gitter", "trackobot":
            return true
        case "edit", "use", "delete", "rename", "archive", "statistics", "export_hearthstone":
            return currentDeck != nil
        default:
            return false
        }
    }

    @IBAction func addDeck(_ sender: AnyObject) {
        newDeck = NewDeck(windowNibName: "NewDeck")
        if let newDeck = newDeck {
            newDeck.setDelegate(self)
            newDeck.defaultClass = currentClass ?? nil
            self.window!.beginSheet(newDeck.window!, completionHandler: nil)
        }
    }

    @IBAction func showStatistics(_ sender: AnyObject) {
        statistics = Statistics(windowNibName: "Statistics")
        if let statistics = statistics {
            statistics.deck = currentDeck
            self.window!.beginSheet(statistics.window!, completionHandler: { (returnCode) in
                self.refreshDecks()
            })
        }
    }
    
    @IBAction func trackobotLogin(_ sender: AnyObject) {
        if TrackOBotAPI.isLogged() {
            let msg = NSLocalizedString("Are you sure you want to disconnect from Track-o-Bot ?",
                                        comment: "")
            NSAlert.show(style: .informational,
                         message: msg,
                         window: self.window!) {
                            TrackOBotAPI.logout()
            }
        } else {
            trackobotLogin = TrackOBotLogin(windowNibName: "TrackOBotLogin")
            if let trackobotLogin = trackobotLogin {
                self.window!.beginSheet(trackobotLogin.window!, completionHandler: nil)
            }
        }
    }
    
    @IBAction func hearthstatsLogin(_ sender: AnyObject) {
        if HearthstatsAPI.isLogged() {
            let msg = NSLocalizedString("Are you sure you want to disconnect from Hearthstats ?",
                                        comment: "")
            NSAlert.show(style: .informational,
                         message: msg,
                         window: self.window!) {
                            HearthstatsAPI.logout()
            }
        } else {
            hearthstatsLogin = HearthstatsLogin(windowNibName: "HearthstatsLogin")
            if let hearthstatsLogin = hearthstatsLogin {
                self.window!.beginSheet(hearthstatsLogin.window!, completionHandler: nil)
            }
        }
    }

    @IBAction func donate(_ sender: AnyObject) {
        openUrl("https://www.paypal.com/cgi-bin/webscr?cmd=_donations"
            + "&business=bmichotte%40gmail%2ecom&lc=US&item_name=HSTracker"
            + "&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted")
    }

    @IBAction func twitter(_ sender: AnyObject) {
        openUrl("https://twitter.com/hstracker_mac")
    }

    @IBAction func gitter(_ sender: AnyObject) {
        openUrl("https://gitter.im/bmichotte/HSTracker")
    }
    
    fileprivate func openUrl(_ url: String) {
        let url = URL(string: url)
        NSWorkspace.shared().open(url!)
    }
    
    @IBAction func renameDeck(_ sender: AnyObject?) {
        if let deck = currentDeck {
            let deckNameInput = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
            deckNameInput.stringValue = deck.name
            NSAlert.show(style: .informational,
                         message: NSLocalizedString("Deck name", comment: ""),
                         accessoryView: deckNameInput,
                         window: self.window) {
                            do {
                                let realm = try Realm()
                                try realm.write {
                                    deck.name = deckNameInput.stringValue
                                }
                            } catch {
                                Log.error?.message("Can not update deck. \(error)")
                            }

                            if HearthstatsAPI.isLogged() &&
                                Settings.instance.hearthstatsAutoSynchronize {
                                do {
                                    try HearthstatsAPI.update(deck: deck) {_ in}
                                } catch {}
                            }

                            self.refreshDecks()
            }
        }
    }

    @IBAction func editDeck(_ sender: AnyObject?) {
        if let deck = currentDeck {
            editDeck = EditDeck(windowNibName: "EditDeck")
            if let editDeck = editDeck {
                editDeck.set(deck: deck)
                editDeck.set(playerClass: deck.playerClass)
                editDeck.setDelegate(self)
                editDeck.showWindow(self)
            }
        }
    }

    @IBAction func useDeck(_ sender: AnyObject?) {
        if let deck = currentDeck {
            if !deck.isActive {
                do {
                    let realm = try Realm()
                    try realm.write {
                        deck.isActive = true
                    }
                } catch {
                    Log.error?.message("Can not update deck : \(error)")
                }
                refreshDecks()
            }
            
            Settings.instance.activeDeck = deck.deckId
            Game.instance.set(activeDeck: deck)
        }
    }

    @IBAction func deleteDeck(_ sender: AnyObject?) {
        if let deck = currentDeck {
            let message = String(format: NSLocalizedString("Are you sure you want to delete "
                + "the deck %@ ?", comment: ""), deck.name)

            NSAlert.show(style: .informational, message: message, window: self.window!) {
                self._deleteDeck(deck)
            }
        }
    }

    @IBAction func archiveDeck(_ sender: AnyObject) {
        if let deck = currentDeck {
            let msg: String
            if deck.isActive {
                msg = String(format: NSLocalizedString("Are you sure you want to archive "
                    + "the deck %@ ?", comment: ""), deck.name)
            } else {
                msg = String(format: NSLocalizedString("Are you sure you want to unarchive "
                    + "the deck %@ ?", comment: ""), deck.name)
            }

            NSAlert.show(style: .informational, message: msg, window: self.window!) {
                do {
                    let realm = try Realm()
                    try realm.write {
                        deck.isActive = !deck.isActive
                    }
                } catch {
                    Log.error?.message("Can not update deck : \(error)")
                }

                Settings.instance.activeDeck = nil
                self.refreshDecks()
            }
        }
    }

    fileprivate func _deleteDeck(_ currentDeck: Deck) {
        decksTable.deselectAll(self)
        self.currentDeck = nil

        guard let realm = try? Realm() else {
            Log.error?.message("Can not get realm instance")
            refreshDecks()
            return
        }
        guard let deck = realm.objects(Deck.self)
            .filter("deckId = '\(currentDeck.deckId)'").first else {
                Log.error?.message("Can not get deck")
                refreshDecks()
                return
        }
        
        if let _ = deck.hearthstatsId.value, HearthstatsAPI.isLogged() {
            if Settings.instance.hearthstatsAutoSynchronize {
                do {
                    try HearthstatsAPI.delete(deck: deck)
                } catch {
                    Log.error?.message("error delete hearthstats")
                }
                do {
                    try realm.write {
                        realm.delete(deck)
                    }
                } catch {
                    Log.error?.message("Can not delete deck : \(error)")
                }
                refreshDecks()
            } else {
                let msg = NSLocalizedString("Do you want to delete the deck on Hearthstats ?",
                                            comment: "")
                NSAlert.show(style: .informational, message: msg, window: self.window!) {
                    do {
                        try HearthstatsAPI.delete(deck: deck)
                    } catch {
                        Log.error?.message("error delete hearthstats")
                    }
                    do {
                        try realm.write {
                            realm.delete(deck)
                        }
                    } catch {
                        Log.error?.message("Can not delete deck : \(error)")
                    }
                    self.refreshDecks()
                }
            }
        } else {
            do {
                try realm.write {
                    realm.delete(deck)
                }
            } catch {
                Log.error?.message("Can not delete deck : \(error)")
            }
            refreshDecks()
        }
    }

    fileprivate func loadSortPopUp() {
        let popupMenu = NSMenu()
        
        for criteria in criterias {
            let popupMenuItem = NSMenuItem(title: NSLocalizedString(criteria, comment: ""),
                action: #selector(DeckManager.changeSort(_:)),
                keyEquivalent: "")
            popupMenuItem.representedObject = criteria
            popupMenu.addItem(popupMenuItem)
        }
        
        popupMenu.addItem(NSMenuItem.separator())
        
        for order in orders {
            let popupMenuItem = NSMenuItem(title: NSLocalizedString(order, comment: ""),
                                           action: #selector(DeckManager.changeSort(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = order
            popupMenu.addItem(popupMenuItem)
        }
        
        popupMenu.item(withTitle: NSLocalizedString(sortCriteria, comment: ""))?.state = NSOnState
        popupMenu.item(withTitle: NSLocalizedString(sortOrder, comment: ""))?.state = NSOnState
        
        let firstItemMenu = NSMenuItem(title: NSLocalizedString(sortCriteria, comment: ""),
                                       action: #selector(DeckManager.changeSort(_:)),
                                       keyEquivalent: "")
        firstItemMenu.representedObject = sortCriteria
        popupMenu.insertItem(firstItemMenu, at: 0)
        
        sortPopUp.menu = popupMenu
    }
    
    @IBAction func changeSort(_ sender: NSMenuItem) {
        // Unset the previously selected one, select the new one
        var previous: String = ""

        if let idx = sender.menu?.index(of: sender), idx <= criterias.count {
            previous = sortCriteria
            if let criteria = sender.representedObject as? String {
                sortCriteria = criteria
                Settings.instance.deckSortCriteria = sortCriteria
                
                let firstMenuItem = sortPopUp.menu?.item(at: 0)
                firstMenuItem?.representedObject = sender.representedObject
                firstMenuItem?.title = sender.title
            }
        } else {
            // Ascending/Descending
            previous = sortOrder
            if let order = sender.representedObject as? String {
                sortOrder = order
                Settings.instance.deckSortOrder = sortOrder
            }
        }
        
        let prevSelected = sortPopUp.menu?.item(withTitle: NSLocalizedString(previous, comment: ""))
        
        if sender.state != NSOnState {
            self.refreshDecks()
        }
        
        prevSelected?.state = NSOffState
        sender.state = NSOnState
    }
    
    @IBAction func exportToHearthstone(_ sender: AnyObject?) {
        if let deck = currentDeck {
            let msg = String(format: NSLocalizedString("To export a deck to Hearthstone, "
                + "create a new deck with the correct class in your collection, then click OK "
                + "and switch to Hearthstone.\nDo not touch your mouse or keyboard "
                + "during the import.", comment: ""), deck.name)
            NSAlert.show(style: .informational, message: msg, window: self.window!) {
                self.exportDeckToHearthstone(deck)
            }
        }
    }
    
    fileprivate func exportDeckToHearthstone(_ deck: Deck) {
        let when = DispatchTime.now() + DispatchTimeInterval.seconds(2)
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: when) {
            let automation = Automation()
            automation.expertDeckToHearthstone(deck: deck) {
                NSAlert.show(style: .informational,
                             message: NSLocalizedString("Export done", comment: ""),
                             window: self.window!, forceFront: true)
            }
        }
    }
}

// MARK: - NSTableViewDelegate
extension DeckManager: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == decksTable {
            if let cell = decksTable?.make(withIdentifier: "DeckCellView", owner: self)
                as? DeckCellView {

                let deck = sortedFilteredDecks()[row]
                cell.deck = deck
                cell.label.stringValue = deck.name
                cell.image.image = NSImage(named: deck.playerClass.rawValue.lowercased())
                cell.arenaImage.image = deck.isArena && deck.arenaFinished() ?
                    NSImage(named: "silenced") : nil
                cell.wildImage.image = deck.isArena ? NSImage(named: "arena") :
                    !deck.standardViable() && !deck.isArena ?
                    NSImage(named: "Mode_Wild") : nil
                cell.color = ClassColor.color(playerClass: deck.playerClass)
                cell.selected = tableView.selectedRow == -1 || tableView.selectedRow == row
                
                let record = StatsHelper.getDeckRecord(deck: deck, mode: .all)
                switch sortCriteria {
                case "creation date":
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    cell.detailTextLabel.stringValue =
                        "\(formatter.string(from: deck.creationDate))"
                case "wins":
                    cell.detailTextLabel.stringValue = "\(record.wins) " +
                        NSLocalizedString("wins", comment: "").lowercased()
                case "losses":
                    cell.detailTextLabel.stringValue = "\(record.losses) " +
                        NSLocalizedString("losses", comment: "").lowercased()
                case "games played":
                    cell.detailTextLabel.stringValue = "\(record.total) " +
                        NSLocalizedString("games", comment: "").lowercased()
                default:
                    cell.detailTextLabel.stringValue = StatsHelper
                        .getDeckManagerRecordLabel(deck: deck, mode: .all)
                }

                return cell
            }
        } else {
            let cell = CardBar.factory()
            cell.playerType = .deckManager
            cell.card = currentDeck?.sortedCards[row]
            return cell
        }

        return nil
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == self.decksTable {
            return 55
        } else if tableView == self.deckListTable {
            return CGFloat(kRowHeight)
        }
        return 20
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let decks = sortedFilteredDecks().count
        guard decks == (notification.object as? NSTableView)?.numberOfRows else { return }
        
        for i in 0 ..< decks {
            let row = decksTable?.view(atColumn: 0, row: i, makeIfNecessary: false) as? DeckCellView
            row?.selected = decksTable?.selectedRow == -1 || decksTable?.selectedRow == i
        }
        
        if let clickedRow = (notification.object as? NSTableView)?.selectedRow, clickedRow >= 0 {
            currentDeck = sortedFilteredDecks()[clickedRow]
            let labelName = currentDeck?.isActive == true ? "Archive" : "Unarchive"
            self.archiveToolBarItem.label = NSLocalizedString(labelName, comment: "")
            deckListTable.reloadData()
            curveView.deck = currentDeck
            updateStatsLabel()
            
            toolbar.validateVisibleItems()
            decksTable?.setNeedsDisplay()
        }
    }
}

// MARK: - NSTableViewDataSource
extension DeckManager: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == decksTable {
            return sortedFilteredDecks().count
        } else if let currentDeck = currentDeck {
            return currentDeck.sortedCards.count
        }

        return 0
    }
}

// MARK: - NewDeckDelegate
extension DeckManager: NewDeckDelegate {
    func addNewDeck(deck: Deck) {
        refreshDecks()
    }

    func openDeckBuilder(playerClass: CardClass, arenaDeck: Bool) {
        editDeck = EditDeck(windowNibName: "EditDeck")
        if let editDeck = editDeck {
            let deck = Deck()
            deck.playerClass = playerClass
            deck.isArena = arenaDeck
            editDeck.set(deck: deck)
            editDeck.set(playerClass: playerClass)
            editDeck.setDelegate(self)
            editDeck.showWindow(self)
        }
    }

    func refreshDecks() {
        // Guard incase we are creating a new deck without the window loaded
        guard isWindowLoaded else { return }
        currentDeck = nil
        decksTable.deselectAll(self)
        decks = []
        do {
            let realm = try Realm()
            decks = Array(realm.objects(Deck.self))
        } catch {
            Log.error?.message("Can not load decks : \(error)")
        }
        decksTable.reloadData()
        deckListTable.reloadData()
    }
}
