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
        
        for rank in (0...25).reversed() {
            var title: String
            if rank == 0 {
                title = "Legend"
            } else {
                title = String(rank)
            }
            rankPicker.addItem(withTitle: title)
        }
        
        for stars in 0...5 {
            starsPicker.addItem(withTitle: String(stars))
        }
        starsPicker.selectItem(at: 1)
        starsPicker.autoenablesItems = false
        
        guessRankAndUpdate()
        
        gamesTable.delegate = self
        timeTable.delegate = self
        gamesTable.dataSource = self
        timeTable.dataSource = self
        
        DispatchQueue.main.async {
            self.gamesTable.reloadData()
            self.timeTable.reloadData()
        }

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(guessRankAndUpdate),
                         name: NSNotification.Name(rawValue: Events.reload_decks),
                         object: nil)
    }

    @objc func guessRankAndUpdate() {
        if !self.isViewLoaded {
            return
        }
        if let deck = self.deck {
            let rank = StatsHelper.guessRank(deck: deck)
            rankPicker.selectItem(at: 25 - rank)
        }
        update()
    }
    @IBAction func rankChanged(_ sender: AnyObject) {
        update()
    }
    
    @IBAction func starsChanged(_ sender: AnyObject) {
        update()
    }
    
    @IBAction func streakChanged(_ sender: AnyObject) {
        update()
    }

    func enableStars(rank: Int) {
        
        for i in 0...5 {
            starsPicker.item(at: i)!.isEnabled = false
        }
        for i in 0...Ranks.starsPerRank[rank]! {
            starsPicker.item(at: i)!.isEnabled = true
        }
        
        if starsPicker.selectedItem?.isEnabled == false {
            starsPicker.selectItem(at: Ranks.starsPerRank[rank]!)
        }
        
        streakButton.isEnabled = true
        if rank <= 5 {
            streakButton.isEnabled = false
            streakButton.state = .off
        }
    }
    
    func update() {
        if let selectedRank = rankPicker.selectedItem,
            let selectedStars = starsPicker.selectedItem {
            var rank: Int
            if selectedRank.title == "Legend" {
                rank = 0
            } else {
                rank = Int(selectedRank.title)!
            }
            enableStars(rank: rank)
            
            let stars = Int(selectedStars.title)!
            
            if let deck = self.deck {
                let streak = (streakButton.state == .on)
                DispatchQueue.main.async {
                    self.ladderTableItems = StatsHelper.getLadderTableData(deck: deck,
                                                                           rank: rank,
                                                                           stars: stars,
                                                                           streak: streak)
                    self.gamesTable.reloadData()
                    self.timeTable.reloadData()
                }
                
            } else {
                DispatchQueue.main.async {
                    self.ladderTableItems = []
                    self.gamesTable.reloadData()
                    self.timeTable.reloadData()
                }
            }
        }
    }
}

extension LadderTab: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if [gamesTable, timeTable].contains(tableView) {
            return ladderTableItems.count
        } else {
            return 0
        }
    }
}

extension LadderTab: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""
        var alignment: NSTextAlignment = NSTextAlignment.left
        
        let item = ladderTableItems[row]
        
        if tableView == gamesTable {
            if tableColumn == gamesTable.tableColumns[0] {
                text  = item.rank
                alignment = NSTextAlignment.left
                cellIdentifier = "LadderGRankCellID"
            } else if tableColumn == gamesTable.tableColumns[1] {
                text = item.games
                alignment = NSTextAlignment.right
                cellIdentifier = "LadderGToRankCellID"
            } else if tableColumn == gamesTable.tableColumns[2] {
                text = item.gamesCI
                alignment = NSTextAlignment.right
                cellIdentifier = "LadderG90CICellID"
            }
        } else if tableView == timeTable {
            if tableColumn == timeTable.tableColumns[0] {
                text  = item.rank
                alignment = NSTextAlignment.left
                cellIdentifier = "LadderTRankCellID"
            } else if tableColumn == timeTable.tableColumns[1] {
                text = item.time
                alignment = NSTextAlignment.right
                cellIdentifier = "LadderTToRankCellID"
            } else if tableColumn == timeTable.tableColumns[2] {
                text = item.timeCI
                alignment = NSTextAlignment.right
                cellIdentifier = "LadderT90CICellID"
            }
        } else {
            return nil
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil)
            as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.textField?.alignment = alignment
            
            return cell
        }
        
        return nil
    }
}
