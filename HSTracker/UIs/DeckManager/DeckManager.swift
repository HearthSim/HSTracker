//
//  DeckManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 23/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import AppKit

class DeckContextMenu: NSMenu {
    public var clickedrow: Int = 0
}

class DeckTable: NSTableView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event)
        if let m = menu as? DeckContextMenu {
            let mousePoint: NSPoint  = self.convert(event.locationInWindow, from: nil)
            m.clickedrow = self.row(at: mousePoint)
            return m
        }

        return menu
    }
}

class DeckManager: NSWindowController {

    @IBOutlet weak var decksTable: NSTableView!
    @IBOutlet weak var deckListTable: NSTableView!
    @IBOutlet weak var curveView: CurveView!
    @IBOutlet weak var statsLabel: NSTextField!
    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var archiveToolBarItem: NSToolbarItem!
    @IBOutlet weak var sortPopUp: NSPopUpButton!
    @IBOutlet weak var deckTypePopup: NSPopUpButton!

    @IBOutlet weak var classesPopup: NSPopUpButton!
    @IBOutlet weak var toolbar: NSToolbar!

    var editDeck: EditDeck?
    var newDeck: NewDeck?

    var decks = [Deck]()
    var currentClass: CardClass?
    var currentDeckType: DeckType = .all
    var currentDeck: Deck?
    var currentCell: DeckCellView?
    var statistics: Statistics?
    var showArchivedDecks = false
    
    let criterias = ["name", "creation date", "win percentage", "wins", "losses", "games played"]
    let orders = ["ascending", "descending"]
    var sortCriteria = Settings.deckSortCriteria
    var sortOrder = Settings.deckSortOrder
	var triggers: [NSObjectProtocol] = []
    
	weak var game: Game?

    override func windowDidLoad() {
        super.windowDidLoad()

        let nib = NSNib(nibNamed: "DeckCellView", bundle: nil)
        decksTable.register(nib, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeckCellView"))

        decksTable.backgroundColor = NSColor.clear
        decksTable.autoresizingMask = [NSView.AutoresizingMask.width,
                                       NSView.AutoresizingMask.height]

        decksTable.tableColumns.first?.width = decksTable.bounds.width
        decksTable.tableColumns.first?.resizingMask = NSTableColumn.ResizingOptions.autoresizingMask

        decksTable.target = self

        refreshDecks()

        deckListTable.tableColumns.first?.width = deckListTable.bounds.width
        deckListTable.tableColumns.first?.resizingMask = NSTableColumn.ResizingOptions.autoresizingMask
        
        loadSortPopUp()
        loadClassesPopUp()
        loadModesPopup()

        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { (e) -> NSEvent? in
            let isCmd = e.modifierFlags.contains(NSEvent.ModifierFlags.command)
            // let isShift = e.modifierFlags.contains(.ShiftKey)

            guard isCmd else { return e }

            switch e.keyCode {
            case 45:
                self.addDeck(self)
                return nil

            default:
                logger.verbose("unsupported keycode \(e.keyCode)")
            }

            return e
        }
        
        let center = NotificationCenter.default
        
        if triggers.count == 0 {
            let events = [
                Events.reload_decks: self.updateStatsLabel,
                Settings.theme_token: self.updateTheme
            ]
            for (event, trigger) in events {
                let observer = center.addObserver(forName: NSNotification.Name(rawValue: event), object: nil, queue: OperationQueue.main) { _ in
                    trigger()
                }
                triggers.append(observer)
            }
        }
    }
    
    deinit {
        for token in triggers {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    override func showWindow(_ sender: Any?) {
        
        refreshDecks()
        super.showWindow(sender)
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
    
    func isCurrentDeckType(deck: Deck) -> Bool {
        switch currentDeckType {
        case .all:
            return true
        case .duels:
            return deck.isDuels
        case .dungeon:
            return deck.isDungeon
        case .arena:
            return deck.isArena
        case .wild:
            return deck.isWildDeck && !deck.isDungeon && !deck.isDuels
        case .standard:
            return !deck.isWildDeck
        case .classic:
            return deck.isClassicDeck
        }
    }
    
    func unsortedFilteredDecks() -> [Deck] {
        if let currentClass = currentClass {
            return decks.filter({ isCurrentDeckType(deck: $0) && $0.playerClass == currentClass && $0.isActive == true })
                .sorted { $0.name < $1.name }
        } else if showArchivedDecks {
            return decks.filter({ isCurrentDeckType(deck: $0) && $0.isActive != true }).sorted { $0.name < $1.name }
        } else {
            return decks.filter({ isCurrentDeckType(deck: $0) && $0.isActive == true }).sorted { $0.name < $1.name }
        }
    }

    @IBAction func filterClassesAction(_ sender: Any) {
        guard let menuItem = sender as? NSMenuItem else { return }

        if let selectedClass = menuItem.representedObject as? CardClass {
            currentClass = selectedClass == .neutral ? nil : selectedClass
            showArchivedDecks = false
        } else {
            showArchivedDecks = true
        }

        refreshDecks()
    }
    
    @IBAction func filterDeckTypeAction(_ sender: Any) {
        guard let menuItem = sender as? NSMenuItem else { return }

        if let deckType = menuItem.representedObject as? DeckType {
            currentDeckType = deckType
        }

        refreshDecks()
    }

    func updateStatsLabel() {
        if let currentDeck = self.currentDeck, !currentDeck.isInvalidated {
            DispatchQueue.main.async {
                self.statsLabel.stringValue = StatsHelper
                    .getDeckManagerRecordLabel(deck: currentDeck, mode: .all)
                self.curveView.reload()
            }
        } else {
            self.currentDeck = nil
        }
    }

    func updateTheme() {
        deckListTable.reloadData()
    }

    // MARK: - Toolbar actions
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier.rawValue {
        case "add", "twitter", "discord":
            return true
        case "edit", "use", "delete", "rename", "archive", "statistics", "export_hearthstone", "export":
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
            self.window!.beginSheet(statistics.window!) { _ in
                self.refreshDecks()
            }
        }
    }

    @IBAction func twitter(_ sender: AnyObject) {
        openUrl("https://twitter.com/hstracker_mac")
    }

    @IBAction func discord(_ sender: AnyObject) {
        openUrl("https://hsreplay.net/discord/")
    }
    
    fileprivate func openUrl(_ url: String) {
        let url = URL(string: url)
        NSWorkspace.shared.open(url!)
    }
    
    @IBAction func renameDeck(_ sender: AnyObject?) {
        if (sender as? NSToolbarItem) != nil {
            if let deck = currentDeck {
                renameDeck(deck)
            }
        } else if let menuitem = sender as? NSMenuItem {
            if let menu = menuitem.menu {
                if let deckmenu = menu as? DeckContextMenu {
                    if deckmenu.clickedrow >= 0 {
                        renameDeck(sortedFilteredDecks()[deckmenu.clickedrow])
                    }
                }
            }
        }
    }
    
    private func renameDeck(_ deck: Deck) {
        let deckNameInput = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        deckNameInput.stringValue = deck.name
        NSAlert.show(style: .informational,
                     message: NSLocalizedString("Deck name", comment: ""),
                     accessoryView: deckNameInput,
                     window: self.window) {
                        RealmHelper.rename(deck: deck, to: deckNameInput.stringValue)
                        self.refreshDecks()
        }

    }

    @IBAction func editDeck(_ sender: AnyObject?) {
        if let menuitem = sender as? NSMenuItem {
            if let menu = menuitem.menu {
                if let deckmenu = menu as? DeckContextMenu {
                    if deckmenu.clickedrow >= 0 {
                        editDeck(sortedFilteredDecks()[deckmenu.clickedrow])
                    }
                }
            }
        } else {
            if let deck = currentDeck {
                editDeck(deck)
            }
        }
    }
    
    private func editDeck(_ deck: Deck) {
        editDeck = EditDeck(windowNibName: "EditDeck")
        if let editDeck = editDeck {
            editDeck.set(deck: deck)
            editDeck.set(playerClass: deck.playerClass)
            editDeck.setDelegate(self)
            editDeck.showWindow(self)
        }
    }

    @IBAction func useDeck(_ sender: Any?) {
        if sender as? NSToolbarItem != nil,
            let deck = currentDeck {
            useDeck(deck: deck)
        } else if let menuitem = sender as? NSMenuItem,
            let menu = menuitem.menu,
            let deckmenu = menu as? DeckContextMenu,
            deckmenu.clickedrow >= 0 {
            useDeck(deck: sortedFilteredDecks()[deckmenu.clickedrow])
        } else if let button = sender as? NSButton, let sv = button.superview as? DeckCellView {
            logger.debug("Use deck row \(sv.row)")
            let deck = sortedFilteredDecks()[sv.row]
            currentDeck = deck
            useDeck(deck: sortedFilteredDecks()[sv.row])
        }
    }

    private func useDeck(deck: Deck) {
        RealmHelper.set(deck: deck, active: true)
        refreshDecks()
        
        Settings.activeDeck = deck.deckId
        let deckId = deck.deckId
        DispatchQueue.main.async { [unowned(unsafe) self] in
            self.game?.set(activeDeckId: deckId, autoDetected: false)
        }
    }

    @IBAction func deleteDeck(_ sender: AnyObject?) {
        if sender as? NSToolbarItem != nil,
           let selection = decksTable?.selectedRowIndexes {
            if selection.count == 1 {
                let decks = sortedFilteredDecks()
                let deck = decks[selection.first ?? decks.startIndex]
                deleteDeck(deck)
            } else if selection.count > 1 {
                deleteDecks(selection)
            }
        } else if let menuitem = sender as? NSMenuItem,
            let menu = menuitem.menu,
            let deckmenu = menu as? DeckContextMenu,
            deckmenu.clickedrow >= 0 {
            deleteDeck(sortedFilteredDecks()[deckmenu.clickedrow])
        }
    }

    private func deleteDeck(_ deck: Deck) {
        let message = String(format: NSLocalizedString("Are you sure you want to delete "
            + "the deck %@ ?", comment: ""), deck.name)
        
        NSAlert.show(style: .informational, message: message, window: self.window!) {
            self._deleteDeck(deck)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Events.reload_decks),
                                            object: deck)
        }
    }

    private func deleteDecks(_ decks: IndexSet) {
        let message = String(format: NSLocalizedString("Are you sure you want to delete "
                                                        + "the selected %d deck(s) ?", comment: ""), decks.count)
        
        NSAlert.show(style: .informational, message: message, window: self.window!) {
            var arr = [Deck]()
            let allDecks = self.sortedFilteredDecks()
            for idx in decks {
                arr.append(allDecks[idx])
            }
            for deck in arr {
                self._deleteDeck(deck)
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: Events.reload_decks),
                                            object: nil)
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
                RealmHelper.set(deck: deck, active: !deck.isActive)
                
                Settings.activeDeck = nil
                self.refreshDecks()
            }
        }
    }

    fileprivate func _deleteDeck(_ currentDeck: Deck) {
        decksTable.deselectAll(self)
        self.currentDeck = nil

        if let deck = RealmHelper.getDeck(with: currentDeck.deckId) {
			RealmHelper.delete(deck: deck)
		} else {
			logger.error("Can not get deck")
		}

        refreshDecks()
    }

    private func loadClassesPopUp() {
        let popupMenu = NSMenu()
        var popupMenuItem = NSMenuItem(title: NSLocalizedString("All classes", comment: ""),
                                       action: #selector(filterClassesAction(_:)),
                                       keyEquivalent: "")
        popupMenuItem.representedObject = CardClass.neutral
        popupMenu.addItem(popupMenuItem)
        for playerClass in Cards.classes {
            popupMenuItem = NSMenuItem(title: NSLocalizedString(playerClass.rawValue,
                                                                comment: ""),
                                       action: #selector(filterClassesAction(_:)),
                                       keyEquivalent: "")
            popupMenuItem.representedObject = playerClass
            popupMenu.addItem(popupMenuItem)
        }
        classesPopup.menu = popupMenu

        popupMenu.addItem(.separator())
        popupMenuItem = NSMenuItem(title: NSLocalizedString("Archived", comment: ""),
                                   action: #selector(filterClassesAction(_:)),
                                   keyEquivalent: "")
        popupMenuItem.state = .off
        popupMenu.addItem(popupMenuItem)
    }

    private func loadSortPopUp() {
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
        
        popupMenu.item(withTitle: NSLocalizedString(sortCriteria, comment: ""))?.state = .on
        popupMenu.item(withTitle: NSLocalizedString(sortOrder, comment: ""))?.state = .on
        
        let firstItemMenu = NSMenuItem(title: NSLocalizedString(sortCriteria, comment: ""),
                                       action: #selector(DeckManager.changeSort(_:)),
                                       keyEquivalent: "")
        firstItemMenu.representedObject = sortCriteria
        popupMenu.insertItem(firstItemMenu, at: 0)
        
        sortPopUp.menu = popupMenu
    }
    
    private func loadModesPopup() {
        let popupMenu = NSMenu()
        
        for mode in DeckType.allCases {
            let popupMenuItem = NSMenuItem(title: NSLocalizedString("DeckType_\(mode)", comment: ""), action: #selector(DeckManager.filterDeckTypeAction(_:)), keyEquivalent: "")
            popupMenuItem.representedObject = mode
            popupMenu.addItem(popupMenuItem)
        }
        deckTypePopup.menu = popupMenu
    }
    
    @IBAction func changeSort(_ sender: NSMenuItem) {
        // Unset the previously selected one, select the new one
        var previous: String = ""

        if let idx = sender.menu?.index(of: sender), idx <= criterias.count {
            previous = sortCriteria
            if let criteria = sender.representedObject as? String {
                sortCriteria = criteria
                Settings.deckSortCriteria = sortCriteria
                
                let firstMenuItem = sortPopUp.menu?.item(at: 0)
                firstMenuItem?.representedObject = sender.representedObject
                firstMenuItem?.title = sender.title
            }
        } else {
            // Ascending/Descending
            previous = sortOrder
            if let order = sender.representedObject as? String {
                sortOrder = order
                Settings.deckSortOrder = sortOrder
            }
        }
        
        let prevSelected = sortPopUp.menu?.item(withTitle: NSLocalizedString(previous, comment: ""))
        
        if sender.state != .on {
            self.refreshDecks()
        }
        
        prevSelected?.state = .off
        sender.state = .on
    }

    @IBAction func exportHSString(_ sender: Any?) {
        guard let deck = currentDeck else { return }
        guard let string = DeckSerializer.serialize(deck: deck) else {
            NSAlert.show(style: .critical,
                         message: NSLocalizedString("Can't create deck string.", comment: ""),
                         window: self.window!)
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([string as NSString])
        NSAlert.show(style: .informational,
                     message: NSLocalizedString("Deck string has been copied in your clipboard.", comment: ""),
                     window: self.window!)
    }
}

// MARK: - NSTableViewDelegate
extension DeckManager: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == decksTable {
            if let cell = decksTable?.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeckCellView"), owner: self)
                as? DeckCellView {

                let deck = sortedFilteredDecks()[row]
                cell.deck = deck
                cell.label.stringValue = deck.name
                cell.image.image = NSImage(named: deck.playerClass.rawValue.lowercased())
                cell.arenaImage.image = deck.isArena && deck.arenaFinished() ?
                    NSImage(named: "silenced") : nil
                cell.wildImage.image = !deck.standardViable() && !deck.isArena ? NSImage(named: "Mode_Wild") : nil
                cell.selected = tableView.selectedRow == row
                cell.color = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
                cell.row = row
                if Settings.activeDeck == deck.deckId {
                    cell.useButton.title = "ACTIVE"
                    cell.useButton.isEnabled = false
                } else {
                    cell.useButton.title = "USE"
                    cell.useButton.isEnabled = true
                }
                
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
        
        let selection = decksTable?.selectedRowIndexes
        for i in 0 ..< decks {
            let row = decksTable?.view(atColumn: 0, row: i, makeIfNecessary: false) as? DeckCellView
            let sel = selection?.contains(i) ?? false
            if row?.selected != sel {
                row?.selected = sel
                row?.needsDisplay = true
            }
            logger.debug("Row selection: \(i): \(decksTable?.selectedRow ?? -1) \(row?.selected ?? false)")
            
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
        
        DispatchQueue.main.async { [weak self] in
            self?.currentDeck = nil
            self?.decksTable.deselectAll(self)
            self?.decks = []
            if let realmdecks = RealmHelper.getDecks() {
                self?.decks = Array(realmdecks)
            }
            
            self?.decksTable.reloadData()
            self?.deckListTable.reloadData()
        }
    }
}
