//
//  StatsTab.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/25/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

class StatsTab: NSViewController {

    @IBOutlet weak var modePicker: NSPopUpButton!
    @IBOutlet weak var statsTable: NSTableView!
    
    var deck: Deck? 
    
    var statsTableItems = [StatsTableRow]()
    
    let modePickerItems: [GameMode] = [.All, .Ranked, .Casual, .Brawl, .Arena, .Friendly]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        for mode in modePickerItems {
            modePicker.addItemWithTitle(mode.userFacingName)
        }
        modePicker.selectItemAtIndex(modePickerItems.indexOf(.Ranked)!)
        
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
        statsTable.tableColumns[3].sortDescriptorPrototype = descCI
        
        // swiftlint:disable line_length
        statsTable.tableColumns[3].headerToolTip = NSLocalizedString("It is 90% certain that the true winrate falls between these values.", comment: "")
        // swiftlint:enable line_length
        
        // We need to update the display both when the
        // stats change
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(update),
                                                         name: "reload_decks",
                                                         object: nil)
    }
    
    func sortStatsTable() {
        let sorted = (statsTableItems as NSArray)
            .sortedArrayUsingDescriptors(statsTable.sortDescriptors)
        if let _statsTableItems = sorted as? [StatsTableRow] {
            statsTableItems = _statsTableItems
        }
    }
    
    
    func update() {
        if let deck = self.deck {
            var index = modePicker.indexOfSelectedItem
            if index == -1 { // In case somehow nothing is selected
                modePicker.selectItemAtIndex(modePickerItems.indexOf(.Ranked)!)
                index = modePicker.indexOfSelectedItem
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.statsTableItems = StatsHelper.getStatsUITableData(deck,
                                                        mode: self.modePickerItems[index])
                self.sortStatsTable()
                self.statsTable.reloadData()
            }
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.statsTableItems = []
                self.statsTable.reloadData()
            }
        }
    }
    
    @IBAction func modeSelected(sender: AnyObject) {
        update()
    }
}

extension StatsTab : NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if tableView == statsTable {
            return statsTableItems.count
        } else {
            return 0
        }
    }
}

extension StatsTab : NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        
        if tableView != statsTable {
            return nil
        }
        
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
        if tableView == statsTable {
            dispatch_async(dispatch_get_main_queue()) {
                self.sortStatsTable()
                self.statsTable.reloadData()
            }
        }
    }
    
}
