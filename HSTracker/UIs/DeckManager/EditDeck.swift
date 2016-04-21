//
//  EditDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class EditDeck: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDataSource, NSComboBoxDelegate, JNWCollectionViewDataSource, JNWCollectionViewDelegate, SaveDeckDelegate, NSTextFieldDelegate {

    @IBOutlet weak var countLabel: NSTextField!
    @IBOutlet weak var cardsCollectionView: JNWCollectionView!
    @IBOutlet weak var classChooser: NSSegmentedControl!
    @IBOutlet weak var deckCardsView: NSTableView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var curveView: CurveView!
    @IBOutlet weak var standardOnlyCards: NSButton!
    @IBOutlet weak var sets: NSPopUpButton!
    
    @IBOutlet weak var manaGem0: ManaGemButton!
    @IBOutlet weak var manaGem1: ManaGemButton!
    @IBOutlet weak var manaGem2: ManaGemButton!
    @IBOutlet weak var manaGem3: ManaGemButton!
    @IBOutlet weak var manaGem4: ManaGemButton!
    @IBOutlet weak var manaGem5: ManaGemButton!
    @IBOutlet weak var manaGem6: ManaGemButton!
    @IBOutlet weak var manaGem7: ManaGemButton!
    
    @IBOutlet weak var damage: NSTextField!
    @IBOutlet weak var health: NSTextField!
    
    @IBOutlet weak var cardType: NSPopUpButton!
    @IBOutlet weak var rarity: NSPopUpButton!
    @IBOutlet weak var races: NSPopUpButton!
    
    @IBOutlet weak var zoom: NSSlider!
    @IBOutlet weak var presentationView: NSSegmentedControl!
    
    var isSaved: Bool = false
    var delegate: NewDeckDelegate?
    var currentDeck: Deck?
    var currentPlayerClass: String?
    var currentSet = [String]()
    var selectedClass: String?
    var currentClassCards = [Card]()
    var currentCardCost = -1
    var currentSearchTerm = ""
    var currentRarity: Rarity?
    var standardOnly = false
    var currentDamage = -1
    var currentHealth = -1
    var currentRace = ""
    var currentCardType = ""
    
    var saveDeck: SaveDeck?
    
    let baseCardWidth: CGFloat = 177
    let baseCardHeight: CGFloat = 259

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

        let settings = Settings.instance
        
        let gridLayout = JNWCollectionViewGridLayout()
        cardsCollectionView.collectionViewLayout = gridLayout
        cardsCollectionView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        cardsCollectionView.registerClass(CardCell.self, forCellWithReuseIdentifier: "card_cell")
        changeLayout()
        presentationView.selectedSegment = settings.deckManagerPreferCards ? 0 : 1
        reloadCards()

        classChooser.segmentCount = 2
        classChooser.setLabel(NSLocalizedString(currentPlayerClass!, comment: ""), forSegment: 0)
        classChooser.setLabel(NSLocalizedString("neutral", comment: ""), forSegment: 1)
        classChooser.setSelected(true, forSegment: 0)

        deckCardsView.reloadData()

        curveView?.deck = currentDeck
        curveView?.reload()

        countCards()
        
        loadSets()
        loadCardTypes()
        loadRarities()
        loadRaces()
        
        zoom.doubleValue = settings.deckManagerZoom
        
        if let cell = searchField.cell as? NSSearchFieldCell {
            cell.cancelButtonCell!.target = self
            cell.cancelButtonCell!.action = #selector(EditDeck.cancelSearch(_:))
        }

        NSEvent.addLocalMonitorForEventsMatchingMask(.KeyDownMask) { (e) -> NSEvent? in
            let isCmd = e.modifierFlags.contains(.CommandKeyMask)
            // let isShift = e.modifierFlags.contains(.ShiftKeyMask)

            guard isCmd else { return e }

            switch e.keyCode {
            case 6:
                self.window!.performClose(nil)
                return nil

            case 3: // cmd-f
                self.searchField.selectText(self)
                self.searchField.becomeFirstResponder()
                return nil

            case 1: // cmd-s
                self.save(nil)
                return nil

            case 12: // cmd-a
                if let selected = self.cardsCollectionView.indexPathsForSelectedItems() as? [NSIndexPath],
                    let cell: CardCell = self.cardsCollectionView.cellForItemAtIndexPath(selected.first) as? CardCell,
                    let card = cell.card {
                        self.addCardToDeck(card)
                }

            default:
                Log.verbose?.message("unsupported keycode \(e.keyCode)")
                break
            }
            return e
        }
    }

    func setDelegate(delegate: NewDeckDelegate) {
        self.delegate = delegate
    }

    private func reloadCards() {
        currentClassCards = Cards.search(className: currentSearchTerm == "" ? selectedClass : currentPlayerClass,
                                         sets: currentSet,
                                         term: currentSearchTerm,
                                         cost: currentCardCost,
                                         rarity: currentRarity,
                                         standardOnly: standardOnly,
                                         damage: currentDamage,
                                         health: currentHealth,
                                         type: currentCardType,
                                         race: currentRace)
        cardsCollectionView.reloadData()
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
        if alert.runModal() == NSAlertFirstButtonReturn {
            Decks.instance.resetDecks()
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
        guard sender.clickedRow >= 0 else { return }
        let card = currentDeck!.sortedCards[sender.clickedRow]
        currentDeck!.removeCard(card)

        isSaved = false

        deckCardsView.reloadData()
        cardsCollectionView.reloadData()
        curveView.reload()
    }
    
    func addCardToDeck(card: Card) {
        let deckCard = currentDeck!.sortedCards.filter({ $0.id == card.id }).first
        
        if deckCard == nil || currentDeck!.isArena || (deckCard!.count == 1 && card.rarity != .Legendary) {
            currentDeck?.addCard(card)
            curveView.reload()
            deckCardsView.reloadData()
            cardsCollectionView.reloadData()
            countCards()
            isSaved = false
        }
    }
    
    // MARK: - Standard/Wild
    @IBAction func standardWildChange(sender: NSButton) {
        standardOnly = sender.state == NSOnState
        reloadCards()
    }
    
    // MARK: - Health/Damage - NSTextFieldDelegate
    override func controlTextDidChange(notification: NSNotification) {
        if let editor = notification.object as? NSTextField {
            if editor == health {
                if let value = Int(editor.stringValue) {
                    currentHealth = value
                }
                else {
                    currentHealth = -1
                }
            }
            else if editor == damage {
                if let value = Int(editor.stringValue) {
                    currentDamage = value
                }
                else {
                    currentDamage = -1
                }
            }
            
            reloadCards()
        }
    }
    
    // MARK: - Gems
    @IBAction func manaGemClicked(sender: ManaGemButton) {
        let gems = [manaGem0, manaGem1, manaGem2, manaGem3, manaGem4, manaGem5, manaGem6, manaGem7]
        
        if sender.selected {
            sender.selected = false
            currentCardCost = -1
        }
        else {
            currentCardCost = sender.tag
            for gem in gems {
                gem.selected = sender == gem
            }
        }
        
        reloadCards()
    }
    
    // MARK: - Sets
    private func loadSets() {
        let popupMenu = NSMenu()
        for set in Database.deckManagerValidCardSets {
            let popupMenuItem = NSMenuItem(title: NSLocalizedString(set, comment: ""),
                                           action: #selector(EditDeck.changeSet(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = set
            popupMenuItem.image = ImageCache.asset("Set_\(set)")
            popupMenu.addItem(popupMenuItem)
        }
        sets.menu = popupMenu
    }
    
    @IBAction func changeSet(sender: NSMenuItem) {
        switch sender.representedObject as! String {
        case "ALL": currentSet = []
        case "EXPERT1": currentSet = ["core", "expert1", "promo"]
        default: currentSet = [(sender.representedObject as! String).lowercaseString]
        }
        
        reloadCards()
    }
    
    // MARK: - Card Types
    private func loadCardTypes() {
        let popupMenu = NSMenu()
        for cardType in Database.deckManagerCardTypes {
            let popupMenuItem = NSMenuItem(title: NSLocalizedString(cardType, comment: ""),
                                           action: #selector(EditDeck.changeCardType(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = cardType
            popupMenu.addItem(popupMenuItem)
        }
        cardType.menu = popupMenu
    }
    
    @IBAction func changeCardType(sender: NSMenuItem) {
        switch sender.representedObject as! String {
        case "all_types": currentCardType = ""
        default: currentCardType = sender.representedObject as! String
        }
        
        reloadCards()
    }
    
    // MARK: - Races
    private func loadRaces() {
        let popupMenu = NSMenu()
        let popupMenuItem = NSMenuItem(title: NSLocalizedString("all_races", comment: ""),
                                       action: #selector(EditDeck.changeRarity(_:)),
                                       keyEquivalent: "")
        popupMenuItem.representedObject = "all"
        popupMenu.addItem(popupMenuItem)
        
        for race in Database.deckManagerRaces {
            let popupMenuItem = NSMenuItem(title: NSLocalizedString(race, comment: ""),
                                           action: #selector(EditDeck.changeRace(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = race
            popupMenu.addItem(popupMenuItem)
        }
        races.menu = popupMenu
    }
    
    @IBAction func changeRace(sender: NSMenuItem) {
        switch sender.representedObject as! String {
        case "all": currentRace = ""
        default: currentRace = sender.representedObject as! String
        }
        
        reloadCards()
    }
    
    // MARK: - Rarity
    private func loadRarities() {
        let popupMenu = NSMenu()
        let popupMenuItem = NSMenuItem(title: NSLocalizedString("all_rarities", comment: ""),
                                       action: #selector(EditDeck.changeRarity(_:)),
                                       keyEquivalent: "")
        popupMenuItem.representedObject = "all"
        popupMenu.addItem(popupMenuItem)
        
        for rarity in Rarity.allValues() {
            let popupMenuItem = NSMenuItem(title: "",
                                           action: #selector(EditDeck.changeRarity(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = rarity.rawValue
            let gemName = rarity == .Free ? "gem" : "gem_\(rarity.rawValue)"
            popupMenuItem.image = ImageCache.asset(gemName)
            popupMenu.addItem(popupMenuItem)
        }
        rarity.menu = popupMenu
    }
    
    @IBAction func changeRarity(sender: NSMenuItem) {
        switch sender.representedObject as! String {
        case "all_rarities": currentRarity = .None
        default: currentRarity = Rarity(rawValue: sender.representedObject as! String)
        }
        
        reloadCards()
    }

    // MARK: - JNWCollectionViewDataSource/Delegate
    func changeLayout() {
        let settings = Settings.instance
        
        zoom.enabled = settings.deckManagerPreferCards
        
        let size: NSSize
        if settings.deckManagerPreferCards {
            size = NSMakeSize(baseCardWidth / 100 * CGFloat(settings.deckManagerZoom),
                              baseCardHeight / 100 * CGFloat(settings.deckManagerZoom))
        }
        else {
            size = NSMakeSize(CGFloat(kFrameWidth), CGFloat(kRowHeight))
        }
        
        (cardsCollectionView.collectionViewLayout as! JNWCollectionViewGridLayout).itemSize = size
    }
    
    func collectionView(collectionView: JNWCollectionView!,
        cellForItemAtIndexPath indexPath: NSIndexPath!) -> JNWCollectionViewCell! {
        
        let card = currentClassCards[indexPath.jnw_item]
        let settings = Settings.instance

        let cell: CardCell = collectionView.dequeueReusableCellWithIdentifier("card_cell") as! CardCell
        cell.showCard = settings.deckManagerPreferCards
        cell.setCard(card)
        var count: Int = 0
        if let deckCard = currentDeck!.sortedCards.firstWhere({ $0.id == card.id }) {
            count = deckCard.count
        }
        cell.isArena = currentDeck!.isArena
        cell.setCount(count)
        return cell
    }

    func collectionView(collectionView: JNWCollectionView!, numberOfItemsInSection section: Int) -> UInt {
        return UInt(currentClassCards.count)
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
        alert.beginSheetModalForWindow(self.window!) { (returnCode) in
            if returnCode == NSAlertFirstButtonReturn {
                if let _ = self.currentDeck!.hearthstatsId where HearthstatsAPI.isLogged() {
                    if Settings.instance.hearthstatsAutoSynchronize {
                        do {
                            try HearthstatsAPI.deleteDeck(self.currentDeck!)
                        }
                        catch {}
                    } else {
                        alert = NSAlert()
                        alert.alertStyle = .InformationalAlertStyle
                        alert.messageText = NSLocalizedString("Do you want to delete the deck on Hearthstats ?", comment: "")
                        alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                        alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
                        alert.beginSheetModalForWindow(self.window!,
                                                       completionHandler: { (response) in
                                                        if response == NSAlertFirstButtonReturn {
                                                            do {
                                                                try HearthstatsAPI.deleteDeck(self.currentDeck!)
                                                            }
                                                            catch {
                                                                // TODO alert
                                                                print("error")
                                                            }
                                                        }
                        })
                    }
                }
                Decks.instance.remove(self.currentDeck!)
                self.isSaved = true
                self.window?.performClose(self)
            }
        }
    }

    // MARK: - Search
    @IBAction func search(sender: NSSearchField) {
        currentSearchTerm = sender.stringValue

        if !currentSearchTerm.isEmpty {
            classChooser.enabled = false
            reloadCards()
        }
        else {
            cancelSearch(sender)
        }
    }

    func cancelSearch(sender: AnyObject) {
        classChooser.enabled = true
        searchField.stringValue = ""
        searchField.resignFirstResponder()
        currentSearchTerm = ""
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
    
    // MARK: - zoom
    @IBAction func zoomChange(sender: NSSlider) {
        let settings = Settings.instance
        settings.deckManagerZoom = round(sender.doubleValue)
        (cardsCollectionView.collectionViewLayout as! JNWCollectionViewGridLayout).itemSize = NSMakeSize(baseCardWidth / 100 * CGFloat(settings.deckManagerZoom), 259 / 100 * CGFloat(settings.deckManagerZoom))
        cardsCollectionView.reloadData()
    }
    
    // MARK: - preferred view
    @IBAction func changePreferredView(sender: NSSegmentedControl) {
        let settings = Settings.instance
        settings.deckManagerPreferCards = sender.selectedSegment == 0
        changeLayout()
        reloadCards()
    }
}