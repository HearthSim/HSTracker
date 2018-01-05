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
    @IBOutlet weak var seasonPicker: NSPopUpButton!
    
    var deck: Deck? 
    
    var statsTableItems = [StatsTableRow]()
    
    let modePickerItems: [GameMode] = [.all, .ranked, .casual, .brawl, .arena, .friendly, .practice]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        for mode in modePickerItems {
            modePicker.addItem(withTitle: mode.userFacingName)
        }
        modePicker.selectItem(at: modePickerItems.index(of: .ranked)!)
        
        seasonPicker.addItem(withTitle: NSLocalizedString("all_seasons", comment: ""))
        if let deck = self.deck {
            let seasons = Array(deck.gameStats).flatMap({ $0.season })
                .sorted().reversed()
            for season in seasons {
                seasonPicker.addItem(
                    withTitle: String(format: NSLocalizedString("season", comment: ""),
                        NSNumber(value: season as Int)))
                seasonPicker.lastItem?.tag = season
            }
        }
        seasonPicker.selectItem(at: 0)
        
        update()
        
        statsTable.delegate = self
        statsTable.dataSource = self
        
        let descClass = NSSortDescriptor(key: "opponentClassName", ascending: true)
        let descRecord = NSSortDescriptor(key: "totalGames", ascending: false)
        let descWinrate = NSSortDescriptor(key: "winRateNumber", ascending: false)
        let descCI = NSSortDescriptor(key: "confidenceWindow", ascending: true)
        
        statsTable.tableColumns[0].sortDescriptorPrototype = descClass
        statsTable.tableColumns[1].sortDescriptorPrototype = descRecord
        statsTable.tableColumns[2].sortDescriptorPrototype = descWinrate
        statsTable.tableColumns[3].sortDescriptorPrototype = descCI
        
        // swiftlint:disable line_length
        statsTable.tableColumns[3].headerToolTip = NSLocalizedString("It is 90% certain that the true winrate falls between these values.", comment: "")
        // swiftlint:enable line_length
        
        // We need to update the display both when the
        // stats change
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(update),
                         name: NSNotification.Name(rawValue: Events.reload_decks),
                         object: nil)
    }

    func sortStatsTable() {
        let sorted = (statsTableItems as NSArray)
            .sortedArray(using: statsTable.sortDescriptors)
        if let _statsTableItems = sorted as? [StatsTableRow] {
            statsTableItems = _statsTableItems
        }
    }
        
    @objc func update() {
        if let deck = self.deck {
            var index = modePicker.indexOfSelectedItem
            if index == -1 { // In case somehow nothing is selected
                modePicker.selectItem(at: modePickerItems.index(of: .ranked)!)
                index = modePicker.indexOfSelectedItem
            }
            var season = seasonPicker.indexOfSelectedItem
            if season == -1 {
                season = 0
                seasonPicker.selectItem(at: 0)
            }
            if season > 0 {
                season = seasonPicker.selectedTag()
            }
            
            DispatchQueue.main.async {
                self.statsTableItems = StatsHelper.getStatsUITableData(deck: deck,
                                                        mode: self.modePickerItems[index],
                                                        season: season)
                self.sortStatsTable()
                self.statsTable.reloadData()
            }
        } else {
            DispatchQueue.main.async {
                self.statsTableItems = []
                self.statsTable.reloadData()
            }
        }
    }
    
    @IBAction func modeSelected(_ sender: AnyObject) {
        update()
    }
    
    @IBAction func changeSeason(_ sender: AnyObject) {
        update()
    }
}

extension StatsTab: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == statsTable {
            return statsTableItems.count
        } else {
            return 0
        }
    }
}

extension StatsTab: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        
        if tableView != statsTable {
            return nil
        }
        
        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        var alignment: NSTextAlignment = NSTextAlignment.left
        
        let item = statsTableItems[row]
        
        if tableColumn == tableView.tableColumns[0] {
            image = NSImage(named: NSImage.Name(rawValue: item.classIcon))
            text  = item.opponentClassName
            alignment = NSTextAlignment.left
            cellIdentifier = "StatsClassCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.record
            alignment = NSTextAlignment.right
            cellIdentifier = "StatsRecordCellID"
        } else if tableColumn == tableView.tableColumns[2] {
            text = item.winRate
            alignment = NSTextAlignment.right
            cellIdentifier = "StatsWinRateCellID"
        } else if tableColumn == tableView.tableColumns[3] {
            text = item.confidenceInterval
            alignment = NSTextAlignment.right
            cellIdentifier = "StatsCICellID"
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil)
            as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            cell.textField?.alignment = alignment
            
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView,
                   sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        if tableView == statsTable {
            DispatchQueue.main.async {
                self.sortStatsTable()
                self.statsTable.reloadData()
            }
        }
    }
    
}
