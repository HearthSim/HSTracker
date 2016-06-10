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
    
    
    
    var statsTableItems = [Dictionary<String, String>]()

    override func windowDidLoad() {
        super.windowDidLoad()
        update()

        statsTable.setDelegate(self)
        statsTable.setDataSource(self)
        
        // We need to update the display both when the 
        // stats change and when the deck is changed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(update), name: "reload_decks", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(update), name: "active_deck_changed", object: nil)
        
    }
    
    func update(){
        if let deck = Game.instance.activeDeck{
            // XXX: This might be unsafe
            // I'm assuming that the player class names
            // and class assets are always the same
            var imageName = deck.playerClass
            if !StatsHelper.playerClassList.contains(imageName){
                imageName = "error"
            }
            selectedDeckIcon.image = NSImage(named: imageName)
            if let deckName = deck.name{
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
    
    
}


extension Statistics : NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return statsTableItems.count
    }
}

extension Statistics : NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var image:NSImage?
        var text:String = ""
        var cellIdentifier:String = ""
        var alignment:NSTextAlignment = NSTextAlignment.Left
        
        let item = statsTableItems[row]
        
        if tableColumn == tableView.tableColumns[0] {
            image = NSImage(named: item["classIcon"]!)
            text  = item["className"]!
            alignment = NSTextAlignment.Left
            cellIdentifier = "StatsClassCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = item["record"]!
            alignment = NSTextAlignment.Right
            cellIdentifier = "StatsRecordCellID"
        } else if tableColumn == tableView.tableColumns[2] {
            text = item["winRate"]!
            alignment = NSTextAlignment.Right
            cellIdentifier = "StatsWinRateCellID"
        }
        
        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            cell.textField?.alignment = alignment
            
            return cell
        }
        
        return nil
    }
    
}