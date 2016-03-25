//
//  EditDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import JNWCollectionView

class EditDeck: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDataSource, NSComboBoxDelegate, JNWCollectionViewDataSource, JNWCollectionViewDelegate, SaveDeckDelegate {

    @IBOutlet weak var countLabel: NSTextField!
    @IBOutlet weak var collectionView: JNWCollectionView!
    @IBOutlet weak var classChooser: NSSegmentedControl!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var setChooser: NSComboBox!
    @IBOutlet weak var curveView: CurveView!

    var isSaved: Bool = false
    var delegate: NewDeckDelegate?
    var currentDeck: Deck?
    var currentPlayerClass: String?
    var currentSet: String?
    var selectedClass: String?
    var currentClassCards: [Card]?
    
    var saveDeck: SaveDeck?

    convenience init() {
        self.init(windowNibName: "EditDeck")
    }

    override init(window: NSWindow!) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setPlayerClass(playerClass: String) {
        currentPlayerClass = playerClass
        selectedClass = currentPlayerClass
    }

    func setDeck(deck: Deck) {
        currentDeck = deck
        isSaved = true
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        let gridLayout = JNWCollectionViewGridLayout()
        gridLayout.itemSize = NSMakeSize(177, 259)
        collectionView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        collectionView.collectionViewLayout = gridLayout
        collectionView.registerClass(CardCell.self, forCellWithReuseIdentifier: "card_cell")

        classChooser.segmentCount = 2
        classChooser.setLabel(NSLocalizedString(currentPlayerClass!, comment: ""), forSegment: 0)
        classChooser.setLabel(NSLocalizedString("Neutral", comment: ""), forSegment: 1)
        classChooser.setSelected(true, forSegment: 0)

        tableView.reloadData()
        reloadCards()

        curveView?.deck = currentDeck
        curveView?.reload()

        countCards()

        if let cell = searchField.cell as? NSSearchFieldCell {
            cell.cancelButtonCell!.target = self
            cell.cancelButtonCell!.action = #selector(EditDeck.cancelSearch(_:))
        }

        NSEvent.addLocalMonitorForEventsMatchingMask(.KeyDownMask) { (e) -> NSEvent? in
            let isCmd = (e.modifierFlags.rawValue & NSEventModifierFlags.CommandKeyMask.rawValue == NSEventModifierFlags.CommandKeyMask.rawValue)
            // let isShift = (e.modifierFlags.rawValue & NSEventModifierFlags.ShiftKeyMask.rawValue == NSEventModifierFlags.ShiftKeyMask.rawValue)

            guard isCmd else { return e }

            switch e.keyCode {
            case 6:
                self.window!.performClose(nil)
                return nil

            case 3: // cmd-f
                self.searchField.becomeFirstResponder()
                return nil

            case 1: // cmd-s
                self.save(nil)
                return nil

            case 12: // cmd-a
                if let selected = self.collectionView.indexPathsForSelectedItems() as? [NSIndexPath],
                    let cell: CardCell = self.collectionView.cellForItemAtIndexPath(selected.first) as? CardCell,
                    let card = cell.card {
                        self.addCardToDeck(card)
                }

            default:
                DDLogVerbose("\(e.keyCode)")
                break
            }
            return e
        }
    }

    func setDelegate(delegate: NewDeckDelegate) {
        self.delegate = delegate
    }

    private func reloadCards() {
        currentClassCards = Cards.byClass(selectedClass, set: currentSet).sortCardList()
        collectionView.reloadData()
    }

    func countCards() {
        if let count = currentDeck?.countCards() {
            countLabel.stringValue = "\(count) / 30"
        }
    }

    // MARK: - NSWindowDelegate
    func windowShouldClose(sender: AnyObject) -> Bool {
        if isSaved {
            delegate?.refreshDecks()
            return true
        }

        let alert = NSAlert()
        alert.alertStyle = .InformationalAlertStyle
        alert.messageText = NSLocalizedString("Are you sure you want to close this deck ? Your changes will not be saved.", comment: "")
        alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
        if alert.runModalSheetForWindow(self.window!) == NSAlertFirstButtonReturn {
            Decks.resetDeck(currentDeck!)
            delegate?.refreshDecks()
            return true
        }
        return false
    }

    // MARK: - NSSegmentedControl
    @IBAction func changeClassTab(sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            selectedClass = currentPlayerClass
        } else {
            selectedClass = "neutral"
        }
        reloadCards()
    }

    // MARK: - NSTableViewDataSource/Delegate
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return currentDeck!.sortedCards.count
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = CardCellView()
        cell.playerType = .DeckManager
        cell.card = currentDeck!.sortedCards[row]
        return cell
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(kRowHeight)
    }

    @IBAction func clickCard(sender: NSTableView) {
        let card = currentDeck!.sortedCards[sender.clickedRow]
        currentDeck!.removeCard(card)

        isSaved = false

        tableView.reloadData()
        collectionView.reloadData()
        curveView.reload()
    }

    // MARK: - NSComboBoxDataSource/Delegate
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return Database.validCardSet.count + 1
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return (["ALL"] + Database.validCardSet)[index]
    }

    func comboBoxSelectionDidChange(notification: NSNotification) {
        if setChooser.indexOfSelectedItem == 0 {
            currentSet = nil
        } else {
            currentSet = Database.validCardSet[setChooser.indexOfSelectedItem - 1].lowercaseString
        }
        reloadCards()
    }

    func addCardToDeck(card: Card) {
        let deckCard = currentDeck!.sortedCards.filter({ $0.cardId == card.cardId }).first

        if deckCard == nil || (deckCard!.count == 1 && card.rarity != .Legendary) {
            currentDeck?.addCard(card)
            curveView.reload()
            tableView.reloadData()
            collectionView.reloadData()
            countCards()
            isSaved = false
        }
    }

    // MARK: - JNWCollectionViewDataSource/Delegate
    func collectionView(collectionView: JNWCollectionView!,
        cellForItemAtIndexPath indexPath: NSIndexPath!) -> JNWCollectionViewCell! {

            let cell: CardCell = collectionView.dequeueReusableCellWithIdentifier("card_cell") as! CardCell
            if let currentClassCards = currentClassCards {
                let card = currentClassCards[indexPath.jnw_item]
                cell.setCard(card)
                var count: Int = 0
                if let deckCard = currentDeck!.sortedCards.firstWhere({ $0.cardId == card.cardId }) {
                    count = deckCard.count
                }
                cell.setCount(count)

                return cell
            }
            return nil
    }

    func collectionView(collectionView: JNWCollectionView!, numberOfItemsInSection section: Int) -> UInt {
        if let currentClassCards = currentClassCards {
            return UInt(currentClassCards.count)
        }
        return 0
    }

    func collectionView(collectionView: JNWCollectionView!, mouseUpInItemAtIndexPath indexPath: NSIndexPath!) {
        if currentDeck!.countCards() == 30 {
            return
        }
        let cell: CardCell = collectionView.cellForItemAtIndexPath(indexPath) as! CardCell
        if let card = cell.card {
            addCardToDeck(card)
        }
    }

    // MARK: - Toolbar actions
    @IBAction func save(sender: AnyObject?) {
        saveDeck = SaveDeck(windowNibName: "SaveDeck")
        saveDeck?.setDelegate(self)
        saveDeck?.deck = currentDeck
        self.window!.beginSheet(saveDeck!.window!, completionHandler: nil)
    }

    @IBAction func cancel(sender: AnyObject?) {
        self.window?.performClose(self)
    }

    @IBAction func delete(sender: AnyObject?) {
        var alert = NSAlert()
        alert.alertStyle = .InformationalAlertStyle
        alert.messageText = NSLocalizedString("Are you sure you want to delete this deck ?", comment: "")
        alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
        if alert.runModalSheetForWindow(self.window!) == NSAlertFirstButtonReturn {
            if let _ = currentDeck!.hearthstatsId where HearthstatsAPI.isLogged() {
                if Settings.instance.hearthstatsAutoSynchronize {
                    do {
                        try HearthstatsAPI.deleteDeck(currentDeck!)
                    }
                    catch {}
                } else {
                    alert = NSAlert()
                    alert.alertStyle = .InformationalAlertStyle
                    alert.messageText = NSLocalizedString("Do you want to delete the deck on Hearthstats ?", comment: "")
                    alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                    alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
                    if alert.runModalSheetForWindow(self.window!) == NSAlertFirstButtonReturn {
                        do {
                            try HearthstatsAPI.deleteDeck(currentDeck!)
                        }
                        catch {
                            // TODO alert
                            print("error")
                        }
                    }
                }
            }
            Decks.remove(currentDeck!)
            isSaved = true
            self.window?.performClose(self)
        }
    }

    // MARK: - Search
    @IBAction func search(sender: NSSearchField) {
        let str = sender.stringValue

        if !str.isEmpty {
            classChooser.enabled = false

            currentClassCards = Cards.search(currentPlayerClass, set: currentSet, term: str).sortCardList()
            collectionView.reloadData()
        }
        else {
            cancelSearch(sender)
        }
    }

    func cancelSearch(sender: AnyObject) {
        classChooser.enabled = true
        searchField.stringValue = ""
        searchField.resignFirstResponder()
        reloadCards()
    }
    
    // MARK: - SaveDeckDelegate
    func deckSaveSaved() {
        isSaved = true
        if let saveDeck = saveDeck {
            self.window?.endSheet(saveDeck.window!)
        }
        self.window?.performClose(self)
    }
    
    func deckSaveCanceled() {
        if let saveDeck = saveDeck {
            self.window?.endSheet(saveDeck.window!)
        }
    }
}