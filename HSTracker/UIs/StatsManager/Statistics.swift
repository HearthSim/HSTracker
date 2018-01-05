//
//  Statistics.swift
//  HSTracker
//
//  Created by Matthew Welborn on 6/8/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import RealmSwift

class Statistics: NSWindowController {
    @IBOutlet weak var selectedDeckIcon: NSImageView!
    @IBOutlet weak var selectedDeckName: NSTextField!
    
    @IBOutlet weak var tabs: NSTabView!
    
    var deck: Deck?
    var statsTab: StatsTab?
    var ladderTab: LadderTab?
    
    var tabSizes = [NSTabViewItem: CGSize]()

    override func windowDidLoad() {
        super.windowDidLoad()
        
        update()
        
        statsTab = StatsTab(nibName: NSNib.Name(rawValue: "StatsTab"), bundle: nil)
        statsTab!.deck = self.deck
        
        ladderTab = LadderTab(nibName: NSNib.Name(rawValue: "LadderTab"), bundle: nil)
        ladderTab!.deck = self.deck
        ladderTab!.guessRankAndUpdate()
        
        let statsTabView = NSTabViewItem(viewController: statsTab!)
        statsTabView.label = NSLocalizedString("Statistics", comment: "")
        tabSizes[statsTabView] = statsTab!.view.frame.size
        
        let ladderTabView = NSTabViewItem(viewController: ladderTab!)
        ladderTabView.label = NSLocalizedString("The Climb", comment: "")
        tabSizes[ladderTabView] = ladderTab!.view.frame.size
        
        tabs.addTabViewItem(statsTabView)
        tabs.addTabViewItem(ladderTabView)
        
        resizeWindowToFitTab(statsTabView)
        
        tabs.delegate = self
        tabs.selectTabViewItem(statsTabView)

        // We need to update the display both when the
        // stats change
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(update),
                         name: NSNotification.Name(rawValue: Events.reload_decks),
                         object: nil)

    }

    func resizeWindowToFitTab(_ tab: NSTabViewItem) {
        //TODO: centering?
        guard let desiredTabSize = tabSizes[tab], let swindow = self.window
            else { return }
        
        let currentTabSize = tab.view!.frame.size
        let windowSize = swindow.frame.size
        
        let newSize = CGSize(
            width: windowSize.width + desiredTabSize.width - currentTabSize.width,
            height: windowSize.height + desiredTabSize.height - currentTabSize.height)
        
        var frame = swindow.frame
        frame.origin.y = swindow.frame.origin.y - newSize.height + windowSize.height
        frame.size = newSize
        swindow.setFrame(frame, display: true)
    }
    
    @objc func update() {
        if let deck = self.deck {
            // XXX: This might be unsafe
            // I'm assuming that the player class names
            // and class assets are always the same
            let imageName = deck.playerClass.rawValue.lowercased()
            selectedDeckIcon.image = NSImage(named: NSImage.Name(rawValue: imageName))
            selectedDeckName.stringValue = deck.name
        } else {
            selectedDeckIcon.image = NSImage(named: NSImage.Name(rawValue: "error"))
            selectedDeckName.stringValue = "No deck selected."
        }
    }

    @IBAction func closeWindow(_ sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse.OK)
    }

    @IBAction func deleteStatistics(_ sender: AnyObject) {
        if let deck = deck {
            let msg = String(format: NSLocalizedString("Are you sure you want to delete the "
                + "statistics for the deck %@ ?", comment: ""), deck.name)
            NSAlert.show(style: .informational, message: msg, window: self.window!) {
                RealmHelper.removeAllGameStats(from: deck)
                
                DispatchQueue.main.async {
                    self.statsTab!.statsTable.reloadData()
                }
            }
        }
    }
}

extension Statistics: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if tabView == tabs {
            guard let item = tabViewItem
                else { return }
            resizeWindowToFitTab(item)
        }
    }
}

