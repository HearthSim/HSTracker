//
//  DeckManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 23/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class DeckManager : NSWindowController, NSTableViewDataSource, NSTableViewDelegate, DeckCellViewDelegate, NewDeckDelegate {

    @IBOutlet weak var decksTable: NSTableView!
    @IBOutlet weak var deckListTable: NSTableView!
    @IBOutlet weak var curveView: CurveView!
    @IBOutlet weak var statsLabel: NSTextField!
    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    @IBOutlet weak var druidButton: NSButton!
    @IBOutlet weak var hunterButton: NSButton!
    @IBOutlet weak var mageButton: NSButton!
    @IBOutlet weak var paladinButton: NSButton!
    @IBOutlet weak var priestButton: NSButton!
    @IBOutlet weak var rogueButton: NSButton!
    @IBOutlet weak var shamanButton: NSButton!
    @IBOutlet weak var warlockButton: NSButton!
    @IBOutlet weak var warriorButton: NSButton!

    var editDeck: EditDeck?
    var newDeck: NewDeck?
    var hearthstatsLogin: HearthstatsLogin?

    var decks = [Deck]()
    var classes = [String]()
    var currentClass: String?
    var currentDeck: Deck?
    var currentCell: DeckCellView?

    convenience init() {
        self.init(windowNibName: "DeckManager")
    }

    override init(window: NSWindow!) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        let nib = NSNib(nibNamed: "DeckCellView", bundle: nil)
        decksTable.registerNib(nib, forIdentifier: "DeckCellView")

        decksTable.backgroundColor = NSColor.clearColor()
        decksTable.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]

        decksTable.tableColumns.first?.width = NSWidth(decksTable.bounds)
        decksTable.tableColumns.first?.resizingMask = NSTableColumnResizingOptions.AutoresizingMask

        decksTable.target = self
        decksTable.action = #selector(DeckManager.decksTableClick(_:))

        decks = Decks.decks().filter({$0.isActive})
        decksTable.reloadData()

        deckListTable.tableColumns.first?.width = NSWidth(deckListTable.bounds)
        deckListTable.tableColumns.first?.resizingMask = NSTableColumnResizingOptions.AutoresizingMask
    }

    func filteredDecks() -> [Deck] {
        if let currentClass = currentClass {
            return decks.filter({ $0.playerClass == currentClass }).sort { $0.name < $1.name }
        }
        else {
            return decks.sort { $0.name < $1.name }
        }
    }

    @IBAction func filterClassesAction(sender: NSButton) {
        let buttons = [druidButton, hunterButton, mageButton,
            paladinButton, priestButton, rogueButton,
            shamanButton, warlockButton, warriorButton
        ]
        for button in buttons {
            if sender != button {
                button.state = NSOffState
            }
        }

        let oldCurrentClass = currentClass
        if sender == druidButton {
            currentClass = "druid"
        }
        else if sender == hunterButton {
            currentClass = "hunter"
        }
        else if sender == mageButton {
            currentClass = "mage"
        }
        else if sender == paladinButton {
            currentClass = "paladin"
        }
        else if sender == priestButton {
            currentClass = "priest"
        }
        else if sender == rogueButton {
            currentClass = "rogue"
        }
        else if sender == shamanButton {
            currentClass = "shaman"
        }
        else if sender == warlockButton {
            currentClass = "warlock"
        }
        else if sender == warriorButton {
            currentClass = "warrior"
        }
        else {
            currentClass = nil
        }

        if currentClass == oldCurrentClass {
            currentClass = nil
        }

        decksTable.reloadData()
    }

    // MARK: - NSTableViewDelegate / NSTableViewDataSource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if tableView == decksTable {
            return filteredDecks().count
        }
        else if let currentDeck = currentDeck {
            return currentDeck.sortedCards.count
        }

        return 0;
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == decksTable {
            let cell = decksTable.makeViewWithIdentifier("DeckCellView", owner: self) as! DeckCellView
            let deck = filteredDecks()[row]
            cell.moreButton.hidden = false
            cell.deck = deck
            cell.label.stringValue = deck.name!
            cell.image.image = ImageCache.classImage(deck.playerClass)
            cell.color = ClassColor.color(deck.playerClass)
            cell.setDelegate(self)
            return cell
        }
        else {
            let cell = CardCellView()
            cell.playerType = .DeckManager
            cell.card = currentDeck!.sortedCards[row]
            return cell
        }
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == self.decksTable {
            return 55
        }
        else if tableView == self.deckListTable {
            return CGFloat(kRowHeight)
        }
        return 20
    }

    func decksTableClick(sender: AnyObject?) {
        guard sender?.clickedRow >= 0 else {
            return
        }
        let clickedRow = sender!.clickedRow!
        currentDeck = filteredDecks()[clickedRow]
        deckListTable.reloadData()
        curveView.deck = currentDeck
        statsLabel.stringValue = currentDeck!.displayStats()
        curveView.reload()
    }

    // MARK: - Toolbar actions
    override func validateToolbarItem(item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier {
        case "add":
            return true
        case "donate":
            return true
        case "hearthstats":
            return !HearthstatsAPI.isLogged()
        default:
            return false
        }
    }

    @IBAction func addDeck(sender: AnyObject) {
        newDeck = NewDeck()
        if let newDeck = newDeck {
            newDeck.setDelegate(self)
            self.window!.beginSheet(newDeck.window!, completionHandler: nil)
        }
    }
    
    @IBAction func hearthstatsLogin(sender: AnyObject) {
        hearthstatsLogin = HearthstatsLogin(windowNibName: "HearthstatsLogin")
        if let hearthstatsLogin = hearthstatsLogin {
            self.window!.beginSheet(hearthstatsLogin.window!, completionHandler: nil)
        }
    }
    
    @IBAction func donate(sender: AnyObject) {
        let url = NSURL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=bmichotte%40gmail%2ecom&lc=US&item_name=HSTracker&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_SM%2egif%3aNonHosted")
        NSWorkspace.sharedWorkspace().openURL(url!)
    }
    
    // MARK: - DeckCellViewDelegate
    func moreClicked(cell: DeckCellView) {
        currentCell = cell

        let menu = NSMenu()
        var menuItem = NSMenuItem(title: NSLocalizedString("Use deck", comment: ""),
            action: #selector(DeckManager.useDeck(_:)),
            keyEquivalent: "")
        menu.addItem(menuItem)
        menuItem = NSMenuItem(title: NSLocalizedString("Edit deck", comment: ""),
            action: #selector(DeckManager.editDeck(_:)),
            keyEquivalent: "")
        menu.addItem(menuItem)
        menuItem = NSMenuItem(title: NSLocalizedString("Rename deck", comment: ""),
            action: #selector(DeckManager.renameDeck(_:)),
            keyEquivalent: "")
        menu.addItem(menuItem)
        menu.addItem(NSMenuItem.separatorItem())
        menuItem = NSMenuItem(title: NSLocalizedString("Delete deck", comment: ""),
            action: #selector(DeckManager.deleteDeck(_:)),
            keyEquivalent: "")
        menu.addItem(menuItem)

        NSMenu.popUpContextMenu(menu, withEvent: NSApp.currentEvent!, forView: cell.moreButton)
    }

    func renameDeck(sender: AnyObject?) {
        if let cell = currentCell, deck = cell.deck {
            let deckNameInput = NSTextField(frame: NSMakeRect(0, 0, 220, 24))
            deckNameInput.stringValue = deck.name!
            let alert = NSAlert()
            alert.alertStyle = .InformationalAlertStyle
            alert.messageText = NSLocalizedString("Deck name", comment: "")
            alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
            alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
            alert.accessoryView = deckNameInput
            alert.beginSheetModalForWindow(self.window!,
                                           completionHandler: { (returnCode) in
                                            if returnCode == NSAlertFirstButtonReturn {
                                                deck.name = deckNameInput.stringValue
                                                deck.save()
                                                
                                                if HearthstatsAPI.isLogged() {
                                                    if Settings.instance.hearthstatsAutoSynchronize {
                                                        do {
                                                            try HearthstatsAPI.updateDeck(deck) {_ in}
                                                        }
                                                        catch {}
                                                    }
                                                    else {
                                                        // TODO Alert synchro
                                                    }
                                                }
                                                
                                                self.refreshDecks()
                                            }
            })
        }
    }

    func editDeck(sender: AnyObject?) {
        if let cell = currentCell, deck = cell.deck {
            editDeck = EditDeck()
            if let editDeck = editDeck {
                editDeck.setDeck(deck)
                editDeck.setPlayerClass(deck.playerClass)
                editDeck.setDelegate(self)
                editDeck.showWindow(self)
            }
        }
    }

    func useDeck(sender: AnyObject?) {
        if let cell = currentCell, deck = cell.deck {
            Settings.instance.activeDeck = deck.deckId
            Game.instance.setActiveDeck(deck)
            Game.instance.updatePlayerTracker()
        }
    }

    func deleteDeck(sender: AnyObject?) {
        if let cell = currentCell, deck = cell.deck {
            let alert = NSAlert()
            alert.alertStyle = .InformationalAlertStyle
            alert.messageText = NSLocalizedString("Are you sure you want to delete this deck ?", comment: "")
            alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
            alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
            alert.beginSheetModalForWindow(self.window!,
                                           completionHandler: { (returnCode) in
                                            if returnCode == NSAlertFirstButtonReturn {
                                                self._deleteDeck(deck)
                                            }
            })
        }
    }
    
    private func _deleteDeck(deck: Deck) {
        Log.verbose?.message("in deleete \(deck) -> \(HearthstatsAPI.isLogged()) -> \(Settings.instance.hearthstatsAutoSynchronize)")
        if let _ = deck.hearthstatsId where HearthstatsAPI.isLogged() {
            if Settings.instance.hearthstatsAutoSynchronize {
                do {
                    try HearthstatsAPI.deleteDeck(deck)
                    Decks.remove(deck)
                    refreshDecks()
                }
                catch {
                    print("error delete hearthstats")
                }
            } else {
                let alert = NSAlert()
                alert.alertStyle = .InformationalAlertStyle
                alert.messageText = NSLocalizedString("Do you want to delete the deck on Hearthstats ?", comment: "")
                alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
                alert.beginSheetModalForWindow(self.window!,
                                               completionHandler: { (returnCode) in
                                                if returnCode == NSAlertFirstButtonReturn {
                                                    do {
                                                        try HearthstatsAPI.deleteDeck(deck)
                                                        Decks.remove(deck)
                                                        self.refreshDecks()
                                                    }
                                                    catch {
                                                        // TODO alert
                                                        print("error delete hearthstats")
                                                    }
                                                }
                })
            }
        }
        else {
            Decks.remove(deck)
            refreshDecks()
        }
    }

    // MARK: - NewDeckDelegate
    func addNewDeck(deck: Deck) {
        NSNotificationCenter.defaultCenter().postNotificationName("reload_decks", object: nil)
        refreshDecks()
    }

    func openDeckBuilder(playerClass: String, _ arenaDeck: Bool) {
        editDeck = EditDeck()
        if let editDeck = editDeck {
            let deck = Deck(playerClass: playerClass)
            deck.isArena = arenaDeck
            editDeck.setDeck(deck)
            editDeck.setPlayerClass(playerClass)
            editDeck.setDelegate(self)
            editDeck.showWindow(self)
        }
    }

    func refreshDecks() {
        decks = Decks.decks().filter({$0.isActive})
        classes = [String]()
        for deck in decks {
            if !classes.contains(deck.playerClass) {
                classes.append(deck.playerClass)
            }
        }
        decksTable.reloadData()
    }
}