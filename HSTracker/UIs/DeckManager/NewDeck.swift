//
//  NewDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol NewDeckDelegate {
    //func newDeckFromFile(file:NSURL)
    //func newDeckFromUrl(url:NSURL)
    //func newDeckFromDeckBuilder(playerClass:String)
    func addNewDeck(deck: Deck)
}

class NewDeck: NSWindowController, NSComboBoxDataSource, NSComboBoxDelegate {
    
    @IBOutlet weak var hstrackerDeckBuilder: NSButton!
    @IBOutlet weak var fromAFile: NSButton!
    @IBOutlet weak var fromTheWeb: NSButton!
    @IBOutlet weak var classesCombobox: NSComboBox!
    @IBOutlet weak var urlDeck: NSTextField!
    @IBOutlet weak var chooseFile: NSButton!
    @IBOutlet weak var okButton: NSButton!
    
    var delegate: NewDeckDelegate?
    
    convenience init() {
        self.init(windowNibName: "NewDeck")
    }
    
    override init(window: NSWindow!) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func radios() -> [NSButton:NSControl] {
        return [
            hstrackerDeckBuilder: classesCombobox,
            fromAFile: chooseFile,
            fromTheWeb: urlDeck
        ]
    }
    
    @IBAction func radioChange(sender: AnyObject) {
        for (button, control) in radios() {
            if button == sender as! NSControl {
                button.state = NSOnState
                control.enabled = true
            }
            else {
                button.state = NSOffState
                control.enabled = false
            }
        }
        checkToEnableSave()
    }
    
    func setDelegate(delegate: NewDeckDelegate) {
        self.delegate = delegate
    }
    
    @IBAction func cancelClicked(sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseCancel)
    }
    
    @IBAction func okClicked(sender: AnyObject) {
        if hstrackerDeckBuilder.state == NSOnState {

        }
        else if fromTheWeb.state == NSOnState {
            // TODO add loader
            do {
                try NetImporter.netImport(urlDeck.stringValue, { (deck) -> Void in
                    if let deck = deck, let delegate = self.delegate {
                        delegate.addNewDeck(deck)
                    }
                    else {
                        // TODO show error
                    }
                    self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
                })
            } catch {
                // TODO show error
            }
        }
        else if fromAFile.state == NSOnState {

        }
        

        
        //self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }
    
    func classes() -> [String] {
        return [ "druid", "hunter", "mage", "paladin", "priest",
            "rogue", "shaman", "warlock", "warrior"].sort { NSLocalizedString($0, comment: "") <  NSLocalizedString($1, comment: "")}
    }
    
    //MARK: - NSComboBoxDataSource, NSComboBoxDelegate
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return classes().count
    }
    
    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return classes()[index]
    }
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        checkToEnableSave()
    }
    
    func checkToEnableSave() {
        var enabled:Bool?
        if hstrackerDeckBuilder.state == NSOnState {
            enabled = classesCombobox.indexOfSelectedItem != -1
        }
        else if fromTheWeb.state == NSOnState {
            enabled = !urlDeck.stringValue.isEmpty
        }
        else if fromAFile.state == NSOnState {
            enabled = false
        }
        
        if let enabled = enabled {
            okButton.enabled = enabled
        }
    }

    override func controlTextDidChange(obj: NSNotification) {
        checkToEnableSave()
    }
}