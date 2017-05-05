//
//  EditDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift
import AppKit

class EditDeck: NSWindowController, NSComboBoxDataSource, NSComboBoxDelegate {

    @IBOutlet weak var cardsTableView: NSTableView!
    @IBOutlet weak var countLabel: NSTextField!
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

    //@IBOutlet weak var zoom: NSSlider!

    var isSaved: Bool = false
    weak var delegate: NewDeckDelegate?
    var currentDeck: Deck?
    var cards: [Card] = []
    var currentPlayerClass: CardClass?
    var currentSet: [CardSet] = []
    var selectedClass: CardClass?
    var currentClassCards: [Card] = []
    var currentCardCost = -1
    var currentSearchTerm = ""
    var currentRarity: Rarity?
    var standardOnly = true
    var currentDamage = -1
    var currentHealth = -1
    var currentRace: Race?
    var currentCardType: CardType = .invalid
    var deckUndoManager: UndoManager?

    var monitor: Any?

    var saveDeck: SaveDeck?

    let baseCardWidth: CGFloat = 181
    let baseCardHeight: CGFloat = 250

    func set(playerClass: CardClass) {
        currentPlayerClass = playerClass
        selectedClass = currentPlayerClass
    }

    func set(deck: Deck) {
        currentDeck = deck
        cards = deck.cards.flatMap {
            if let card = Cards.by(cardId: $0.id) {
                card.count = $0.count
                return card
            }
            return nil
        }
        isSaved = true
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        reloadCards()

        if let playerClass = currentPlayerClass {
            classChooser.segmentCount = 2
            classChooser.setLabel(NSLocalizedString(playerClass.rawValue.lowercased(),
                comment: ""), forSegment: 0)
        } else {
            classChooser.segmentCount = 1
        }
        classChooser.setLabel(NSLocalizedString("neutral", comment: ""), forSegment: 1)
        classChooser.setSelected(true, forSegment: 0)

        deckCardsView.reloadData()

        curveView?.deck = currentDeck
        curveView?.reload()

        standardOnlyCards.title = ""
        standardOnlyCards.image = NSImage(named: "Mode_Standard_Mammoth",
                                          size: NSSize(width: 25, height: 25))

        countCards()

        loadSets()
        loadCardTypes()
        loadRarities()
        loadRaces()

        if let deck = self.currentDeck {
            let name = deck.name
            let playerClass = deck.playerClass.rawValue.lowercased()
            self.window?.title = "\(NSLocalizedString(playerClass, comment: ""))"
                + " - \(name)"
        }

        if let cell = searchField.cell as? NSSearchFieldCell {
            cell.cancelButtonCell!.target = self
            cell.cancelButtonCell!.action = #selector(EditDeck.cancelSearch(_:))
        }

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(EditDeck.updateTheme(_:)),
                         name: NSNotification.Name(rawValue: "theme"),
                         object: nil)

        deckUndoManager = window?.undoManager
        initKeyboardShortcuts()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        removeKeyboardShortcuts()
    }

    func initKeyboardShortcuts() {
        self.monitor = NSEvent
            .addLocalMonitorForEvents(matching: .keyDown) { (e) -> NSEvent? in

            let isCmd = e.modifierFlags.contains(.command)

            if isCmd {
                switch e.keyCode {
                case 3: // cmd-f
                    self.searchField.selectText(self)
                    self.searchField.becomeFirstResponder()
                    return nil

                case 1: // cmd-s
                    self.save(nil)
                    return nil

                default:
                    break
                }

                // cmd-[1 to 9] for adding a card to a deck.
                //
                // Using characters pressed rather than keycodes, as keycodes
                // distinguish between numpads and numbers above qwerty etc..
                //
                /* TODO FIXME reactivate
                guard let charsPressed = e.charactersIgnoringModifiers,
                    let numberPressed = Int(charsPressed.char(at: 0)),
                    let visibleCardIndexPaths = self.cardsCollectionView
                        .indexPathsForVisibleItems()
                        as? [IndexPath], 1 ... visibleCardIndexPaths.count ~= numberPressed
                    else { return e }

                if let cell = self.cardsCollectionView
                    .cellForItem(at: visibleCardIndexPaths[numberPressed - 1])
                    as? CardCell,
                    let card = cell.card {

                    self.addCardToDeck(card)
                    return nil
                }

                Log.verbose?.message("unsupported keycode \(e.keyCode)")
 */
            }

            return e
        }
    }

    func removeKeyboardShortcuts() {
        if let monitor = self.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func setDelegate(_ delegate: NewDeckDelegate) {
        self.delegate = delegate
    }

    fileprivate func reloadCards() {
        currentClassCards = Cards.search(
            className: currentSearchTerm == "" ? selectedClass : currentPlayerClass,
            sets: currentSet,
            term: currentSearchTerm,
            cost: currentCardCost,
            rarity: currentRarity,
            standardOnly: standardOnly,
            damage: currentDamage,
            health: currentHealth,
            type: currentCardType,
            race: currentRace)

        cardsTableView.reloadData()
    }

    func countCards() {
        let count = cards.countCards()
        countLabel.stringValue = "\(count) / 30"
    }

    func updateTheme(_ notification: Notification) {
        deckCardsView.reloadData()
        cardsTableView.reloadData()
    }

    // MARK: - NSSegmentedControl
    @IBAction func changeClassTab(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            selectedClass = currentPlayerClass
        } else {
            selectedClass = .neutral
        }
        reloadCards()
    }

    @IBAction func clickCard(_ sender: NSTableView) {
        guard sender.clickedRow >= 0 else { return }
        let card: Card

        if sender == cardsTableView {
            card = currentClassCards[sender.clickedRow]
            if cards.countCards() == 30 {
                return
            }

            if cardCanBeAdded(card) {
                //cell.flash()
                addCardToDeck(card)

                if let deckCard = cards.filter({ $0.id == card.id }).first {
                    card.count = deckCard.count
                }
            }
        } else {
            card = cards.sortCardList()[sender.clickedRow]
            undoCardAdd(card)
        }
    }
    
    func cardCanBeAdded(_ card: Card) -> Bool {
        let deckCard = cards.filter({ $0.id == card.id }).first
        return deckCard == nil || currentDeck!.isArena ||
            (deckCard!.count == 1 && card.rarity != .legendary)
    }

    func addCardToDeck(_ card: Card) {
        if cardCanBeAdded(card) {
            redoCardAdd(card)
        }
    }
    
    // MARK: - Undo/Redo
    func undoCardAdd(_ card: AnyObject) {
        if let c = card as? Card {
            deckUndoManager?.registerUndo(withTarget: self,
                                          selector: #selector(redoCardAdd(_:)),
                                          object: card)
            
            if deckUndoManager?.isUndoing == true {
                deckUndoManager?.setActionName(NSLocalizedString("Add Card", comment: ""))
            } else {
                deckUndoManager?.setActionName(NSLocalizedString("Remove Card", comment: ""))
            }
            
            remove(card: c)
            curveView.reload()
            deckCardsView.reloadData()
            cardsTableView.reloadData()
            countCards()
            isSaved = false
        }
    }
    
    func redoCardAdd(_ card: AnyObject) {
        if let c = card as? Card {
            deckUndoManager?.registerUndo(withTarget: self,
                                          selector: #selector(undoCardAdd(_:)),
                                          object: card)
            
            if deckUndoManager?.isUndoing == true {
                deckUndoManager?.setActionName(NSLocalizedString("Remove Card", comment: ""))
            } else {
                deckUndoManager?.setActionName(NSLocalizedString("Add Card", comment: ""))
            }

            add(card: c)
            curveView.reload()
            deckCardsView.reloadData()
            cardsTableView.reloadData()
            countCards()
            isSaved = false
        }
    }

    func add(card: Card) {
        if card.count == 0 {
            card.count = 1
        }

        if let c = cards.first({ $0.id == card.id }) {
            c.count += 1
        } else {
            cards.append(card)
        }
    }

    func remove(card: Card) {
        guard let c = cards.first({ $0.id == card.id }) else { return }
        c.count -= 1
        if c.count == 0 {
            cards.remove(c)
        }
    }

    // MARK: - Standard/Wild
    @IBAction func standardWildChange(_ sender: NSButton) {
        standardOnly = sender.state == NSOnState

        let name = standardOnly ? "Mode_Standard_Mammoth" : "Mode_Wild_Dark"
        standardOnlyCards.image = NSImage(named: name,
                                          size: NSSize(width: 25, height: 25))
        reloadCards()
    }

    // MARK: - Gems
    @IBAction func manaGemClicked(_ sender: ManaGemButton) {
        let gems = [manaGem0, manaGem1, manaGem2, manaGem3, manaGem4, manaGem5, manaGem6, manaGem7]

        if sender.selected {
            sender.selected = false
            currentCardCost = -1
        } else {
            currentCardCost = sender.tag
            for gem in gems {
                gem?.selected = sender == gem
            }
        }

        reloadCards()
    }

    // MARK: - Sets
    private func loadSets() {
        let popupMenu = NSMenu()
        for set in CardSet.deckManagerValidCardSets() {
            let popupMenuItem = NSMenuItem(title:
                NSLocalizedString(set.rawValue.uppercased(), comment: ""),
                                           action: #selector(EditDeck.changeSet(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = set.rawValue
            popupMenuItem.image = NSImage(named: "Set_\(set.rawValue.uppercased())",
                size: NSSize(width: 15, height: 15))
            popupMenu.addItem(popupMenuItem)
        }
        sets.menu = popupMenu
    }

    @IBAction func changeSet(_ sender: NSMenuItem) {
        if let type = sender.representedObject as? String {
            switch type {
            case "all": currentSet = []
            case "expert1": currentSet = [.core, .expert1, .promo, .hof]
            default:
                if let set = CardSet(rawValue: type) {
                    currentSet = [set]
                } else {
                    currentSet = []
                }
            }
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
            popupMenuItem.representedObject = cardType.lowercased()
            popupMenu.addItem(popupMenuItem)
        }
        cardType.menu = popupMenu
    }

    @IBAction func changeCardType(_ sender: NSMenuItem) {
        if let type = sender.representedObject as? String {
            switch type {
            case "all_types": currentCardType = .invalid
            default: currentCardType = CardType(rawString: type) ?? .invalid
            }
        }

        reloadCards()
    }

    // MARK: - Races
    private func loadRaces() {
        let popupMenu = NSMenu()
        let popupMenuItem = NSMenuItem(title: NSLocalizedString("all_races", comment: ""),
                                       action: #selector(EditDeck.changeRace(_:)),
                                       keyEquivalent: "")
        popupMenuItem.representedObject = "all"
        popupMenu.addItem(popupMenuItem)

        for race in Database.deckManagerRaces {
            let popupMenuItem = NSMenuItem(title: NSLocalizedString(race.rawValue,
                comment: ""),
                                           action: #selector(EditDeck.changeRace(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = race.rawValue
            popupMenu.addItem(popupMenuItem)
        }
        races.menu = popupMenu
    }

    @IBAction func changeRace(_ sender: NSMenuItem) {
        if let type = sender.representedObject as? String {
            switch type {
            case "all": currentRace = nil
            default: currentRace = Race(rawValue: type)
            }
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

        for rarity in Rarity.cases() {
            let popupMenuItem = NSMenuItem(title: "",
                                           action: #selector(EditDeck.changeRarity(_:)),
                                           keyEquivalent: "")
            popupMenuItem.representedObject = rarity.rawValue
            let gemName = rarity == .free ? "gem" : "gem_\(rarity.rawValue)"

            let fullPath = Bundle.main.resourcePath!
                + "/Resources/Themes/Bars/classic/\(gemName).png"
            if let image = NSImage(contentsOfFile: fullPath) {
                popupMenuItem.image = image.resized(to: NSSize(width: 25, height: 25))
            } else {
                popupMenuItem.title = gemName
            }

            popupMenu.addItem(popupMenuItem)
        }
        rarity.menu = popupMenu
    }

    @IBAction func changeRarity(_ sender: NSMenuItem) {
        if let type = sender.representedObject as? String {
            switch type {
            case "all_rarities": currentRarity = .none
            default: currentRarity = Rarity(rawValue: type)
            }
        }

        reloadCards()
    }

    // MARK: - Toolbar actions
    @IBAction func save(_ sender: AnyObject?) {
        saveDeck = SaveDeck(windowNibName: "SaveDeck")
        if let saveDeck = saveDeck {
            saveDeck.setDelegate(self)
            saveDeck.deck = currentDeck
            saveDeck.cards = cards
            self.window!.beginSheet(saveDeck.window!, completionHandler: nil)
        }
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        self.window?.performClose(self)
    }

    // MARK: - Search
    @IBAction func search(_ sender: NSSearchField) {
        currentSearchTerm = sender.stringValue

        if !currentSearchTerm.isEmpty {
            classChooser.isEnabled = false
            reloadCards()
        } else {
            cancelSearch(sender)
        }
    }

    func cancelSearch(_ sender: AnyObject) {
        classChooser.isEnabled = true
        searchField.stringValue = ""
        searchField.resignFirstResponder()
        currentSearchTerm = ""
        reloadCards()
    }
}

// MARK: - NSWindowDelegate
extension EditDeck: NSWindowDelegate {
    func windowDidBecomeMain(_ notification: Notification) {
        initKeyboardShortcuts()
    }

    func windowDidResignMain(_ notification: Notification) {
        removeKeyboardShortcuts()
    }

    func windowShouldClose(_ sender: Any) -> Bool {
        if isSaved {
            delegate?.refreshDecks()
            return true
        }
        
        let alert = NSAlert()
        alert.alertStyle = .informational
        // swiftlint:disable line_length
        alert.messageText = NSLocalizedString("Are you sure you want to close this deck? "
            + "Your changes will not be saved.", comment: "")
        // swiftlint:enable line_length
        alert.addButton(withTitle: NSLocalizedString("Yes", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        return alert.runModal() == NSAlertFirstButtonReturn
    }
}

// MARK: - NSTableViewDataSource
extension EditDeck: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == cardsTableView {
            return currentClassCards.count
        } else {
            return cards.count
        }
    }
}

// MARK: - NSTableViewDelegate
extension EditDeck: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = CardBar.factory()

        let card: Card
        if tableView == cardsTableView {
            card = currentClassCards[row]
            var count: Int = 0
            if let deckCard = cards.sortCardList().firstWhere({ $0.id == card.id }) {
                count = deckCard.count
            }
            card.count = count
            cell.playerType = .editDeck
            cell.isArena = currentDeck!.isArena
        } else {
            cell.playerType = .deckManager
            card = cards.sortCardList()[row]
        }
        cell.card = card
        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(kRowHeight)
    }
}

// MARK: - SaveDeckDelegate
extension EditDeck: SaveDeckDelegate {
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

// MARK: - Health/Damage - NSTextFieldDelegate
extension EditDeck: NSTextFieldDelegate {
    override func controlTextDidChange(_ notification: Notification) {
        if let editor = notification.object as? NSTextField {
            if editor == health {
                if let value = Int(editor.stringValue) {
                    currentHealth = value
                } else {
                    currentHealth = -1
                }
            } else if editor == damage {
                if let value = Int(editor.stringValue) {
                    currentDamage = value
                } else {
                    currentDamage = -1
                }
            }

            reloadCards()
        }
    }
}
