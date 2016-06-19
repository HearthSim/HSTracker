//
//  Statistics.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/8/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import CleanroomLogger

class Statistics: NSWindowController {
    @IBOutlet weak var statsTable: NSTableView!
    @IBOutlet weak var selectedDeckIcon: NSImageView!
    @IBOutlet weak var selectedDeckName: NSTextField!
    
    var deck: Deck?
    
    var statsTableItems = [StatsTableRow]()

    override func windowDidLoad() {
        super.windowDidLoad()
        update()

        statsTable.setDelegate(self)
        statsTable.setDataSource(self)
        
        let descClass   = NSSortDescriptor(key: "opponentClassName", ascending: true)
        let descRecord  = NSSortDescriptor(key: "totalGames", ascending: false)
        let descWinrate = NSSortDescriptor(key: "winRateNumber", ascending: false)
        let descCI      = NSSortDescriptor(key: "confidenceWindow", ascending: true)
        
        statsTable.tableColumns[0].sortDescriptorPrototype = descClass
        statsTable.tableColumns[1].sortDescriptorPrototype = descRecord
        statsTable.tableColumns[2].sortDescriptorPrototype = descWinrate
        statsTable.tableColumns[3].sortDescriptorPrototype = descCI;
        
        statsTable.tableColumns[3].headerToolTip = "It is 90% certain that the true winrate falls between these values."
        
        // We need to update the display both when the 
        // stats change
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(update),
                                                         name: "reload_decks",
                                                         object: nil)
    }
    
    func update() {
        if let deck = self.deck {
            // XXX: This might be unsafe
            // I'm assuming that the player class names
            // and class assets are always the same
            var imageName = deck.playerClass
            if !StatsHelper.playerClassList.contains(imageName) {
                imageName = "error"
            }
            selectedDeckIcon.image = NSImage(named: imageName)
            if let deckName = deck.name {
                selectedDeckName.stringValue = deckName
            } else {
                selectedDeckName.stringValue = "Deck name missing."
            }
            
            statsTableItems = StatsHelper.getStatsUITableData(deck)
            
        } else {
            selectedDeckIcon.image = NSImage(named: "error")
            selectedDeckName.stringValue = "No deck selected."
            
            statsTableItems = []
        }
        
        statsTable.reloadData()
    }
    
    @IBAction func closeWindow(sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }
}


extension Statistics : NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return statsTableItems.count
    }
}

extension Statistics : NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {

        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        var alignment: NSTextAlignment = NSTextAlignment.Left
        
        let item = statsTableItems[row]
        
        if tableColumn == tableView.tableColumns[0] {
            image = NSImage(named: item.classIcon)
            text  = item.opponentClassName
            alignment = NSTextAlignment.Left
            cellIdentifier = "StatsClassCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.record
            alignment = NSTextAlignment.Right
            cellIdentifier = "StatsRecordCellID"
        } else if tableColumn == tableView.tableColumns[2] {
            text = item.winRate
            alignment = NSTextAlignment.Right
            cellIdentifier = "StatsWinRateCellID"
        } else if tableColumn == tableView.tableColumns[3] {
            text = item.confidenceInterval
            alignment = NSTextAlignment.Right
            cellIdentifier = "StatsCICellID"
        }

    
        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil)
            as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            cell.textField?.alignment = alignment
            
            return cell
        }
        
        return nil
    }
    
    func tableView(tableView: NSTableView, sortDescriptorsDidChange
        oldDescriptors: [NSSortDescriptor]) {
        let sorted = (statsTableItems as NSArray)
            .sortedArrayUsingDescriptors(tableView.sortDescriptors)
        if let _statsTableItems = sorted as? [StatsTableRow] {
            statsTableItems = _statsTableItems
        }
        statsTable.reloadData()
    }
    
}
