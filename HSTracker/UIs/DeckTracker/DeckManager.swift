//
//  DeckManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 23/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MagicalRecord

enum DeckManagerViewMode : Int {
    case Classes,
    Deck
}

class DeckManager : NSWindowController, NSTableViewDataSource, NSTableViewDelegate, DeckCellViewDelegate {

    @IBOutlet weak var decksTable: NSTableView!
    @IBOutlet weak var deckListTable: NSTableView!
    @IBOutlet weak var curveView: CurveView!
    @IBOutlet weak var statsLabel: NSTextField!
    
    var viewMode: DeckManagerViewMode = .Classes
    var decks = [Deck]()
    var classes = [String]()
    var currentClass:String?
    var currentDeck:Deck?
    
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
        //decksTable.intercellSpacing = NSSize(width: 0, height: 0)
        
        decksTable.backgroundColor = NSColor.clearColor()
        decksTable.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]
        
        decksTable.tableColumns.first?.width = NSWidth(decksTable.bounds)
        decksTable.tableColumns.first?.resizingMask = NSTableColumnResizingOptions.AutoresizingMask
        
        decksTable.target = self
        decksTable.action = "decksTableClick:"
        decksTable.doubleAction = "decksTableDoubleClick:"
        
        if let _decks = Deck.MR_findAll() {
            decks = _decks as! [Deck]
            for deck in decks {
                if !classes.contains(deck.playerClass) {
                    classes.append(deck.playerClass)
                }
            }
            
            decksTable.reloadData()
        }
        
        deckListTable.tableColumns.first?.width = NSWidth(deckListTable.bounds)
        deckListTable.tableColumns.first?.resizingMask = NSTableColumnResizingOptions.AutoresizingMask
    }
    
    func filteredDecks() -> [Deck] {
        return decks.filter({$0.playerClass == currentClass})
    }
    
    // MARK: - NSTableViewDelegate / NSTableViewDataSource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if tableView == decksTable {
            switch (viewMode) {
            case .Classes:
                return classes.count
            case .Deck:
                return filteredDecks().count
            }
        }
        else if let currentDeck = currentDeck {
            return currentDeck.sortedCards.count
        }
        
        return 0;
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == decksTable {
            let cell = decksTable.makeViewWithIdentifier("DeckCellView", owner: self) as! DeckCellView
            switch (viewMode) {
            case .Classes:
                cell.moreButton.hidden = true
                let clazz = classes[row]
                cell.label.stringValue = NSLocalizedString(clazz, comment: "")
                cell.image.image = ImageCache.classImage(clazz)
                cell.color = ClassColor.color(clazz)
                cell.setDelegate(nil)
            case .Deck:
                let deck = filteredDecks()[row]
                cell.moreButton.hidden = false
                cell.deck = deck
                cell.label.stringValue = deck.name
                cell.image.image = ImageCache.classImage(deck.playerClass)
                cell.color = ClassColor.color(deck.playerClass)
                cell.setDelegate(self)
            }
            return cell
        }
        else {
            let cell = CardCellView()
            cell.playerType = .Player
            cell.card = currentDeck!.sortedCards[row]
            return cell
        }
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == self.decksTable {
            return 55
        }
        else if tableView == self.deckListTable {
            return CGFloat(KRowHeight)
        }
        return 20
    }
    
    func decksTableClick(sender: AnyObject?) {
        guard viewMode == .Deck else {
            return
        }
        guard sender?.clickedRow >= 0 else {
            return
        }
        let clickedRow = sender!.clickedRow!
        DDLogVerbose("\(clickedRow) -> \(filteredDecks())")
        currentDeck = filteredDecks()[clickedRow]
        deckListTable.reloadData()
        curveView.deck = currentDeck
        statsLabel.stringValue = currentDeck!.displayStats()
        curveView.reload()
    }
    
    func decksTableDoubleClick(sender: AnyObject?) {
        guard sender?.clickedRow >= 0 else {
            return
        }

        let clickedRow = sender!.clickedRow!
        if viewMode == .Classes {
            currentClass = classes[clickedRow]
            viewMode = .Deck
            decksTable.reloadData()
        }
    }
    
    //MARK: - Toolbar actions
    override func validateToolbarItem(item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier {
        case "back":
            return viewMode == .Deck
        case "add":
            return true
        default:
            return false
        }
    }
    
    @IBAction func back(sender: AnyObject) {
        currentClass = nil
        viewMode = .Classes
        currentDeck = nil
        deckListTable.reloadData()
        curveView.deck = nil
        statsLabel.stringValue = ""
        curveView.reload()
        decksTable.reloadData()
    }

    @IBAction func addDeck(sender: AnyObject) {
    }
    
    
    // MARK: - DeckCellViewDelegate
    func moreClicked(cell: DeckCellView) {
        let menu = NSMenu()
        var menuItem = NSMenuItem(title: NSLocalizedString("Use", comment: ""),
            action: "",
            keyEquivalent: "")
        menu.addItem(menuItem)
        menuItem = NSMenuItem(title: NSLocalizedString("Edit", comment: ""),
            action: "",
            keyEquivalent: "")
        menu.addItem(menuItem)
        
        NSMenu.popUpContextMenu(menu, withEvent:NSApp.currentEvent!, forView: cell.moreButton)
    }
    
}