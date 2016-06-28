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
    @IBOutlet weak var selectedDeckIcon: NSImageView!
    @IBOutlet weak var selectedDeckName: NSTextField!
    
    @IBOutlet weak var tabs: NSTabView!
    
    var deck: Deck?
    var statsTab: StatsTab?
    var ladderTab: LadderTab?
    
    var tabSizes = [NSTabViewItem : CGSize]()

    override func windowDidLoad() {
        super.windowDidLoad()
        
        update()
        
        statsTab = StatsTab()
        statsTab!.deck = self.deck
        
        ladderTab = LadderTab()
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
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(update),
                                                         name: "reload_decks",
                                                         object: nil)
 
    }
    
    func resizeWindowToFitTab(tab: NSTabViewItem) {
        //TODO: centering?
        guard let desiredTabSize = tabSizes[tab], swindow = self.window
            else { return }
        
        let currentTabSize = tab.view!.frame.size
        let windowSize = swindow.frame.size
        
        let newSize = CGSize(
            width:  windowSize.width  + desiredTabSize.width  - currentTabSize.width,
            height: windowSize.height + desiredTabSize.height - currentTabSize.height)
        
        var frame = swindow.frame
        frame.origin.y = swindow.frame.origin.y - newSize.height + windowSize.height
        frame.size = newSize
        swindow.setFrame(frame, display: true)
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
            
        } else {
            selectedDeckIcon.image = NSImage(named: "error")
            selectedDeckName.stringValue = "No deck selected."
        }
    }

    
    @IBAction func closeWindow(sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }
    
    
    @IBAction func deleteStatistics(sender: AnyObject) {
        if let deck = deck {
            let alert = NSAlert()
            alert.alertStyle = .InformationalAlertStyle
            // swiftlint:disable line_length
            alert.messageText = NSString(format: NSLocalizedString("Are you sure you want to delete the statistics for the deck %@ ?", comment: ""), deck.name!) as String
            // swiftlint:enable line_length
            alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
            alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
            alert.beginSheetModalForWindow(self.window!,
                                           completionHandler: { (returnCode) in
                                            if returnCode == NSAlertFirstButtonReturn {
                                                self.deck?.removeAllStatistics()
                                                dispatch_async(dispatch_get_main_queue()) {
                                                    self.statsTab!.statsTable.reloadData()
                                                }
                                            }
            })
        }
    }
}

extension Statistics: NSTabViewDelegate {
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        if tabView == tabs {
            guard let item = tabViewItem
                else { return }
            resizeWindowToFitTab(item)
        }
    }
}



