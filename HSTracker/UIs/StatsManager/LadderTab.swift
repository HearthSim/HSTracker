//
//  LadderTab.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/25/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

// TODO: Localization

class LadderTab: NSViewController {

    @IBOutlet weak var gamesTable: NSTableView!
    @IBOutlet weak var timeTable: NSTableView!
    @IBOutlet weak var rankPicker: NSPopUpButton!
    @IBOutlet weak var starsPicker: NSPopUpButton!
    @IBOutlet weak var streakButton: NSButton!
    
    var ladderTableItems = [LadderTableRow]()
    
    // TODO: latest data point
    
    var deck: Deck?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // swiftlint:disable line_length
        gamesTable.tableColumns[2].headerToolTip = NSLocalizedString("It is 90% certain that the true winrate falls between these values.", comment: "")
        timeTable.tableColumns[2].headerToolTip  = NSLocalizedString("It is 90% certain that the true winrate falls between these values.", comment: "")
        // swiftlint:enable line_length
        
        for rank in (0...25).reverse() {
            var title: String
            if rank == 0 {
                title = "Legend"
            } else {
                title = String(rank)
            }
            rankPicker.addItemWithTitle(title)
        }
        
        for stars in 0...5 {
            starsPicker.addItemWithTitle(String(stars))
        }
        starsPicker.selectItemAtIndex(1)
        starsPicker.autoenablesItems = false
        
        guessRankAndUpdate()
        
        gamesTable.setDelegate(self)
        timeTable.setDelegate(self)
        gamesTable.setDataSource(self)
        timeTable.setDataSource(self)
        
        gamesTable.reloadData()
        timeTable.reloadData()

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(guessRankAndUpdate),
                                                         name: "reload_decks",
                                                         object: nil)
    }
    
    func guessRankAndUpdate() {
        if !self.viewLoaded {
            return
        }
        if let deck = self.deck {
            let rank = StatsHelper.guessRank(deck)
            rankPicker.selectItemAtIndex(25-rank)
        }
        update()
    }
    @IBAction func rankChanged(sender: AnyObject) {
        update()
    }
    
    @IBAction func starsChanged(sender: AnyObject) {
        update()
    }
    
    @IBAction func streakChanged(sender: AnyObject) {
        update()
    }

    func enableStars(rank: Int) {
        
        for i in 0...5 {
            starsPicker.itemAtIndex(i)!.enabled = false
        }
        for i in 0...Ranks.starsPerRank[rank]! {
            starsPicker.itemAtIndex(i)!.enabled = true
        }
        
        if starsPicker.selectedItem?.enabled == false {
            starsPicker.selectItemAtIndex(Ranks.starsPerRank[rank]!)
        }
        
        streakButton.enabled = true
        if rank <= 5 {
            streakButton.enabled = false
            streakButton.state = NSOffState
        }
    }
    
    func update() {
        if let selectedRank = rankPicker.selectedItem, selectedStars = starsPicker.selectedItem {
            var rank: Int
            if selectedRank.title == "Legend" {
                rank = 0
            } else {
                rank = Int(selectedRank.title)!
            }
            enableStars(rank)
            
            let stars = Int(selectedStars.title)!
            
            if let deck = self.deck {
                let streak = (streakButton.state == NSOnState)
                ladderTableItems = StatsHelper.getLadderTableData(deck,
                                                                  rank: rank,
                                                                  stars: stars,
                                                                  streak: streak)
            } else {
                ladderTableItems = []
            }
            gamesTable.reloadData()
            timeTable.reloadData()
        }
    }
    
}

extension LadderTab : NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if [gamesTable, timeTable].contains(tableView) {
            return ladderTableItems.count
        } else {
            return 0
        }
    }
}

extension LadderTab : NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""
        var alignment: NSTextAlignment = NSTextAlignment.Left
        
        let item = ladderTableItems[row]
        
        if tableView == gamesTable {
            if tableColumn == gamesTable.tableColumns[0] {
                text  = item.rank
                alignment = NSTextAlignment.Left
                cellIdentifier = "LadderGRankCellID"
            } else if tableColumn == gamesTable.tableColumns[1] {
                text = item.games
                alignment = NSTextAlignment.Right
                cellIdentifier = "LadderGToRankCellID"
            } else if tableColumn == gamesTable.tableColumns[2] {
                text = item.gamesCI
                alignment = NSTextAlignment.Right
                cellIdentifier = "LadderG90CICellID"
            }
        } else if tableView == timeTable {
            if tableColumn == timeTable.tableColumns[0] {
                text  = item.rank
                alignment = NSTextAlignment.Left
                cellIdentifier = "LadderTRankCellID"
            } else if tableColumn == timeTable.tableColumns[1] {
                text = item.time
                alignment = NSTextAlignment.Right
                cellIdentifier = "LadderTToRankCellID"
            } else if tableColumn == timeTable.tableColumns[2] {
                text = item.timeCI
                alignment = NSTextAlignment.Right
                cellIdentifier = "LadderT90CICellID"
            }
        } else {
            return nil
        }
        
        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil)
            as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.textField?.alignment = alignment
            
            return cell
        }
        
        return nil
    }
}
